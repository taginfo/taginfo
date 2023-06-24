# web/lib/api/v4/site.rb
class Taginfo < Sinatra::Base

    api(4, 'site/config/geodistribution', {
        :description => 'Get information about the background map for distribution charts.',
        :result => [
            [:width,               :INT,    'width of background image'],
            [:height,              :INT,    'height of background image'],
            [:scale_image,         :FLOAT,  'scale factor for images'],
            [:scale_compare_image, :FLOAT,  'scale factor for comparison images'],
            [:background_image,    :STRING, 'URL of background image'],
            [:image_attribution,   :STRING, 'map attribution for comparison background']
        ],
        :example => {}
    }) do
        data = {}
        [:width, :height, :scale_image, :scale_compare_image, :background_image, :image_attribution].each do |k|
            data[k] = @taginfo_config.get("geodistribution.#{k}")
        end
        return JSON.generate(data, json_opts(params[:format]))
    end

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
        :example => {}
    }) do
        data = {}
        [:url, :name, :description, :icon, :contact, :area].each do |k|
            data[k] = @taginfo_config.get("instance.#{k}")
        end
        return JSON.generate(data, json_opts(params[:format]))
    end

    api(4, 'site/sources', {
        :description => 'Get information about the data sources used.',
        :result => [
            [:id          , :STRING, 'Id'],
            [:name        , :STRING, 'Name'],
            [:data_until  , :STRING, 'All changes in the source until this date are reflected in taginfo.'],
            [:update_start, :STRING, 'Date/Timestamp when last update was started.'],
            [:update_end  , :STRING, 'Date/Timestamp when last update was finished.']
        ],
        :example => {},
        :ui => '/sources'
    }) do
        return JSON.generate(@sources.visible.map do |source| {
            :id           => source.id,
            :name         => source.name,
            :data_until   => source.data_until,
            :update_start => source.update_start,
            :update_end   => source.update_end
        }
        end, json_opts(params[:format]))
    end

end
