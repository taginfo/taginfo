# web/lib/api/v4/site.rb
class Taginfo < Sinatra::Base

    api(4, 'site/info', {
        :description => 'Get information about this taginfo site.',
        :result => [
            [:url,         :STRING, 'URL'],
            [:name,        :STRING, 'Name'],
            [:description, :STRING, 'Description'],
            [:icon,        :STRING, 'Path to icon which appears on the lop left corner of all pages.'],
            [:contact,     :STRING, 'Contact information to admin.'],
            [:area,        :STRING, 'Description of area covered.']
        ],
        :example => { }
    }) do
        data = {}
        [:url, :name, :description, :icon, :contact, :area].each do |k|
            data[k] = TaginfoConfig.get("instance.#{k}") 
        end
        return data.to_json
    end

    api(4, 'site/sources', {
        :description => 'Get information about the data sources used.',
        :result => [
            [:name        , :STRING, 'Name'],
            [:data_until  , :STRING, 'All changes in the source until this date are reflected in taginfo.'],
            [:update_start, :STRING, 'Date/Timestamp when last update was started.'],
            [:update_end  , :STRING, 'Date/Timestamp when last update was finished.']
        ],
        :example => { },
        :ui => '/sources'
    }) do
        return Source.visible.map{ |source| {
            :name         => source.name,
            :data_until   => source.data_until,
            :update_start => source.update_start,
            :update_end   => source.update_end
        }}.to_json
    end

end
