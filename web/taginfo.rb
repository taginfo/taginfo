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

$LOAD_PATH.unshift(File.dirname(__FILE__))

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
require 'lib/api.rb'
require 'lib/langtag/bcp47.rb'

#------------------------------------------------------------------------------

TaginfoConfig.read

#------------------------------------------------------------------------------

DATA_UNTIL = SQL::Database.init('../../data');

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
        javascript 'customSelect.jquery-minified'
        javascript 'jquery.tipsy-minified'
        javascript 'flexigrid-minified'
        javascript r18n.locale.code + '/texts'
        javascript 'taginfo'

        # set to immediate expire on normal pages
        # (otherwise switching languages doesn't work)
        expires 0, :no_cache

        @db = SQL::Database.new.attach_sources

        @data_until = DATA_UNTIL
    end

    after do
        @db.close
    end

    #-------------------------------------

    before '/api/*' do
        content_type :json
        expires next_update
        headers['Access-Control-Allow-Origin'] = '*'
        begin
            @ap = APIParameters.new(params)
        rescue ArgumentError => ex
            halt 412, { :error => ex.message }.to_json
        end
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
        javascript "#{ r18n.locale.code }/index"
        erb :index
    end

    #-------------------------------------

    %w(about download keys relations sources tags).each do |page|
        get '/' + page do
            @title = (page =~ /^(keys|tags|relations)$/) ? t.osm[page] : t.taginfo[page]
            if File.exists?("viewsjs/#{ page }.js.erb")
                javascript "#{ r18n.locale.code }/#{ page }"
            end
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

    # old deprecated API (version 2 and 3)
    load 'lib/api/db.rb'
    load 'lib/api/josm.rb'
    load 'lib/api/main.rb'
    load 'lib/api/reports.rb'
    load 'lib/api/search.rb'
    load 'lib/api/wiki.rb'

    # current API (version 4)
    load 'lib/api/v4/josm.rb'
    load 'lib/api/v4/key.rb'
    load 'lib/api/v4/keys.rb'
#    load 'lib/api/v4/langtag.rb'
    load 'lib/api/v4/relation.rb'
    load 'lib/api/v4/relations.rb'
    load 'lib/api/v4/search.rb'
    load 'lib/api/v4/site.rb'
    load 'lib/api/v4/tag.rb'
    load 'lib/api/v4/tags.rb'
    load 'lib/api/v4/wiki.rb'

    load 'lib/ui/embed.rb'
    load 'lib/ui/keys_tags.rb'
    load 'lib/ui/relation.rb'
    load 'lib/ui/reports.rb'
    load 'lib/ui/search.rb'
    load 'lib/ui/taginfo.rb'
    load 'lib/ui/test.rb'

    # run application
    run! if app_file == $0

end

