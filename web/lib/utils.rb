# web/lib/utils.rb

# patches convenience methods into base classes

class Fixnum

    # convert to string with this space as thousand separator
    def to_s_with_ts
        self.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1&thinsp;")
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
    "http://www.informationfreeway.org/api/0.6/#{ element }[#{ Rack::Utils::escape(predicate) }]"
end

def xapi_link(element, key, value=nil)
    '<span class="button">' + external_link('XAPI', xapi_url(element, key, value)) + '</span>'
end

def josm_link(element, key, value=nil)
    '<span class="button">' + external_link('JOSM', 'http://localhost:8111/import?url=' + xapi_url(element, key, value)) + '</span>'
end

def external_link(title, link)
    %Q{<img src="/img/link-extern.gif" alt="" width="14" height="10"/><a class="extlink" href="#{link}">#{title}</a>}
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

def link_to_key(key)
    k = escape(key)
    title = escape_html(key)

    if key.match(/[=\/]/)
        return '<a class="taglink" href="/keys/?key=' + k + '" title="' + title + '">' + pp_key(key) + '</a>'
    else
        return '<a class="taglink" href="/keys/'      + k + '" title="' + title + '">' + pp_key(key) + '</a>'
    end
end

def link_to_value(key, value)
    k = escape(key)
    v = escape(value)
    title = escape_html(key) + '=' + escape_html(value)

    if key.match(/[=\/]/) || value.match(/[=\/]/)
        return '<a class="taglink" href="/tags/?key=' + k + '&value=' + v + '" title="' + title + '">' + pp_value(value) + '</a>'
    else
        return '<a class="taglink" href="/tags/' + k + '=' + v + '" title="' + title + '">' + pp_value(value) + '</a>'
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

