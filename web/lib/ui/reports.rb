# web/lib/ui/reports.rb
class Taginfo < Sinatra::Base

    get! '/reports' do
        @title = t.taginfo.reports
        section :reports
        erb :'reports/index'
    end

    Report.each do |report|
        get report.url do
            @title = [report.title, t.taginfo.reports]
            section :reports
            if File.exist?("public/js/pages/reports/#{ report.name }.js")
                javascript "pages/reports/#{ report.name }"
            end
            erb ('reports/' + report.name).to_sym
        end
    end

end
