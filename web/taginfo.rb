#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo
#
#------------------------------------------------------------------------------
#
#  taginfo.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2010  Jochen Topf <jochen@remote.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#------------------------------------------------------------------------------

require 'rubygems'
require 'sinatra/base'
require 'json'
require 'sqlite3'

require 'lib/utils.rb'
require 'lib/sql.rb'

#------------------------------------------------------------------------------

TAGCLOUD_NUMBER_OF_TAGS = 200

#------------------------------------------------------------------------------

class Taginfo < Sinatra::Base

    configure do
        set :app_file, __FILE__

        if ARGV[0]
            # production
            set :host, 'localhost'
            set :port, ARGV[0]
            set :environment, :production
        else
            # test
            enable :logging
        end
    end

    # make h() method for escaping HTML available
    helpers do
        include Rack::Utils
        alias_method :h, :escape_html
    end

    before do
        @db = SQL::Database.new('../../data')

        @stats = Hash.new

        @db.execute('SELECT key, value FROM master_stats') do |row|
            @stats[row[0]] = row[1].to_i
        end

        @stats['objects']                 = @stats['nodes']     + @stats['ways']     + @stats['relations']
        @stats['object_tags']             = @stats['node_tags'] + @stats['way_tags'] + @stats['relation_tags']
        @stats['nodes_with_tags_percent'] = (10000.0 * @stats['nodes_with_tags'] / @stats['nodes']).to_i.to_f           / 100
        @stats['tags_per_node']           = (  100.0 * @stats['node_tags']       / @stats['nodes_with_tags']).to_i.to_f / 100
        @stats['tags_per_way']            = (  100.0 * @stats['way_tags']        / @stats['ways']).to_i.to_f            / 100
        @stats['tags_per_relation']       = (  100.0 * @stats['relation_tags']   / @stats['relations']).to_i.to_f       / 100

        @data_until = @db.select("SELECT min(data_until) FROM master_meta").get_first_value().sub(/:..$/, '')

        @breadcrumbs = []
    end

    after do
        @db.close
    end

    #-------------------------------------

    before do
        if request.path_info =~ %r{^/api/}
            content_type :json
        end
    end

    #-------------------------------------

    get '/' do
        @tags = @db.select("SELECT key, scale1 FROM popular_keys ORDER BY scale1 DESC LIMIT #{ TAGCLOUD_NUMBER_OF_TAGS }").
            execute().
            each_with_index{ |tag, idx| tag['pos'] = (TAGCLOUD_NUMBER_OF_TAGS - idx) / TAGCLOUD_NUMBER_OF_TAGS.to_f }.
            sort{ |a,b| a['key'] <=> b['key'] }
        erb :index
    end

    ['about', 'contact', 'download', 'languages'].each do |page|
        get '/' + page do
            @title = page.capitalize
            @breadcrumbs << @title
            erb page.to_sym
        end
    end

    get '/sources/?' do
        @title = 'Sources'
        @breadcrumbs << @title
        @sources = @db.select('SELECT * FROM master_meta ORDER BY source_name').execute()
        erb :'sources/index'
    end

    get '/api' do
        @title = 'API'
        @breadcrumbs << @title
        erb :api
    end

    get '/keys' do
        @title = 'Keys'
        @breadcrumbs << ['Keys']
        erb :keys
    end

    get %r{^/keys/(.*)} do
        @key = params[:captures].first

        @key_html = escape_html(@key)
        @key_uri  = escape(@key)
        @key_json = @key.to_json
        @key_pp   = pp_key(@key)

        @title = [@key_html, 'Keys']
        @breadcrumbs << ['Keys', '/keys']
        @breadcrumbs << @key_html

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", @key).get_first_value())
        @desc = '<i>no description in wiki</i>' if @desc == ''

        @prevalent_values = @db.select("SELECT value, count_#{@filter_type} AS count FROM tags").
            condition('key=?', @key).
            condition('count > ?', @count_all_values * 0.02).
            order_by([:count], :count, 'DESC').
            execute().map{ |row| [{ 'value' => row['value'], 'count' => row['count'].to_i }] }

        # add "(other)" label for the rest of the values
        sum = @prevalent_values.inject(0){ |sum, x| sum += x[0]['count'] }
        @prevalent_values << [{ 'value' => '(other)', 'count' => @count_all_values - sum }]

        erb :key
    end

    get '/tags/:tag' do
        @tag = params[:tag]
        (@key, @value) = @tag.split('=', 2)

        @key_html = escape_html(@key)
        @key_uri  = escape(@key)
        @key_json = @key.to_json
        @key_pp   = pp_key(@key)

        @value_html = escape_html(@value)
        @value_uri  = escape(@value)
        @value_json = @value.to_json
        @value_pp   = pp_value(@value)

        @tag_html = @key_html + '=' + @value_html
        @tag_uri  = @key_uri  + '=' + @value_uri

        if @tag !~ /=/
            redirect '/keys/' + @tag
        end

        @title = [@tag_html, 'Tags']
        @breadcrumbs << ['Keys', '/keys']
        @breadcrumbs << [@key_html, '/keys/' + @key_uri]
        @breadcrumbs << @tag_html

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @count_all = @db.select('SELECT count_all FROM db.tags').condition('key = ? AND value = ?', @key, @value).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value=?", @key, @value).get_first_value())
        @desc = '<i>no description in wiki</i>' if @desc == ''

        erb :tag
    end

    get '/debug/tags/?' do
        @title = ['Tags', 'Debug']
        @breadcrumbs << 'Debug'
        @breadcrumbs << 'Tags'
        limit = 300;
        (@min, @max) = @db.select('SELECT min(count) AS min, max(count) AS max FROM popular_keys').get_columns(:min, :max)
        @tags = @db.select("SELECT key, count, (count - ?) / (? - ?) AS scale, in_wiki, in_josm FROM popular_keys ORDER BY count DESC LIMIT #{limit}", @min.to_f, @max, @min).
            execute().
            each_with_index{ |tag, idx| tag['pos'] = (limit - idx) / limit.to_f }.
            sort{ |a,b| a['key'] <=> b['key'] }
        erb :'debug/tags'
    end

    #--------------------------------------------------------------------------

    get '/search/?' do
        @title = 'Search results'
        @breadcrumbs << @title

        @escaped_search_string = escape_html(params[:search])

        @key = @db.select('SELECT key FROM keys').
            condition('key = ?', params[:search]).
            get_first_value()

        @substring_keys = @db.select('SELECT key FROM keys').
            condition("key LIKE '%' || ? || '%' AND key != ?", params[:search], params[:search]).
            order_by([:key], :key, 'ASC').
            execute().
            map{ |row| row['key'] }

        erb :search
    end

    #--------------------------------------------------------------------------

    get '/sources/db/?' do
        @title = 'Database'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Database']
        erb :'sources/db'
    end

    #--------------------------------------------------------------------------

    get '/sources/wiki/?' do
        @title = 'Wiki'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Wiki']
        erb :'sources/wiki/index'
    end

    get '/sources/wiki/keys/?' do
        @title = ['Keys', 'Wiki']
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['Wiki', '/sources/wiki']
        @breadcrumbs << ['Keys']

        @languages = @db.execute('SELECT language FROM wiki_languages ORDER by language').map do |row|
            row['language']
        end

        lang_lookup = Hash.new
        @languages.each_with_index do |lang, idx|
            lang_lookup[lang] = idx + 1
        end
        @languages_lookup = @languages.map{ |lang| "'#{lang}': #{lang_lookup[lang]}" }.join(', ')

        erb :'sources/wiki/keys'
    end

    #--------------------------------------------------------------------------

    get '/sources/josm/?' do
        @title = 'JOSM'
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['JOSM']
        erb :'sources/josm/index'
    end

    get '/sources/josm/styles/?' do
        @title = ['Styles', 'JOSM']
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['JOSM', '/sources/josm']
        @breadcrumbs << ['Styles']
        erb :'sources/josm/styles'
    end

    get '/sources/josm/styles/:style' do
        @stylename = h(params[:style])
        @title = [@stylename, 'Styles', 'JOSM']
        @breadcrumbs << ['Sources', '/sources']
        @breadcrumbs << ['JOSM', '/sources/josm']
        @breadcrumbs << ['Styles', '/sources/josm/styles']
        @breadcrumbs << @stylename
        erb :'sources/josm/style'
    end

    #--------------------------------------------------------------------------

    load 'lib/api/db.rb'
    load 'lib/api/wiki.rb'
    load 'lib/api/josm.rb'

    # run application
    run!

end

