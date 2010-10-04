# utils.rb

class Language

    @@languages = {}

    attr_reader :code, :english_name, :native_name

    def initialize(options)
        @code         = options['code']
        @english_name = options['english_name']
        @native_name  = options['native_name']
        @@languages[@code] = self
    end

    def self.[](code)
        @@languages[code] || self.new('code' => code, 'english_name' => '(unknown)', 'native_name' => '(unknown)')
    end

    def self.each
        @@languages.keys.sort.each do |lang|
            yield @@languages[lang]
        end
    end

end

# patches convenience methods into base classes

class Fixnum

    # convert to string with this space as thousand separator
    def to_s_with_ts
        self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1&thinsp;")
    end

end

def breadcrumbs
    return @breadcrumbs.map{ |name, link|
        if link
            "<a href='#{link}'>#{name}</a>"
        else
            name
        end    
    }.join(' &raquo; ')
end

def title
    @title = [] if @title.nil?
    @title = [@title] unless @title.is_a?(Array)
    @title << 'OpenStreetMap Taginfo'
    @title.join(' | ')
end

def xapi_url(element, predicate)
    "http://www.informationfreeway.org/api/0.6/#{ element }[#{ Rack::Utils::escape(predicate) }]"
end

def xapi_link(element, predicate)
    "<a id='xapi' href='#{ xapi_url(element, predicate) }'>XAPI</a>"
end

def josm_link(element, predicate)
    "<a id='josm' href='http://localhost:8111/import?url=#{ xapi_url(element, predicate) }'>JOSM</a>"
end

def tagcloud_size(tag)
    #(Math.log(0.000001 + tag['scale'].to_f * Math::E) * 36 + 12).to_i
    x = tag['scale1'].to_f / 17 / 2 + tag['pos'] / 2
    (x * 24 + 12).to_i
end

def tagcloud_color(tag)
    c = 0xa0;
    if tag['in_wiki'] == '1'
        c -= 0x40;
    end
    if tag['in_josm'] == '1'
        c -= 0x60;
    end
    sprintf('#%02x%02x%02x', c, c, c)
    c = '#000000';
end

def get_filter
    f = params[:filter].to_s == '' ? 'all' : params[:filter]
    if f !~ /^(all|nodes|ways|relations)$/
        raise ArgumentError, "unknown filter"
    end
    f
end

def get_total(type)
    key = {
        'all'       => 'objects',
        'nodes'     => 'nodes_with_tags',
        'ways'      => 'ways',
        'relations' => 'relations' }[type]
    return @stats[key]
end

def pp_key(key)
    if key == ''
        return '<b><i>empty string<i></b>'
    end
    return key.gsub(/([&<>#;\/]+)/, '<b>\1</b>').gsub(/ /, '<b>&#x2423;</b>').gsub(/\s+/, '<b>?</b>').gsub(/([-!"\$%'()*+,.=@\[\\\]^`{|}~]+)/, '<b>\1</b>')
end

def pp_value(value)
    if value == ''
        return '<b><i>empty string<i></b>'
    end
    return escape_html(value).gsub(/ /, '&#x2423;').gsub(/\s/, '<b>?</b>')
end

