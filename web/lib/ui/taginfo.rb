# web/lib/ui/taginfo.rb
class Taginfo < Sinatra::Base

    def count_texts(data)
        data.values.map{ |value|
            if value.is_a?(Hash)
                count_texts(value)
            else
                1
            end
        }.inject(0, :+)
    end

    def i18n_walk(line, level, path, en, other)
        out = ''
        en.keys.sort.each do |key|
            name = path.sub(/^\./, '') + '.' + key
            name.sub!(/^\./, '')
            if en[key].class == Hash
                if other.nil?
                    out += line.call(level, "<b>#{key}</b>", name, '', '<span style="color: red;">MISSING</span>')
                else
                    out += line.call(level, "<b>#{key}</b>", name, '', '')
                    out += i18n_walk(line, level+1, path + '.' + key, en[key], other[key])
                end
            else
                if other.nil?|| ! other[key]
                    out += line.call(level, key, name, en[key], '<span style="color: red;">MISSING</span>')
                else
                    out += line.call(level, key, name, en[key], other[key])
                end 
            end
        end
        out
    end

    get '/taginfo' do
        begin
            @commit = `git rev-parse HEAD`.chop
        rescue
            @commit = 'unknown'
        end
        erb :'taginfo/index'
    end

    get '/taginfo/status' do
        content_type 'text/plain'
        age_in_days = DateTime.now() - DateTime.parse(@data_until)
        if age_in_days.to_f > 1.5
            halt 400, "data_too_old\n"
        else
            return "ok\n"
        end
    end

    get '/taginfo/config' do
        @title = 'Configuration'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @config = TaginfoConfig.sanitized_config

        erb :'taginfo/config'
    end

    get '/taginfo/translations' do
        @title = 'Translations Overview'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @num_texts = {}
        r18n.available_locales.each do |lang|
            data = YAML.load_file("i18n/#{lang.code}.yml")
            @num_texts[lang.code] = count_texts(data)
        end

        erb :'taginfo/translations'
    end

    get '/taginfo/i18n' do
        @title = 'Translations of taginfo texts'
        @section = 'taginfo'
        @section_title = t.taginfo.meta
        @lang = params[:lang] || 'de'
        @i18n_en   = YAML.load_file("i18n/en.yml")
        begin
            @i18n_lang = YAML.load_file("i18n/#{@lang}.yml")
        rescue
            @error = "Unknown language: #{@lang}"
        end 

        c = 'even'
        @line = lambda { |level, key, name, en, other|    
            c = (c == '') ? 'even': ''
            "<tr><td class='#{c}' style='padding-left: #{ level * 16 + 6 }px;'><span title='#{ name }'>#{ key }</span></td><td class='#{c}'>#{ en }</td><td class='#{c}'>#{ other }</td></tr>"
        }

        javascript "#{ r18n.locale.code }/taginfo/i18n"
        erb :'taginfo/i18n'
    end

    get '/taginfo/apidoc' do
        @title = t.taginfo.apidoc
        @section = 'taginfo'
        @section_title = t.taginfo.meta
        erb :'taginfo/apidoc'
    end

    get '/taginfo/projects' do
        @title = t.taginfo.projects
        @section = 'taginfo'
        @section_title = t.taginfo.meta
        erb :'taginfo/projects'
    end

end
