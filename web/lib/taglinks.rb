class TagLink

    attr_reader :title, :url

    def initialize(title, url)
        @title = title
        @url = url
    end

    def html
        external_link('', @title, @url, true)
    end

end

class TagMatch

    attr_reader :regex

    def initialize(regex, func)
        @regex = regex
        @func = func
    end

    def match(value)
        value =~ @regex
    end

    def call(value)
        @func.call(value)
    end

    def links(value)
        if match(value)
            return call(value).map(&:html)
        end

        []
    end

end

def tag_match(regex, func)
    TagMatch.new(regex, func)
end

# https://wikistats.wmcloud.org/wikimedias_csv.php
# grep ,wikipedia, wikimedias.csv | cut -d, -f2 | sort
TAGLINKS = {
    'addr:country': tag_match(%r{^[A-Z][A-Z]$}, lambda { |value|
        return [ TagLink.new('ISO: ' + value, 'https://www.iso.org/obp/ui/#iso:code:3166:' + value),
                 TagLink.new('Wikipedia: ' + value, 'https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#' + value) ]
    }),
    phone:     tag_match(%r{^\+[0-9. -]+$},  ->(value){ return [ TagLink.new('Phone number: ' + value, 'tel:' + value.gsub(/[ .-]+/, '-')) ] }),
    'ref:bag': tag_match(%r{^[0-9]+$},       lambda { |value|
        id = value.rjust(16, '0')
        return [ TagLink.new('Basisregistratie Adressen en Gebouwen (BAG): ' + id, 'https://bagviewer.kadaster.nl/lvbag/bag-viewer/index.html#?searchQuery=' + id) ]
    }),
    species:   tag_match(%r{^[a-zA-Z -]+$},  ->(value){ return [ TagLink.new('Wikispecies: ' + value, 'https://species.wikimedia.org/wiki/' + value) ] }),
    url:       tag_match(%r{^https?://},     ->(value){ return [ TagLink.new('Website', value) ] }),
    website:   tag_match(%r{^https?://},     ->(value){ return [ TagLink.new('Website', value) ] }),
    wikidata:  tag_match(%r{^Q[0-9]{1,10}$}, ->(value){ return [ TagLink.new('Wikidata: ' + value, 'https://www.wikidata.org/wiki/' + value) ] }),
    wikipedia: tag_match(%r{^[a-z-]{2,8}:},  lambda { |value|
        c = value.split(':')
        if $WIKIPEDIA_SITES.include?(c[0])
            return [ TagLink.new('Wikipedia', "https://#{c[0]}.wikipedia.org/wiki/#{c[1]}") ]
        end

        return []
    })
}

def get_links(key, value)
    tm = TAGLINKS[key.to_sym]
    return tm.links(value) if tm

    []
end
