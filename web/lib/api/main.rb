# web/lib/api/main.rb
class Taginfo < Sinatra::Base

    api(2, 'about', {
    }) do
        data = {}
        [:url, :name, :description, :icon, :contact, :area].each do |k|
            data[k] = TaginfoConfig.get("instance.#{k}") 
        end
        return data.to_json
    end

end
