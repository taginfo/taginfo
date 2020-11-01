# web/lib/sources.rb
class Source

    @@sources = Hash.new

    attr_reader :id, :name, :data_until, :update_start, :update_end, :visible, :dbsize, :dbpack

    # Enumerate all available sources
    def self.each
        @@sources.values.each do |source|
            yield source
        end
    end

    # The number of available sources
    def self.size
        @@sources.size
    end

    def self.visible
        @@sources.values.select{ |source| source.visible }
    end

    def self.get(id)
        @@sources[id]
    end

    # Create new source
    #  id - Symbol with id for this source
    #  name - Name of this source
    def initialize(id, name, data_until, update_start, update_end, visible)
        @id           = id.to_sym
        @name         = name
        @data_until   = data_until
        @update_start = update_start
        @update_end   = update_end
        @visible      = visible

        data_dir = TaginfoConfig.get('paths.data_dir', '../../data')
        download_dir = TaginfoConfig.get('paths.download_dir', '../../download')
        @dbsize = File.size("#{ data_dir }/#{ dbname }").to_bytes rescue 0
        @dbpack = File.size("#{ download_dir }/#{ dbname }.bz2").to_bytes rescue 0

        @@sources[@id] = self
    end

    # The URL where this source is described
    def url
        "/sources/#{ @id }"
    end

    # The img URL of this source
    def imgurl(size=16)
        "/img/sources/#{ @id }.#{ size }.png"
    end

    # Returns img tag for this source
    def img(size=16, title_prefix='')
        %Q{<img src="#{ imgurl(size) }" alt="#{ name }" title="#{title_prefix} #{ name }" tipsy="w" width="#{ size }" height="#{ size }"/>}
    end

    def dbname
        "taginfo-#{ @id }.db"
    end

    def link_download
        %Q{<a rel="nofollow" href="/download/#{ dbname }.bz2">#{ dbname }.bz2</a>}
    end

end
