# web/lib/utils.rb

require 'time'

# ------------------------------------------------------------------------------
# patch some convenience methods into base classes

# Monkey patching Integer class
class Integer

    # convert to string with thin space as thousand separator
    def to_s_with_ts
        to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1&#x202f;")
    end

end

# Monkey patching String class
class String

    def titlecase
        self[0, 1].upcase + self[1, size].downcase
    end

end

# Monkey patching Numeric class
class Numeric

    def to_bytes
        if self >= 1024 * 1024
            unit = 'MB'
            value = self / (1024 * 1024)
        elsif self >= 1024
            unit = 'kB'
            value = self / 1024
        else
            unit = 'B'
        end
        value.to_i.to_s + '&thinsp;' + unit
    end

end

# ------------------------------------------------------------------------------

def title
    @title = [] if @title.nil?
    @title = [@title] unless @title.is_a?(Array)
    @title << @taginfo_config.get('instance.name', 'OpenStreetMap Taginfo')
    @title.join(' | ')
end

def section(id)
    @section = id.to_s
    @section_title = @section =~ /^(keys|tags)$/ ? t.osm[@section] : t.taginfo[@section]
end

def in_section(id)
    @section == id ? 'class="selected" ' : ''
end

def under_section
    @section && request.path != '/' + @section
end

def json_opts(format)
    return {} if format != 'json_pretty'

    { :indent => '  ', :space => ' ', :object_nl => "\n" }
end

# ------------------------------------------------------------------------------

# Escape tag key or value for XAPI according to
# http://wiki.openstreetmap.org/wiki/XAPI#Escaping
def xapi_escape(text)
    text.gsub(/([|\[\]*\/=()\\])/, '\\\\\1')
end

def xapi_url(element, key, value = nil)
    predicate = xapi_escape(key) + '='
    predicate += value.nil? ? '*' : xapi_escape(value)
    @taginfo_config.get('xapi.url_prefix', 'http://www.informationfreeway.org/api/0.6/') + "#{ element }[#{ Rack::Utils.escape(predicate) }]"
end

def xapi_link(element, key, value = nil)
    external_link('xapi_button', 'XAPI', xapi_url(element, key, value), true)
end

def josm_link(element, key, value = nil)
    external_link('josm_button', 'JOSM', 'http://127.0.0.1:8111/import?url=' + Rack::Utils.escape(xapi_url(element, key, value)), true)
end

