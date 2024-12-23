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
            javascript_if_exists "pages/reports/#{ report.name }"
            erb ('reports/' + report.name).to_sym
        end
    end

    get '/reports/database_statistics' do
        redirect '/sources/db'
    end

    get '/reports/language_comparison_table_for_keys_in_the_wiki' do
        redirect '/sources/wiki/language_comparison_table_for_keys'
    end

    get '/reports/wiki_images' do
        redirect '/sources/wiki/image_comparison'
    end

end
