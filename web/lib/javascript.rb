# web/lib/javascript.rb

def javascript(url=nil, &block)
    @javascript ||= Array.new
    @javascript << Javascript.new(url, &block)
end

def javascript_tags
    @javascript.map{ |js| js.to_html }
end

class Javascript

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
            %Q{        <script type="text/javascript">//<![CDATA[\n#{ @content }//]]></script>\n}
        else
            %Q{        <script type="text/javascript" src="/js/#{ @file }.js"></script>\n}
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

class JS

    #
    #  Careful, deep magic!
    #
    #  We redefine the to_json method of the String argument to return
    #  the raw string. This way we can do JS.raw("foo").to_json and get "foo".
    #
    def self.raw(code)
       code.instance_eval do
          def to_json(state=nil)
              to_s
          end
       end
       code
    end

end

