# web/lib/sources.rb
class Sources

    def initialize(taginfo_config, db)
        data_dir = taginfo_config.get('paths.data_dir', '../../data')
        download_dir = taginfo_config.get('paths.download_dir', '../../download')

        @sources = {}
        db.select('SELECT * FROM sources ORDER BY no').execute.each do |source|
            @sources[source['id'].to_sym] = Source.new(data_dir, download_dir, source['id'], source['name'], source['data_until'], source['update_start'], source['update_end'], source['visible'].to_i == 1)
        end
        @sources.each_value do |source|
            db.attach_source(source.dbname, source.id.to_s)
        end
        db.attach_source('taginfo-history.db', 'history')
    end

    # Enumerate all available sources
    def each(&block)
        @sources.each_value(&block)
    end

    # The number of available sources
    def size
        @sources.size
    end

    def visible
        @sources.values.select(&:visible)
    end

    def get(id)
        @sources[id]
    end

end

class Source

    attr_reader :id, :name, :data_until, :update_start, :update_end, :visible, :dbsize, :dbpack

    # Create new source
    #  id - Symbol with id for this source
    #  name - Name of this source
    def initialize(data_dir, download_dir, id, name, data_until, update_start, update_end, visible)
        @id           = id.to_sym
        @name         = name
        @data_until   = data_until
        @update_start = update_start
        @update_end   = update_end
        @visible      = visible

        @dbsize = File.size("#{ data_dir }/#{ dbname }").to_bytes rescue 0
        @dbpack = File.size("#{ download_dir }/#{ dbname }.bz2").to_bytes rescue 0
    end

    def dbname
        "taginfo-#{ @id }.db"
    end

    def link_download
        %(<a rel="nofollow" href="/download/#{ dbname }.bz2">#{ dbname }.bz2</a>)
    end

end
