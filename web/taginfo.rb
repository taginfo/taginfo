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
#  Copyright (C) 2012  Jochen Topf <jochen@remote.org>
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
require 'rack/contrib'

require 'lib/utils.rb'
require 'lib/config.rb'
require 'lib/javascript.rb'
require 'lib/language.rb'
require 'lib/sql.rb'
require 'lib/sources.rb'
require 'lib/reports.rb'
require 'lib/apidoc.rb'

#------------------------------------------------------------------------------

TaginfoConfig.read

#------------------------------------------------------------------------------

db = SQL::Database.new('../../data')

db.select('SELECT * FROM sources ORDER BY no').execute().each do |source|
    Source.new source['id'], source['name'], source['data_until'], source['update_start'], source['update_end'], source['visible'].to_i == 1
end

DATA_UNTIL = db.select("SELECT min(data_until) FROM sources").get_first_value().sub(/:..$/, '')

db.close

class Taginfo < Sinatra::Base

    register Sinatra::R18n

    use Rack::JSONP

    mime_type :opensearch, 'application/opensearchdescription+xml'

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

    # when do we expect the next data update
    def next_update
        # three hours after midnight UTC
        ((Time.utc(Time.now.year(), Time.now.month(), Time.now.day(), 3, 0, 0) + (Time.now.hour < 3 ? 0 : 24)*60*60)-Time.now).to_i.to_i
    end

    before do
        if request.cookies['taginfo_locale'] && request.path != '/switch_locale'
            params[:locale] = request.cookies['taginfo_locale']
        end

        javascript 'jquery-1.5.1.min'
        javascript 'jquery-ui-1.8.10.custom.min'
        javascript 'customSelect.jquery'
        javascript 'jquery.tipsy'
