# web/lib/reports.rb
class Report

    @@reports = []

    attr_reader :title, :sources

    def self.each(&block)
        @@reports.sort_by(&:title).each(&block)
    end

    def self.each_visible(&block)
        @@reports.select(&:visible?).sort_by(&:title).each(&block)
    end

    def self.each_visible_with_index(&block)
        @@reports.select(&:visible?).sort_by(&:title).each_with_index(&block)
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

    def visible?
        @visible
    end

end

Report.new 'Database statistics', :db
Report.new 'Characters in keys', :db
Report.new 'Frequently used keys without wiki page', :db, :wiki
Report.new 'Key lengths', :db
Report.new 'Language comparison table for keys in the wiki', :wiki
Report.new 'Languages', :wiki
Report.new 'Wiki pages about non-existing keys', :db, :wiki
Report.new 'Name tags' # disabled
Report.new 'Similar keys', :db
Report.new 'Historic development', :db
Report.new 'Wiki images', :wiki
# Report.new 'Wiki problems', :wiki
