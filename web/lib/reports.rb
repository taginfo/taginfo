# web/lib/reports.rb
class Report

    @@reports = Array.new

    attr_reader :title, :sources

    def self.each
        @@reports.sort_by{ |report| report.title }.each do |report|
            yield report
        end
    end

    def initialize(title, sources)
        @@reports << self
        @title = title
        @sources = Hash.new
        sources.each do |s|
            @sources[s] = 1
        end
    end

    def name
        @title.gsub(/ /, '_').downcase
    end

    def url
        '/reports/' + name
    end

end

Report.new 'Characters in Keys', %w(db)
Report.new 'Frequently Used Keys Without Wiki Page', %w(db wiki)
Report.new 'Key Lengths', %w(db)
Report.new 'Language Comparison Table for Keys in the Wiki', %w(wiki)
Report.new 'Languages', %w(wiki)
Report.new 'Wiki Pages About Non-Existing Keys', %w(db wiki)
