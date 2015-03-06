# web/lib/reports.rb
class Report

    @@reports = Array.new

    attr_reader :title, :sources

    def self.each
        @@reports.sort_by{ |report| report.title }.each do |report|
            yield report
        end
    end

    def self.each_visible
        @@reports.select{ |report| report.visible? }.sort_by{ |report| report.title }.each do |report|
            yield report
        end
    end

    def self.each_visible_with_index
        @@reports.select{ |report| report.visible? }.sort_by{ |report| report.title }.each_with_index do |report, idx|
            yield report, idx
        end
    end

    def initialize(title, *sources)
        @@reports << self
        @title = title
        @sources = Hash.new
        @visible = sources.size > 0
        sources.each do |id|
            @sources[id] = 1
        end
    end

    def uses_source?(id)
        sources.has_key? id
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
Report.new 'Name tags' #disabled
Report.new 'Similar keys', :db
Report.new 'Historic development', :db

