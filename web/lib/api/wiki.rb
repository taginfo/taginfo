# web/lib/api/wiki.rb
class Taginfo < Sinatra::Base

    def get_wiki_result(res)
        return res.map{ |row| {
                :lang             => h(row['lang']),
                :language         => h(::Language[row['lang']].native_name),
                :language_en      => h(::Language[row['lang']].english_name),
                :title            => h(row['title']),
                :description      => h(row['description']),
                :image            => h(row['image']),
                :on_node          => row['on_node']     == '1' ? true : false,
                :on_way           => row['on_way']      == '1' ? true : false,
                :on_area          => row['on_area']     == '1' ? true : false,
                :on_relation      => row['on_relation'] == '1' ? true : false,
                :tags_implies     => row['tags_implies'    ].split(','),
                :tags_combination => row['tags_combination'].split(','),
                :tags_linked      => row['tags_linked'     ].split(',')
            }
        }.to_json
    end

    get '/api/2/wiki/keys' do
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
                order_by(params[:sortname], params[:sortorder]){ |o|
                    o.key
                }.
                paging(params[:rp], params[:page]).
                execute()

            return {
                :page  => params[:page].to_i,
                :rp    => params[:rp].to_i,
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

    get '/api/2/wiki/tags' do
        key   = params[:key]
        value = params[:value]

        res = @db.execute('SELECT * FROM wikipages WHERE key = ? AND value = ? ORDER BY lang', key, value)

        return get_wiki_result(res)
    end

end