def quote_double(text)
    text.gsub(/["\\]/, "\\\\\\0")
end

def turbo_link(count, filter, key, value = nil)
    if count <= @taginfo_config.get('turbo.max_auto', 100)
        key = quote_double(key)
        value = if value.nil?
                    '*'
                else
                    '"' + quote_double(value) + '"'
                end
        if filter != 'all'
            filter_condition = ' and type:' + filter.chop
        end
        url = @taginfo_config.get('turbo.url_prefix', 'https://overpass-turbo.eu/?') + 'w=' + Rack::Utils.escape('"' + key + '"=' + value + filter_condition.to_s + ' ' + @taginfo_config.get('turbo.wizard_area', 'global')) + '&R'
    else
        template = 'key'
        parameters = { :key => key }

        unless value.nil?
            parameters[:value] = value
            template += '-value'
        end

        if filter != 'all'
            template += '-type'
            parameters[:type] = filter.chop
        end
        parameters[:template] = template

        url = @taginfo_config.get('turbo.url_prefix', 'https://overpass-turbo.eu/?') + Rack::Utils.build_query(parameters)
    end

    external_link('turbo_button', 'Overpass turbo', url, true)
end

def level0_url(filter, key, value)
    query = '["' + quote_double(key)
    unless value.nil?
        query += '"="' + quote_double(value)
    end
    query += '"];'

    if filter == 'nodes'
        query = 'node' + query
    elsif filter == 'ways'
        query = '(way' + query + '>;);'
    elsif filter == 'relations'
        query = 'rel' + query
    else
        query = '(node' + query + 'way' + query + '>;rel' + query + ');'
    end

    overpass_url = @taginfo_config.get('level0.overpass_url_prefix') + Rack::Utils.build_query({ :data => '[out:xml];' + query + 'out meta;' })

    @taginfo_config.get('level0.level0_url_prefix') + Rack::Utils.build_query({ :url => overpass_url })
end

def level0_link(filter, key, value = nil)
    external_link('level0_button', 'Level0 Editor', level0_url(filter, key, value), true)
end

def external_link(id, title, link, new_window = false)
    target = new_window ? 'target="_blank" ' : ''
    %(<a id="#{id}" #{target}rel="nofollow" class="extlink" href="#{link}">#{title}</a>)
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
    return 'all' if f !~ /^(all|nodes|ways|relations)$/

    f
end

def get_total(type)
    key = {
        'all'       => 'objects',
        'nodes'     => 'nodes_with_tags',
        'ways'      => 'ways',
        'relations' => 'relations' }[type]

    @db.stats(key)
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
def api(version, path, doc = nil, &block)
    API.new(version, path, doc) unless doc.nil?
    get("/api/#{version}/#{path}", &block)
end

# ------------------------------------------------------------------------------

# Get the printing direction of a language.
def direction_from_lang_code(language_code)
    r = R18n.locale(language_code)
    if r.supported?
        return r.ltr? ? 'ltr' : 'rtl'
    end

    'auto'
end

# ------------------------------------------------------------------------------

# Get description for key/tag/relation from wiki page
# Get it in given language or fall back to English if it isn't available
def get_description(table, attr, param, value)
    [r18n.locale.code, 'en'].each do |lang|
        select = @db.select("SELECT description FROM #{table}")
                    .condition("lang=? AND #{attr}=?", lang, param)

        if attr == 'key'
            if value.nil?
                select = select.condition('value IS NULL')
            else
                select = select.condition('value=?', value)
            end
        end

        desc = select.get_first_value
        return [desc, lang, direction_from_lang_code(lang)] if desc
    end

    ['', '', 'auto']
end

def get_key_description(key)
    get_description('wiki.wikipages', 'key', key, nil)
end

def get_tag_description(key, value)
    get_description('wiki.wikipages', 'key', key, value)
end

def get_relation_description(rtype)
    get_description('wiki.relation_pages', 'rtype', rtype, nil)
end

def wrap_description(translation, description)
    if description[0] != ''
        return "<span lang='#{description[1]}' dir='#{description[2] ? 'ltr' : 'rtl'}' title='#{ h(translation.description_from_wiki) }' data-tooltip-position='#{r18n.locale.ltr? ? 'OnRight' : 'OnLeft'}'>#{ h(description[0]) }</span>"
    end

    "<span class='empty'>#{ h(translation.no_description_in_wiki) }</span>"
end

# ------------------------------------------------------------------------------

# Used in wiki api calls
def get_wiki_result(res)
    generate_json_result(res.size, res.map do |row|
        {
            :lang             => row['lang'],
            :dir              => direction_from_lang_code(row['lang']),
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
            :tags_implies     => row['tags_implies'].split(','),
            :tags_combination => row['tags_combination'].split(','),
            :tags_linked      => row['tags_linked'].split(','),
            :status           => row['approval_status']
        }
        end
    )
end

def paging_results(array)
    [
        [ :total,      :INT, 'Total number of results.' ],
        [ :page,       :INT, 'Result page number (first has page number 1).' ],
        [ :rp,         :INT, 'Results per page.' ],
        [ :url,        :STRING, 'URL of the request.' ],
        [ :data_until, :STRING, 'All changes in the source until this date are reflected in this taginfo result.' ],
        [ :data,       :ARRAY_OF_HASHES, 'Array with results.', array ]
    ]
end

def no_paging_results(array)
    [
        [ :total,      :INT, 'Total number of results.' ],
        [ :url,        :STRING, 'URL of the request.' ],
        [ :data_until, :STRING, 'All changes in the source until this date are reflected in this taginfo result.' ],
        [ :data,       :ARRAY_OF_HASHES, 'Array with results.', array ]
    ]
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

    nil
end

def unpack_chronology(raw_data)
    data = []

    if raw_data
        flat_data = raw_data.unpack('l*')

        until flat_data.empty?
            day = flat_data.shift(4)
            data << {
                :date      => Time.at(day[0] * (60 * 60 * 24)).to_date.to_s,
                :nodes     => day[1],
                :ways      => day[2],
                :relations => day[3]
            }
        end
    end

    data
end

def build_link(link)
    if (@taginfo_config.id != '')
        '/' + @taginfo_config.id + link
    else
        link
    end
end

def data_as_script(data)
    data.to_json.gsub('<', '\u003C')
end

