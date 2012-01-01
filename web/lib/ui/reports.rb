# web/lib/ui/reports.rb
class Taginfo < Sinatra::Base

    get! '/reports' do
        @title = t.taginfo.reports
        erb :'reports/index'
    end

    Report.each do |report|
        get report.url do
            @title = report.title
            @section = 'reports'
            @section_title = 'reports'
            erb ('reports/' + report.name).to_sym
        end
    end

end
