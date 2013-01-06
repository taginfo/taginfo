# web/lib/api/wiki.rb
class Taginfo < Sinatra::Base

    api(2, 'wiki/keys') do
        key = params[:key]

        if key.nil?

            languages = @db.execute('SELECT language FROM wiki.wiki_languages ORDER by language').map do |row|
                row['language']
            end

            total = @db.count('wiki.wikipages_keys').
                condition_if("key LIKE '%' || ? || '%'", params[:query]).
                get_first_value().to_i

            res = @db.select('SELECT key, langs FROM wiki.wikipages_keys').
                condition_if("key LIKE '%' || ? || '%'", params[:query]).
                order_by(@ap.sortname, @ap.sortorder){ |o|
                    o.key
                }.
                paging(@ap).
                execute()

            return {
                :page  => @ap.page,
                :rp    => @ap.results_per_page,
                :total => total,
                :data  => res.map{ |row|
                    lang_hash = Hash.new
                    row['langs'].split(',').each{ |l|
                        (lang, status) = l.split(' ', 2)
                        lang_hash[lang] = status
                    }
                    { :key => row['key'], :lang => lang_hash }
                }
            }.to_json
        else
            res = @db.execute('SELECT * FROM wikipages WHERE value IS NULL AND key = ? ORDER BY lang', key)
            return get_wiki_result(res)
        end
    end

    api(2, 'wiki/tags') do
        key   = params[:key]
        value = params[:value]

        res = @db.execute('SELECT * FROM wikipages WHERE key = ? AND value = ? ORDER BY lang', key, value)

        return get_wiki_result(res)
    end

end
