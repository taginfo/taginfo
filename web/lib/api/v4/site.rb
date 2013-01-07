# web/lib/api/v4/site.rb
class Taginfo < Sinatra::Base

    api(4, 'site/info', {
        :description => 'Get information about this taginfo site.',
        :result => {
            :url         => :STRING,
            :name        => :STRING,
            :description => :STRING,
            :icon        => :STRING,
            :contact     => :STRING,
            :area        => :STRING
        },
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
        :result => {
            :name         => :STRING,
            :data_until   => :STRING,
            :update_start => :STRING,
            :update_end   => :STRING
        },
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
