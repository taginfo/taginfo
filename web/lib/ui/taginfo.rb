# web/lib/ui/taginfo.rb
class Taginfo < Sinatra::Base

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
        erb :'taginfo/index'
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

        erb :'taginfo/i18n'
    end

    get '/taginfo/apidoc' do
        @title = t.taginfo.apidoc
        @section = 'taginfo'
        @section_title = t.taginfo.meta
        erb :'taginfo/apidoc'
    end

end
