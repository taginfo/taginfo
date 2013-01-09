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
    x = tag['scale1'].to_f / 20 + tag['pos'] / 4
    (x * 40 + 12).to_i
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

    pp_chars = '!"#$%&()*+,/;<=>?@[\\]^`{|}~' + "'";

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

# Used in wiki api calls
def get_wiki_result(res)
    return res.map{ |row| {
            :lang             => h(row['lang']),
            :language         => h(::Language[row['lang']].native_name),
            :language_en      => h(::Language[row['lang']].english_name),
            :title            => h(row['title']),
            :description      => h(row['description']),
            :image            => {
                :title            => h(row['image']),
                :width            => row['width'].to_i,
                :height           => row['height'].to_i,
                :mime             => h(row['mime']),
                :image_url        => h(row['image_url']),
                :thumb_url_prefix => h(row['thumb_url_prefix']),
                :thumb_url_suffix => h(row['thumb_url_suffix'])
            },
            :on_node          => row['on_node'].to_i     == 1,
            :on_way           => row['on_way'].to_i      == 1,
            :on_area          => row['on_area'].to_i     == 1,
            :on_relation      => row['on_relation'].to_i == 1,
            :tags_implies     => row['tags_implies'    ].split(','),
            :tags_combination => row['tags_combination'].split(','),
            :tags_linked      => row['tags_linked'     ].split(',')
        }
    }.to_json
end

# Used in josm api calls
def get_josm_style_rules_result(total, res)
    return {
        :page  => @ap.page,
        :rp    => @ap.results_per_page,
        :total => total,
        :data  => res.map{ |row| {
            :key        => row['k'],
            :value      => row['v'],
            :value_bool => row['b'],
            :rule       => h(row['rule']),
            :area_color => row['area_color'] ? h(row['area_color'].sub(/^.*#/, '#')) : '',
            :line_color => row['line_color'] ? h(row['line_color'].sub(/^.*#/, '#')) : '',
            :line_width => row['line_width'] ? row['line_width'].to_i : 0,
            :icon       => row['icon_source'] && row['icon_source'] != 'misc/deprecated.png' && row['icon_source'] != 'misc/no_icon.png' ? h(row['icon_source']) : ''
        } }
    }.to_json
end

def paging_results(array)
    return [
        [ :total, :INT, 'Total number of results.' ],
        [ :page,  :INT, 'Result page number (first has page number 1).' ],
        [ :rp,    :INT, 'Results per page.' ],
        [ :data,  :ARRAY_OF_HASHES, 'Array with results.', array ]
    ];
end

def no_paging_results(array)
    return [
        [ :total, :INT, 'Total number of results.' ],
        [ :data,  :ARRAY_OF_HASHES, 'Array with results.', array ]
    ];
end

