# web/lib/ui/reports.rb
class Taginfo < Sinatra::Base

    get! '/reports' do
        @title = t.taginfo.reports
        @breadcrumbs << @title
        erb :'reports/index'
    end

    Report.each do |report|
        get report.url do
            @title = report.title
            @breadcrumbs << [ t.taginfo.reports, '/reports' ]
            @breadcrumbs << t.reports[report.name].name
            erb ('reports/' + report.name).to_sym
        end
    end

end
