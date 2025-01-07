# web/lib/tagstatus.rb

class TagStatus

    @@status_list = {}

    attr_reader :name, :known

    def initialize(name, known: false)
        @name = name
        @known = known
        @@status_list[name] = self
    end

    def self.[](name)
        @@status_list[name] || new(name)
    end

    def css_class
        return '' unless known

        ' tagstatus-' + name.tr(' ', '-')
    end

    def badge
        return '<i>(none)</i>' unless name

        "<a class='tagstatus#{ css_class }'>#{ name }</a>"
    end

end

TagStatus.new('in use', known: true)
TagStatus.new('de facto', known: true)
TagStatus.new('approved', known: true)
TagStatus.new('proposed', known: true)
TagStatus.new('imported', known: true)
TagStatus.new('deprecated', known: true)
TagStatus.new('obsolete', known: true)
TagStatus.new('discardable', known: true)
TagStatus.new('undefined', known: true)
