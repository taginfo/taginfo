# web/lib/javascript.rb

def javascript(url=nil, &block)
    @javascript ||= Array.new
    @javascript << Javascript.new(url, &block)
end

def javascript_tags
    @javascript.flatten.uniq.map{ |js| js.to_html }.join("\n")
end

def javascript_for(*ids)
    (@javascript ||= [] ) << Javascript.init(ids)
end

class Javascript

    @@js_files = {
#        :common    => [ 'jquery-1.11.1.min', 'jquery-ui-1.9.2.custom.min', 'jquery.tipsy-minified' ],
        :common    => [ 'common', 'jquery.slicknav.min' ],
        :taginfo   => [ 'taginfo' ],
        :flexigrid => [ 'jquery-migrate-1.2.1.min', 'flexigrid-minified' ],
        :d3        => [ 'd3/d3.min' ],
        :d3_cloud  => [ 'd3/d3.layout.cloud' ],
    }

    def self.init(ids)
        js = []
        ids.each do |id|
            @@js_files[id].each do |file|
                js << self.new(file)
            end
        end
        js
    end

    def initialize(file)
        if file.nil?
            c = ''
            r = yield c
            @content = (c == '' ? r : c)
        else
            @file = file
        end
    end

    def to_html
        if @file.nil?
            %Q{    <script type="text/javascript">\n#{ @content }\n</script>}
        else
            %Q{    <script type="text/javascript" src="/js/#{ @file }.js"></script>}
        end
    end

end

class JQuery

    # "include" the convenience methods from R18n::Helpers.
    # Uses extend instead of include, because we want this
    # to work not with instances of JQuery but they should
    # show up as JQuery class methods.
    extend R18n::Helpers

    def self.flexigrid(id, options)
        defaults = {
            :method        => 'GET',
            :dataType      => 'json',
            :pagetext      => t.flexigrid.pagetext,
            :pagestat      => t.flexigrid.pagestat,
            :outof         => t.flexigrid.outof,
            :findtext      => t.flexigrid.findtext,
            :procmsg       => t.flexigrid.procmsg,
            :nomsg         => t.flexigrid.nomsg,
            :errormsg      => t.flexigrid.errormsg,
            :showToggleBtn => false,
            :usepager      => true,
            :useRp         => true,
            :rp            => 15,
            :rpOptions     => [10,15,20,25,50,100],
        }
        "jQuery('##{id}').flexigrid(" + defaults.merge(options).to_json + ");\n"
    end

end

