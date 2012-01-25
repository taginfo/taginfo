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
require 'yaml'

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
        javascript r18n.locale.code + '/texts'
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
        redirect(params[:url])
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

    %w(about download keys sources tags).each do |page|
        get '/' + page do
            @title = (page =~ /^(keys|tags)$/) ? t.osm[page] : t.taginfo[page]
            erb page.to_sym
        end
    end

    #-------------------------------------

    get %r{^/js/([a-z][a-z])/(.*).js$} do |lang, js|
        expires next_update
        @lang = lang
        @trans = R18n::I18n.new(lang, 'i18n')
        erb :"#{js}.js", :layout => false, :content_type => 'text/javascript', :views => 'viewsjs'
    end

    #--------------------------------------------------------------------------

    load 'lib/api/db.rb'
    load 'lib/api/josm.rb'
    load 'lib/api/main.rb'
    load 'lib/api/reports.rb'
    load 'lib/api/search.rb'
    load 'lib/api/wiki.rb'

    load 'lib/ui/embed.rb'
    load 'lib/ui/keys_tags.rb'
    load 'lib/ui/reports.rb'
    load 'lib/ui/search.rb'
    load 'lib/ui/taginfo.rb'
    load 'lib/ui/test.rb'

    # run application
    run! if app_file == $0

end

