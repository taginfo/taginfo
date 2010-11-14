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
require 'json'
require 'sqlite3'

require 'sinatra/base'
require 'sinatra/r18n'

require 'lib/utils.rb'
require 'lib/javascript.rb'
require 'lib/language.rb'
require 'lib/sql.rb'
require 'lib/sources.rb'
require 'lib/reports.rb'

#------------------------------------------------------------------------------

TAGCLOUD_NUMBER_OF_TAGS = 200

#------------------------------------------------------------------------------

db = SQL::Database.new('../../data')

db.select('SELECT * FROM sources ORDER BY no').execute().each do |source|
    Source.new source['id'], source['name'], source['data_until'], source['update_start'], source['update_end'], source['visible'] == '1'
end

db.close

class Taginfo < Sinatra::Base

    register Sinatra::R18n

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

    # make trimming \n after %> the default in erb templates
    alias_method :erb_orig, :erb
    def erb(template, options={}, locals={})
        options[:trim] = '>' unless options[:trim]
        erb_orig template, options, locals
    end

    before do
#        if params[:locale]
#            response.set_cookie('taginfo_locale', params[:locale])
#        elsif request.cookies['taginfo_locale']
#            params[:locale] = request.cookies['taginfo_locale']
#        end
        params[:locale] = 'en'

        javascript 'jquery-1.3.2.min'
        javascript 'jquery-ui-1.7.2.all.min'
        javascript 'flexigrid-minified'
        javascript 'taginfo'
        javascript 'protovis-r3.2'

        @db = SQL::Database.new('../../data')

        @data_until = @db.select("SELECT min(data_until) FROM sources").get_first_value().sub(/:..$/, '')

        @breadcrumbs = []
    end

    after do
        @db.close
    end

    #-------------------------------------

    before '/api/*' do
        content_type :json
    end

    #-------------------------------------

    get '/' do
        @tags = @db.select("SELECT key, scale1 FROM popular_keys ORDER BY scale1 DESC LIMIT #{ TAGCLOUD_NUMBER_OF_TAGS }").
            execute().
            each_with_index{ |tag, idx| tag['pos'] = (TAGCLOUD_NUMBER_OF_TAGS - idx) / TAGCLOUD_NUMBER_OF_TAGS.to_f }.
            sort_by{ |row| row['key'] }
        erb :index
    end

    %w(about download keys).each do |page|
        get '/' + page do
            @title = t.taginfo[page]
            @breadcrumbs << @title
            erb page.to_sym
        end
    end

    get! '/sources' do
        @title = t.taginfo.sources
        @breadcrumbs << @title
        erb :'sources/index'
    end

    #-------------------------------------

    get %r{^/keys/(.*)} do |key|
        if params[:key].nil?
            @key = key
        else
            @key = params[:key]
        end

        @key_html = escape_html(@key)
        @key_uri  = escape(@key)
        @key_json = @key.to_json
        @key_pp   = pp_key(@key)

        @title = [@key_html, t.osm.keys]
        @breadcrumbs << [t.osm.keys, '/keys']
        @breadcrumbs << @key_html

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", @key).get_first_value())
        @desc = "<i>#{ t.ui.empty.no_description_in_wiki }</i>" if @desc == ''

        @prevalent_values = @db.select("SELECT value, count_#{@filter_type} AS count FROM tags").
            condition('key=?', @key).
            condition('count > ?', @count_all_values * 0.02).
            order_by(:count, 'DESC').
            execute().map{ |row| [{ 'value' => row['value'], 'count' => row['count'].to_i }] }

        # add "(other)" label for the rest of the values
        sum = @prevalent_values.inject(0){ |sum, x| sum += x[0]['count'] }
        if sum < @count_all_values
            @prevalent_values << [{ 'value' => '(other)', 'count' => @count_all_values - sum }]
        end

        @wiki_count = @db.count('wiki.wikipages').condition('value IS NULL').condition('key=?', @key).get_first_value().to_i
        
        (@merkaartor_type, @merkaartor_link, @merkaartor_selector) = @db.select('SELECT tag_type, link, selector FROM merkaartor.keys').condition('key=?', @key).get_columns(:tag_type, :link, :selector)
        @merkaartor_images = [:node, :way, :area, :relation].map{ |type|
            name = type.to_s.capitalize
            '<img src="/img/types/' + (@merkaartor_selector =~ /Type is #{name}/ ? type.to_s : 'none') + '.16.png" alt="' + name + '" title="' + name + '"/>'
        }.join('&nbsp;')

        @merkaartor_values = @db.select('SELECT value FROM merkaartor.tags').condition('key=?', @key).order_by(:value).execute().map{ |row| row['value'] }

        @merkaartor_desc = @db.select('SELECT lang, description FROM key_descriptions').condition('key=?', @key).order_by(:lang).execute()

        erb :key
    end

    #-------------------------------------

    get %r{^/tags/(.*)} do |tag|
        if tag.match(/=/)
            kv = tag.split('=', 2)
        else
            kv = [ tag, '' ]
        end
        if params[:key].nil?
            @key = kv[0]
        else
            @key = params[:key]
        end
        if params[:value].nil?
            @value = kv[1]
        else
            @value = params[:value]
        end
        @tag = @key + '=' + @value

        @key_html = escape_html(@key)
        @key_uri  = escape(@key)
        @key_json = @key.to_json
        @key_pp   = pp_key(@key)

        @value_html = escape_html(@value)
        @value_uri  = escape(@value)
        @value_json = @value.to_json
        @value_pp   = pp_value(@value)

        @title = [@key_html + '=' + @value_html, t.taginfo.tags]
        @breadcrumbs << [t.taginfo.keys, '/keys']
        @breadcrumbs << [@key_html, '/keys/' + @key_uri]
        @breadcrumbs << ( @value.length > 30 ? escape_html(@value[0,20] + '...') : @value_html)

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @count_all = @db.select('SELECT count_all FROM db.tags').condition('key = ? AND value = ?', @key, @value).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value=?", @key, @value).get_first_value())
        @desc = "<i>#{ t.ui.empty.no_description_in_wiki }</i>" if @desc == ''

        erb :tag
    end

    #--------------------------------------------------------------------------

    load 'lib/api/db.rb'
    load 'lib/api/wiki.rb'
    load 'lib/api/josm.rb'
    load 'lib/api/reports.rb'

    load 'lib/ui/search.rb'
    load 'lib/ui/reports.rb'
    load 'lib/ui/sources/db.rb'
    load 'lib/ui/sources/wiki.rb'
    load 'lib/ui/sources/josm.rb'
    load 'lib/ui/sources/potlatch.rb'
    load 'lib/ui/sources/merkaartor.rb'
    load 'lib/ui/test.rb'

    # run application
    run!

end

