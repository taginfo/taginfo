# web/lib/sql.rb
#
# SQL database wrapper with convenience methods for query building.
module SQL

    # Wrapper for a database connection.
    class Database

        def initialize(dir)
            filename = dir + '/taginfo-master.db'
            @db = SQLite3::Database.new(filename)
            @db.results_as_hash = true

            [:db, :wiki, :josm, :potlatch, :merkaartor, :search].each do |dbname|
                @db.execute("ATTACH DATABASE '#{dir}/taginfo-#{dbname}.db' AS #{dbname}")
            end

            @db.execute('SELECT * FROM languages') do |row|
                Language.new(row)
            end
        end

        def close
            @db.close
            @db = nil
        end

        def execute(*args, &block)
            @db.execute(*args, &block)
        end

        def get_first_row(*args)
            @db.get_first_row(*args)
        end

        def get_first_value(*args)
            @db.get_first_value(*args)
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

        def condition_if(expression, *param)
            if param.first.to_s != ''
                condition(expression, *param)
            end
            self
        end

        def conditions(cond)
            cond.each do |cond|
                condition(cond)
            end
            self
        end

        def order_by(values, direction='ASC', &block)
            if values.is_a?(Array)
                values = values.compact
            else
                values = [values]
            end

            o = Order.new(values, &block)

            if direction.nil?
                direction = 'ASC'
            else
                direction = direction.to_s
                if direction !~ /^(asc|desc)$/i
                    raise ArgumentError, 'direction must be ASC or DESC'
                end
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
                    o[value.to_s].map{ |oel| oel.to_s(direction.upcase) }.join(',')
                }.join(',')
            end

            self
        end

        def group_by(value)
            @group_by = "GROUP BY #{value}"
            self
        end

        def paging(results_per_page, page)
            unless results_per_page.nil? || page.nil?
                if results_per_page !~ /^[0-9]{1,3}$/
                    raise ArgumentError, 'results per page must be integer between 0 and 999'
                end
                if page !~ /^[0-9]{1,4}$/
                    raise ArgumentError, 'page must be integer between 0 and 9999'
                end
                limit(results_per_page.to_i, results_per_page.to_i * (page.to_i - 1))
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
            puts "Query: #{q}; (with params: #{@params.join(', ')})"
            @db.execute(q, *@params, &block)
        end

        def get_first_value
            q = build_query()
            puts "Query: #{q}; (with params: #{@params.join(', ')})"
            @db.get_first_value(q, *@params)
        end

        def get_columns(*columns)
            q = build_query()
            puts "Query: #{q}; (with params: #{@params.join(', ')})"
            row = @db.get_first_row(q, *@params)
            return [nil] * columns.size if row.nil?;
            columns.map{ |column| row[column.to_s] }
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