#        javascript 'flexigrid-minified'
        javascript 'flexigrid'
        javascript 'protovis-r3.2'
        javascript 'lang/' + r18n.locale.code
        javascript 'taginfo'

        # set to immediate expire on normal pages
        # (otherwise switching languages doesn't work)
        expires 0, :no_cache

        @db = SQL::Database.new('../../data')

        @data_until = DATA_UNTIL
    end

    after do
        @db.close
    end

    #-------------------------------------

    before '/api/*' do
        content_type :json
        expires next_update
    end

    #-------------------------------------

    # This is called when the language is changed with the pull-down menu in the top-right corner.
    # It sets a cookie and redirects back to the page the user was coming from.
    get '/switch_locale' do
        response.set_cookie('taginfo_locale', params[:locale])
        redirect(TaginfoConfig.get('instance.url') + params[:url])
    end

    #-------------------------------------

    get '/' do
        # This is the maximum number of tags in the tag cloud. Javascript code will remove tags if the
        # window is to small to show all of them.
        tagcloud_number_of_tags = 260
        @tags = @db.select("SELECT key, scale1 FROM popular_keys ORDER BY scale1 DESC LIMIT #{ tagcloud_number_of_tags }").
            execute().
            each_with_index{ |tag, idx| tag['pos'] = (tagcloud_number_of_tags - idx) / tagcloud_number_of_tags.to_f }.
            sort_by{ |row| row['key'] }
        erb :index
    end

    #-------------------------------------

    %w(about apidoc download keys sources tags).each do |page|
        get '/' + page do
            @title = t.taginfo[page]
            erb page.to_sym
        end
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
        section :keys

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @count_all_values = @db.select("SELECT count_#{@filter_type} FROM db.keys").condition('key = ?', @key).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value IS NULL", r18n.locale.code, @key).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value IS NULL", @key).get_first_value()) if @desc == ''
        @desc = "<span class='empty'>#{ t.pages.key.no_description_in_wiki }</span>" if @desc == ''

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
        @user_count = @db.select('SELECT users_all FROM db.keys').condition('key=?', @key).get_first_value().to_i
        
        (@merkaartor_type, @merkaartor_link, @merkaartor_selector) = @db.select('SELECT tag_type, link, selector FROM merkaartor.keys').condition('key=?', @key).get_columns(:tag_type, :link, :selector)
        @merkaartor_images = [:node, :way, :area, :relation].map{ |type|
            name = type.to_s.capitalize
            '<img src="/img/types/' + (@merkaartor_selector =~ /Type is #{name}/ ? type.to_s : 'none') + '.16.png" alt="' + name + '" title="' + name + '"/>'
        }.join('&nbsp;')

        @merkaartor_values = @db.select('SELECT value FROM merkaartor.tags').condition('key=?', @key).order_by(:value).execute().map{ |row| row['value'] }

        @merkaartor_desc = @db.select('SELECT lang, description FROM key_descriptions').condition('key=?', @key).order_by(:lang).execute()

        @img_width  = TaginfoConfig.get('geodistribution.width')  * TaginfoConfig.get('geodistribution.scale_image')
        @img_height = TaginfoConfig.get('geodistribution.height') * TaginfoConfig.get('geodistribution.scale_image')

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
        section :tags

        @filter_type = get_filter()
        @sel = Hash.new('')
        @sel[@filter_type] = ' selected="selected"'

        @wiki_count = @db.count('wiki.wikipages').condition('value=?', @value).condition('key=?', @key).get_first_value().to_i
        @count_all = @db.select('SELECT count_all FROM db.tags').condition('key = ? AND value = ?', @key, @value).get_first_value().to_i

        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang=? AND key=? AND value=?", r18n.locale.code, @key, @value).get_first_value())
        @desc = h(@db.select("SELECT description FROM wiki.wikipages WHERE lang='en' AND key=? AND value=?", @key, @value).get_first_value()) if @desc == ''
        @desc = "<span class='empty'>#{ t.pages.tag.no_description_in_wiki }</span>" if @desc == ''

        erb :tag
    end

    #-------------------------------------

    get '/js/lang/:lang.js' do
        expires next_update
        trans = R18n::I18n.new(params[:lang], 'i18n')
        return 'var texts = ' + {
            :flexigrid => {
                :pagetext => trans.t.flexigrid.pagetext,
                :pagestat => trans.t.flexigrid.pagestat,
                :outof    => trans.t.flexigrid.outof,
                :findtext => trans.t.flexigrid.findtext,
                :procmsg  => trans.t.flexigrid.procmsg,
                :nomsg    => trans.t.flexigrid.nomsg,
                :errormsg => trans.t.flexigrid.errormsg,
            },
            :instance_description => {
                :title => trans.t.taginfo.instance.title,
            },
            :misc => {
                :values_less_than_one_percent => trans.t.misc.values_less_than_one_percent,
                :empty_string => trans.t.misc.empty_string,
                :count => trans.t.misc.count,
                :no_image => trans.t.misc.no_image,
                :all => trans.t.misc.all,
            },
            :osm => {
                :key => trans.t.osm.key,
                :keys => trans.t.osm.keys,
                :value => trans.t.osm.value,
                :values => trans.t.osm.values,
                :tag => trans.t.osm.tag,
                :tags => trans.t.osm.tags,
                :node => trans.t.osm.node,
                :nodes => trans.t.osm.nodes,
                :way => trans.t.osm.way,
                :ways => trans.t.osm.ways,
                :relation => trans.t.osm.relation,
                :relations => trans.t.osm.relations,
                :all => trans.t.osm.all
            },
            :pages => {
                :key => {
                    :other_keys_used => {
                        :other => trans.t.pages.key.other_keys_used.other,
                    },
                    :number_objects => trans.t.pages.key.number_objects,
                },
                :tag => {
                    :other_tags_used => {
                        :other => trans.t.pages.tag.other_tags_used.other,
                    },
                },
            },
        }.to_json + ";\n"
    end

    #--------------------------------------------------------------------------

    load 'lib/api/main.rb'
    load 'lib/api/db.rb'
    load 'lib/api/wiki.rb'
    load 'lib/api/josm.rb'
    load 'lib/api/reports.rb'
    load 'lib/api/search.rb'

    load 'lib/ui/search.rb'
    load 'lib/ui/reports.rb'
    load 'lib/ui/sources/db.rb'
    load 'lib/ui/sources/wiki.rb'
    load 'lib/ui/sources/josm.rb'
    load 'lib/ui/sources/potlatch.rb'
    load 'lib/ui/sources/merkaartor.rb'
    load 'lib/ui/embed.rb'
    load 'lib/ui/test.rb'

    # run application
    run! if app_file == $0

end

