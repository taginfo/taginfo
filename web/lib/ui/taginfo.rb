# web/lib/ui/taginfo.rb
class Taginfo < Sinatra::Base

    def count_texts(data)
        data.values.map do |value|
            if value.is_a?(Hash)
                count_texts(value)
            else
                1
            end
        end.inject(0, :+)
    end

    def i18n_walk(line, level, path, en, other)
        out = ''
        en.keys.sort.each do |key|
            name = path.sub(/^\./, '') + '.' + key
            name.sub!(/^\./, '')
            if en[key].instance_of?(Hash)
                if other.nil?
                    out += line.call(level, "<b>#{key}</b>", name, '', '<span style="color: red;">MISSING</span>')
                else
                    out += line.call(level, "<b>#{key}</b>", name, '', '')
                    out += i18n_walk(line, level + 1, path + '.' + key, en[key], other[key])
                end
            else
                out += if other.nil? || !other[key]
                           line.call(level, key, name, en[key], '<span style="color: red;">MISSING</span>')
                       else
                           line.call(level, key, name, en[key], other[key])
                       end
            end
        end
        out
    end

    def get_commit
        @commit = `git rev-parse HEAD`.chop
        @commit_date = Time.parse(`git show -s --format=%ci HEAD`.chop).utc.iso8601
    rescue StandardError
        @commit = 'unknown'
        @commit_date = 'unknown'
    end

    get! '/taginfo' do
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        get_commit

        erb :'taginfo/index'
    end

    get '/taginfo/version' do
        get_commit
        "#{@commit} #{@commit_date}\n"
    end

    get '/taginfo/status' do
        content_type 'text/plain'
        age_in_days = DateTime.now - DateTime.parse(@data_until)
        return "ok\n" unless age_in_days.to_f > 1.5

        halt 400, "data_too_old\n"
    end

    get '/taginfo/stats' do
        @title = 'Statistics'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @stats = @db.select("SELECT * FROM master_stats ORDER BY key").execute

        erb :'taginfo/stats'
    end

    get '/taginfo/config' do
        @title = 'Configuration'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @config = @taginfo_config.sanitized_config

        erb :'taginfo/config'
    end

    get '/taginfo/translations' do
        @title = 'Translations Overview'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @num_texts = {}
        r18n.available_locales.each do |lang|
            data = YAML.load_file("i18n/#{lang.code.downcase}.yml")
            @num_texts[lang.code] = count_texts(data)
        end

        erb :'taginfo/translations'
    end

    get '/taginfo/i18n' do
        @title = 'Translations of taginfo texts'
        @section = 'taginfo'
        @section_title = t.taginfo.meta
        @lang = params[:lang] || 'de'
        @i18n_en = YAML.load_file("i18n/en.yml")
        begin
            @i18n_lang = YAML.load_file("i18n/#{@lang.downcase}.yml")
        rescue StandardError
            @error = "Unknown language: #{@lang}"
        end

        c = 'even'
        @line = lambda { |level, key, name, en, other|
            c = (c == '') ? 'even': ''
            "<tr><td class='#{c}' style='padding-left: #{ level * 16 + 6 }px;'><span data-tooltip-position='OnRight' title='#{ name }'>#{ key }</span></td><td class='#{c}'>#{ en }</td><td class='#{c}' lang='#{@lang}' dir='#{direction_from_lang_code(@lang)}'>#{ other }</td></tr>"
        }

        javascript "pages/taginfo/i18n"
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

        @projects = @db.select("SELECT * FROM projects.projects ORDER BY id").execute

        erb :'taginfo/projects'
    end

    get %r{/taginfo/projects/([a-z_]+)/error_log} do |id|
        @title = "Error log for project #{ id }"
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @data = @db.select("SELECT name, error_log FROM projects.projects").
            condition("id = ?", id).
            execute[0]

        erb :'taginfo/project_error_log'
    end

    get '/taginfo/taglinks' do
        @title = 'Taglinks'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @data = {}
        TAGLINKS.each do |key, match|
            row = @db.select("SELECT count_all, values_all FROM db.keys").
                condition("key = ?", key.to_s).
                get_first_row

            @data[key] = row

            matching = 0

            pcre_extension = @taginfo_config.get('paths.sqlite3_pcre_extension')
            if pcre_extension
                matching = @db.count('db.tags').
                    condition("key = ?", key.to_s).
                    condition("value REGEXP ?", match.regex.to_s).
                    get_first_i
            end

            @data[key]['values_match'] = matching

            @data[key]['links'] = match.call('VALUE')
        end

        erb :'taginfo/taglinks'
    end

    get '/taginfo/wiki-problems' do
        @title = 'Wiki problems'
        @section = 'taginfo'
        @section_title = t.taginfo.meta

        @stats_reason = @db.select("SELECT reason, count(*) AS count FROM wiki.problems GROUP BY reason ORDER BY reason").execute
        @stats_lang   = @db.select("SELECT lang,   count(*) AS count FROM wiki.problems GROUP BY lang   ORDER BY lang").execute

        javascript_for(:d3)
        javascript "pages/taginfo/wiki-problems"
        erb :'taginfo/wiki-problems'
    end

end
