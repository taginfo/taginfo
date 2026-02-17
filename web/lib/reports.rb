# web/lib/reports.rb
class Report

    @@reports = []

    attr_reader :title, :sources

    def self.each(&block)
        @@reports.sort_by(&:title).each(&block)
    end

    def self.each_visible_with_index(sources, &block)
        @@reports.select{ |report| report.visible?(sources) }.sort_by(&:title).each_with_index(&block)
    end

    def initialize(title, *sources)
        @@reports << self
        @title = title
        @sources = {}
        @visible = !sources.empty?
        sources.each do |id|
            @sources[id] = 1
        end
    end

    def uses_source?(id)
        sources.key?(id)
    end

    def name
        @title.gsub(/[\s-]/, '_').downcase
    end

    def url
        '/reports/' + name
    end

    def visible?(sources)
        @visible && @sources.all?{ |s| sources.get(s[0]) }
    end

end

Report.new 'Characters in keys', :db
Report.new 'Frequently used keys without wiki page', :db, :wiki
Report.new 'Key lengths', :db
Report.new 'Languages', :wiki
Report.new 'Wiki pages about non-existing keys', :db, :wiki
Report.new 'Name tags' # disabled
Report.new 'Similar keys', :db
Report.new 'Historic development', :db
Report.new 'Discardable tags', :db, :wiki, :sw
