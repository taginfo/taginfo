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
            if File.exists?("viewsjs/reports/#{ report.name }.js.erb")
                javascript "#{ r18n.locale.code }/reports/#{ report.name }"
            end
            javascript_for(:flexigrid)
            erb ('reports/' + report.name).to_sym
        end
    end

end
