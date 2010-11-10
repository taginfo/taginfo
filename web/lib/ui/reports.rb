# web/lib/ui/reports.rb
class Taginfo < Sinatra::Base

    get! '/reports' do
        @title = 'Reports'
        @breadcrumbs << @title
        erb :'reports/index'
    end

    Report.each do |report|
        get report.url do
            @title = report.title
            @breadcrumbs << [ 'Reports', '/reports' ]
            @breadcrumbs << report.title
            erb ('reports/' + report.name).to_sym
        end
    end

end
