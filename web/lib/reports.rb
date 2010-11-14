# web/lib/reports.rb
class Report

    @@reports = Array.new

    attr_reader :title, :sources

    def self.each
        @@reports.sort_by{ |report| report.title }.each do |report|
            yield report
        end
    end

    def initialize(title, *sources)
        @@reports << self
        @title = title
        @sources = Hash.new
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

end

Report.new 'Characters in Keys', :db
Report.new 'Frequently Used Keys Without Wiki Page', :db, :wiki
Report.new 'Key Lengths', :db
Report.new 'Language Comparison Table for Keys in the Wiki', :wiki
Report.new 'Languages', :wiki
Report.new 'Wiki Pages About Non-Existing Keys', :db, :wiki

