# web/lib/sql.rb
#
# SQL database wrapper with convenience methods for query building.
module SQL

    # Wrapper for a database connection.
    class Database

        def initialize(taginfo_config)
            @dir = taginfo_config.get('paths.data_dir')
            filename = @dir + '/taginfo-master.db'
            @db = SQLite3::Database.new(filename, { :readonly => true })
            @db.results_as_hash = true

            pcre_extension = taginfo_config.get('paths.sqlite3_pcre_extension')
            if pcre_extension
                @db.load_extension(pcre_extension)
            end
            @db.execute('PRAGMA journal_mode = OFF')
            @db.execute('SELECT * FROM languages') do |row|
                Language.new(row)
            end
            @min_duration = taginfo_config.get('logging.min_duration', 0)
            @sources = Sources.new(taginfo_config)
            select('SELECT * FROM sources ORDER BY no').execute().each do |source|
                @sources.add(source['id'], source['name'], source['data_until'], source['update_start'], source['update_end'], source['visible'].to_i == 1)
            end
        end

        def sources
            @sources
        end

        def data_until_raw
            defined?(@data_until_raw) || @data_until_raw = select("SELECT min(data_until) FROM sources WHERE id='db'").get_first_value()
            @data_until_raw
        end

        def data_until
            data_until_raw.sub(/:..$/, '')
        end

        def data_until_m
            data_until_raw.sub(' ', 'T') + 'Z'
        end

        def attach_source(filename, name)
            @db.execute('ATTACH DATABASE ? AS ?', "#{ @dir }/#{ filename }", name)
            @db.execute("PRAGMA #{ name }.journal_mode = OFF")
        end

        def attach_sources
            @sources.each do |source|
                attach_source(source.dbname, source.id.to_s)
            end
            attach_source('taginfo-history.db', 'history')
            self
        end

        def close
            @db.close
            @db = nil
        end

        def wrap_query(query, *params)
            t1 = Time.now
            out = yield
            duration = Time.now - t1

            if duration > @min_duration
                if params.size > 0
                    p = ' params=[' + params.map{ |param| "'#{param}'" }.join(', ') + ']'
                else
                    p = ''
                end
                ($queries_log||$stderr).puts %Q{SQL duration=#{ duration.round(2) } query="#{ query };"} + p
            end

            out
        end

        def execute(*args, &block)
            wrap_query(*args) do
                @db.execute(*args, &block)
            end
        end

        def get_first_row(*args)
            wrap_query(*args) do
                @db.get_first_row(*args)
            end
        end

        def get_first_value(*args)
            wrap_query(*args) do
                @db.get_first_value(*args)
            end
        end

        def select(query, *params)
            Select.new(self, query, *params)
        end

        # Build query of the form
        #   SELECT count(*) FROM table;
        def count(table)
            Select.new(self, 'SELECT count(*) FROM ' + table)
        end

        def stats(key)
            get_first_value('SELECT value FROM master_stats WHERE key=?', key).to_i
        end

        def quote(data)
            SQLite3::Database.quote(data)
        end

        def quote_and_join_array(data)
            data.map{ |v| "'" + SQLite3::Database.quote(v) + "'" }.join(',')
        end

    end

    # Representation of a SELECT query.
    class Select

        def initialize(db, query, *params)
            @db = db

            @query      = [query]
            @conditions = []

            @params = params
        end

        def condition(expression, *params)
            @conditions << expression
            @params.push(*params)
            self
        end

        def is_null(attribute)
            condition("#{attribute} IS NULL")
            self
        end

        def condition_if(expression, *param)
            unless param.first.to_s.match(/^%?%?$/)
                condition(expression, *param)
            end
            self
        end

        def condition_if_true(expression, value)
            if value
                condition(expression)
            end
            self
        end

        def conditions(conds)
            conds.each do |cond|
                condition(cond)
            end
            self
        end

        def order_by(values, direction, &block)
            if values.is_a?(Array)
                values = values.compact
            else
                values = [values]
            end

            o = Order.new(values, &block)

            if direction != 'ASC' && direction != 'DESC'
                raise ArgumentError, 'direction must be ASC or DESC'
            end

            values.each do |value|
                value = o.default if value.nil?
                unless o._allowed(value)
                    raise ArgumentError, 'order by this attribute not allowed'
                end
            end

            unless values.empty?
                @order_by = "ORDER BY " + values.map{ |value|
                    value = o.default if value.nil?
                    o[value.to_s].map{ |oel| oel.to_s(direction) }.join(',')
                }.join(',')
            end

            self
        end

        def group_by(value)
            @group_by = "GROUP BY #{value}"
            self
        end

        def paging(ap)
            if ap.do_paging?
                limit(ap.results_per_page, ap.first_result)
            end
            self
        end

        def limit(limit, offset=0)
            @limit = "LIMIT #{limit} OFFSET #{offset}"
            self
        end

        def build_query
            unless @conditions.empty?
                @query << 'WHERE'
                @query << @conditions.map{ |c| "(#{c})" }.join(' AND ')
            end
            @query << @group_by
            @query << @order_by
            @query << @limit
            @query.compact.join(' ')
        end

        def execute(&block)
            q = build_query()
            @db.execute(q, *@params, &block)
        end

        def get_first_row
            q = build_query()
            @db.get_first_row(q, *@params)
        end

        def get_first_value
            q = build_query()
            @db.get_first_value(q, *@params)
        end

        def get_first_i
            get_first_value().to_i
        end

        def get_columns(*columns)
            q = build_query()
            row = @db.get_first_row(q, *@params)
            return [nil] * columns.size if row.nil?;
            columns.map{ |column| row[column.to_s].to_i }
        end

    end

    class OrderElement

        @@DIRECTION = { 'ASC' => 'DESC', 'DESC' => 'ASC' }

        def initialize(column, reverse)
            @column  = column
            @reverse = reverse
        end

        def to_s(direction)
            dir = @reverse ? @@DIRECTION[direction.upcase] : direction.upcase
            "#{@column} #{dir}"
        end

    end

    class Order

        attr_reader :default

        def initialize(values, &block)
            @allowed = Hash.new
            if block_given?
                yield self
            else
                values.each do |value|
                    _add(value.to_s)
                end
            end
        end

        def _allowed(field)
            @allowed.has_key?(field.to_s)
        end

        def [](field)
            @allowed[field]
        end

        def _add(field, attribute=nil)
            field = field.to_s
            @default = field unless defined? @default
            if field =~ /^(.*)!$/
                field = $1
                reverse = true
            else
                reverse = false
            end
            attribute = field if attribute.nil?

            @allowed[field] ||= Array.new
            @allowed[field] << OrderElement.new(attribute.to_s, reverse)
        end

        def method_missing(field, attribute=nil)
            _add(field, attribute)
        end

    end

end
