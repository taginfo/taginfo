# web/lib/sources.rb
class Source

    @@sources = Array.new

    attr_reader :id, :name, :data_until, :update_start, :update_end, :dbsize, :dbpack

    # Enumerate all available sources
    def self.each
        @@sources.each do |source|
            yield source
        end
    end

    # The number of available sources
    def self.size
        @@sources.size
    end

    # Create new source
    #  id - Symbol with id for this source
    #  name - Name of this source
    def initialize(id, name, data_until, update_start, update_end)
        @id           = id.to_sym
        @name         = name
        @data_until   = data_until
        @update_start = update_start
        @update_end   = update_end

        @dbsize = File.size("../../data/#{ dbname }").to_bytes rescue '<i>unknown</i>'
        @dbpack = File.size("../../download/#{ dbname }.bz2").to_bytes rescue '<i>unknown</i>'

        @@sources << self
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
    def img(size=16)
        %Q{<img src="#{ imgurl(size) }" alt="#{ name }" title="#{ name }" width="#{ size }" height="#{ size }"/>}
    end

    # Returns a link to this source
    def link_img
        %Q{<a href="#{ url }">#{ img }</a>}
    end

    # Returns a link to this source
    def link_name
        %Q{<a href="#{ url }">#{ name }</a>}
    end

    def dbname
        "taginfo-#{ @id }.db"
    end

    def link_download
        %Q{<a href="/download/#{ dbname }.bz2">#{ dbname }.bz2</a>}
    end

end
