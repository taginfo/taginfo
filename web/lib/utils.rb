# web/lib/utils.rb

# patches convenience methods into base classes

class Fixnum

    # convert to string with this space as thousand separator
    def to_s_with_ts
        self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1&thinsp;")
    end

end

class String

    def titlecase
        self[0,1].upcase + self[1,self.size].downcase
    end

end

class Numeric

    def to_bytes
        if self >= 1024*1024
            unit = 'MB'
            value = self / (1024*1024)
        elsif self >= 1024
            unit = 'kB'
            value = self / 1024
        else
            unit = 'B'
        end
        value.to_i.to_s + '&thinsp;' + unit
    end

end

class Float
    def round_to(n=0)
        (self * (10.0 ** n)).round * (10.0 ** (-n))
    end
end

def title
    @title = [] if @title.nil?
    @title = [@title] unless @title.is_a?(Array)
    @title << TaginfoConfig.get('instance.name', 'OpenStreetMap Taginfo')
    @title.join(' | ')
end

def section(id)
    @section = id.to_s
    @section_title = (@section =~ /^(keys|tags)$/) ? t.osm[@section] : t.taginfo[@section]
end

# Escape tag key or value for XAPI according to
# http://wiki.openstreetmap.org/wiki/XAPI#Escaping
def xapi_escape(text)
    text.gsub(/([|\[\]*\/=()\\])/, '\\\\\1')
end

def xapi_url(element, key, value=nil)
    predicate = xapi_escape(key) + '='
    if value.nil?
        predicate += '*'
    else
        predicate += xapi_escape(value)
    end
    TaginfoConfig.get('xapi.url_prefix', 'http://www.informationfreeway.org/api/0.6/') + "#{ element }[#{ Rack::Utils::escape(predicate) }]"
end

def xapi_link(element, key, value=nil)
    '<span class="button">' + external_link('xapi_button', 'XAPI', xapi_url(element, key, value), true) + '</span>'
end

def josm_link(element, key, value=nil)
    '<span class="button">' + external_link('josm_button', 'JOSM', 'http://localhost:8111/import?url=' + Rack::Utils::escape(xapi_url(element, key, value)), true) + '</span>'
end

def external_link(id, title, link, new_window=false)
    target = new_window ? 'target="_blank" ' : ''
    %Q{<a id="#{id}" #{target}rel="nofollow" class="extlink" href="#{link}">#{title}</a>}
end

def tagcloud_size(tag)
    x = tag['scale1'].to_f / 17 / 2 + tag['pos'] / 2
    (x * 32 + 10).to_i
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
    return @db.stats(key)
end

# see also web/public/js/taginfo.js
def pp_key(key)
    if key == ''
        return '<span class="badchar empty">empty string</span>'
    end

    pp_chars = '!"#$%&()*+,-/;<=>?@[\\]^`{|}~' + "'";

    result = ''
    key.each_char do |c|
        if (!pp_chars.index(c).nil?)
            result += '<span class="badchar">' + c + '</span>'
        elsif (c == ' ')
            result += '<span class="badchar">&#x2423;</span>'
        elsif (c.match(/\s/))
            result += '<span class="whitespace">&nbsp;</span>'
        else
            result += c;
        end
    end

    return result;
end

# see also web/public/js/taginfo.js
def pp_value(value)
    if value == ''
        return '<span class="badchar empty">empty string</span>'
    end
    return escape_html(value).gsub(/ /, '&#x2423;').gsub(/\s/, '<span class="whitespace">&nbsp;</span>')
end

def link_to_key(key, tab='')
    k = escape(key)

    if key.match(/[=\/]/)
        return '<a href="/keys/?key=' + k + tab + '">' + pp_key(key) + '</a>'
    else
        return '<a href="/keys/'      + k + tab + '">' + pp_key(key) + '</a>'
    end
end

def link_to_value(key, value)
    k = escape(key)
    v = escape(value)

    if key.match(/[=\/]/) || value.match(/[=\/]/)
        return '<a href="/tags/?key=' + k + '&value=' + v + '">' + pp_value(value) + '</a>'
    else
        return '<a href="/tags/' + k + '=' + v + '">' + pp_value(value) + '</a>'
    end
end

def link_to_tag(key, value)
    return link_to_key(key) + '=' + link_to_value(key, value)
end

# Like the 'get' method but will add a redirect for the same path with trailing / added
def get!(path, &block)
    get path, &block
    get path + '/' do
        redirect path
    end
end

# Like the 'get' method but specific for API calls, includes documentation for API calls
def api(version, path, doc=nil, &block)
    API.new(version, path, doc) unless doc.nil?
    get("/api/#{version}/#{path}", &block)
end

