# web/lib/utils.rb

# ------------------------------------------------------------------------------
# patch some convenience methods into base classes

class Fixnum

    # convert to string with thin space as thousand separator
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

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------

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

def quote_double(text)
    text.gsub(/["\\]/, "\\\\\\0")
end

def turbo_link(count, filter, key, value=nil)
    if count <= TaginfoConfig.get('turbo.max_auto', 100)
        key = quote_double(key)
        if value.nil?
            value = '*'
        else
            value = '"' + quote_double(value) + '"'
        end
        if filter != 'all'
            filter_condition = ' and type:' + filter.chop
        end
        url = TaginfoConfig.get('turbo.wizard_url_prefix', 'http://overpass-turbo.eu/master?') + 'w=' + Rack::Utils::escape('"' + key + '"=' + value + filter_condition.to_s + ' ' + TaginfoConfig.get('turbo.wizard_area', 'global')) + '&R'
    else
        template = 'key';
        parameters = { :key => key }

        unless value.nil?
            parameters[:value] = value;
            template += '-value'
        end

        if filter != 'all'
            template += '-type'
            parameters[:type] = filter.chop
        end
        parameters[:template] = template

        url = TaginfoConfig.get('turbo.url_prefix', 'http://overpass-turbo.eu/?') + Rack::Utils::build_query(parameters)
    end
    return '<span class="button">' + external_link('turbo_button', '<img src="/img/turbo.png"/> overpass turbo', url, true) + '</span>'
end

def level0_link()
    return '<span class="button">' + external_link('level0_button', 'Level0 Editor', '#', true) + '</span>'
end

def external_link(id, title, link, new_window=false)
    target = new_window ? 'target="_blank" ' : ''
    %Q{<a id="#{id}" #{target}rel="nofollow" class="extlink" href="#{link}">#{title}</a>}
end

def wiki_link(title)
    prefix = '//wiki.openstreetmap.org/wiki/'
    external_link('wikilink_' + title.gsub(%r{[^A-Za-z0-9]}, '_'), title, prefix + title)
end

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------

# Escape % and _ special characters with @.
# The @ was chosen because it is not a special character in SQL, in Regexes,
# and isn't seen often in OSM tags. You must use "ESCAPE '@'" clause with LIKE!
def like_escape(param)
    param.to_s.gsub(/[_%@]/, '@\0')
end

def like_prefix(param)
    like_escape(param) + '%'
end

def like_contains(param)
    '%' + like_escape(param) + '%'
end

# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------

# Used in wiki api calls
def get_wiki_result(res)
    return res.map{ |row| {
            :lang             => row['lang'],
            :language         => ::Language[row['lang']].native_name,
            :language_en      => ::Language[row['lang']].english_name,
            :title            => row['title'],
            :description      => row['description'] || '',
            :image            => {
                :title            => row['image'],
                :width            => row['width'].to_i,
                :height           => row['height'].to_i,
                :mime             => row['mime'],
                :image_url        => row['image_url'],
                :thumb_url_prefix => row['thumb_url_prefix'],
                :thumb_url_suffix => row['thumb_url_suffix']
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
        :url   => request.url,
        :data  => res.map{ |row| {
            :key        => row['k'],
            :value      => row['v'],
            :value_bool => row['b'],
            :rule       => row['rule'],
            :area_color => row['area_color'] ? row['area_color'].sub(/^.*#/, '#') : '',
            :line_color => row['line_color'] ? row['line_color'].sub(/^.*#/, '#') : '',
            :line_width => row['line_width'] ? row['line_width'].to_i : 0,
            :icon       => row['icon_source'] && row['icon_source'] != 'misc/deprecated.png' && row['icon_source'] != 'misc/no_icon.png' ? row['icon_source'] : ''
        } }
    }.to_json
end

def paging_results(array)
    return [
        [ :total, :INT, 'Total number of results.' ],
        [ :page,  :INT, 'Result page number (first has page number 1).' ],
        [ :rp,    :INT, 'Results per page.' ],
        [ :url,   :STRING, 'URL of the request.' ],
        [ :data,  :ARRAY_OF_HASHES, 'Array with results.', array ]
    ];
end

def no_paging_results(array)
    return [
        [ :total, :INT, 'Total number of results.' ],
        [ :url,   :STRING, 'URL of the request.' ],
        [ :data,  :ARRAY_OF_HASHES, 'Array with results.', array ]
    ];
end

MAX_IMAGE_WIDTH = 300

def build_image_url(row)
    w = row['width'].to_i
    h = row['height'].to_i
    if w <= MAX_IMAGE_WIDTH
        return row['image_url']
    end
    if w > 0 && h > 0
        return "#{row['thumb_url_prefix']}#{ h <= w ? MAX_IMAGE_WIDTH : (MAX_IMAGE_WIDTH * w / h).to_i }#{ row['thumb_url_suffix'] }"
    end
    return nil
end

