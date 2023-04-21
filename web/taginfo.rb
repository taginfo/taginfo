#!/usr/bin/env ruby
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
#  Copyright (C) 2010-2023  Jochen Topf <jochen@topf.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#------------------------------------------------------------------------------

v = RUBY_VERSION.split('.').map(&:to_i)
if v[0] < 2 || (v[0] == 2 && v[1] < 4)
    STDERR.puts "You need at least Ruby 2.4 to run taginfo"
    exit(1)
end

#------------------------------------------------------------------------------

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'json'
require 'sqlite3'
require 'yaml'
require 'date'

require 'sinatra/base'
require 'sinatra/r18n'
require 'rack/contrib'

require 'lib/utils'
require 'lib/taglinks'
require 'lib/config'
require 'lib/javascript'
require 'lib/language'
require 'lib/sql'
require 'lib/sources'
require 'lib/reports'
require 'lib/api'
require 'lib/langtag/bcp47'

#------------------------------------------------------------------------------

TAGINFO_CONFIG = TaginfoConfig.new(File.expand_path(File.dirname(__FILE__)) + '/../../taginfo-config.json')

#------------------------------------------------------------------------------

ALL_SECTIONS = %w[download taginfo test].freeze
SECTIONS = Hash[TAGINFO_CONFIG.get('instance.sections', ALL_SECTIONS).collect{ |s| [s.to_sym, s] }]

class Taginfo < Sinatra::Base

    register Sinatra::R18n

    use Rack::JSONP

    mime_type :opensearch, 'application/opensearchdescription+xml'

    configure do
        set :app_file, __FILE__

        # Disable rack-protection library because it messes up embedding
        # taginfo in an iframe. This should probably be done more
        # selectively, but there is no documentation on what rack-protection
        # is actually doing...
        disable :protection
    end

    # make h() method for escaping HTML available
    helpers do
        include Rack::Utils
        alias_method :h, :escape_html
    end

    # make trimming \n after %> the default in erb templates
    alias_method :erb_orig, :erb
    def erb(template, options = {}, locals = {})
        options[:trim] = '>' unless options[:trim]
        erb_orig template, options, locals
    end

    # when do we expect the next data update
    def next_update
        # 7 hours after midnight UTC
        ((Time.utc(Time.now.year, Time.now.month, Time.now.day, 7, 0, 0) + (Time.now.hour < 7 ? 0 : 24) * 60 * 60) - Time.now).to_i.to_i
    end

    before do
        @taginfo_config = TAGINFO_CONFIG

        if request.cookies['taginfo_locale'] && request.path != '/switch_locale'
            params[:locale] = request.cookies['taginfo_locale']
        end

        javascript_for(:taginfo)
        javascript r18n.locale.code + '/texts'

        # set to immediate expire on normal pages
        # (otherwise switching languages doesn't work)
        expires 0, :no_cache

        @db = SQL::Database.new(@taginfo_config)
        @sources = Sources.new(@taginfo_config, @db)
        $WIKIPEDIA_SITES = @db.execute('SELECT prefix FROM wikipedia_sites').map{ |row| row['prefix'] }

        data_until_raw = @db.select("SELECT min(data_until) FROM sources WHERE id='db'").get_first_value
        @data_until = data_until_raw.sub(/:..$/, '')
        @data_until_m = data_until_raw.sub(' ', 'T') + 'Z'

        @context = {
            instance: @taginfo_config.id,
            lang: r18n.locale.code || 'en'
        }
    end

    after do
        @db.close
    end

    #-------------------------------------

    before '/api/*' do
        content_type :json, :charset => 'UTF-8'
        expires next_update
        cors = @taginfo_config.get('instance.access_control_allow_origin', '')
        if cors != ""
            headers['Access-Control-Allow-Origin'] = cors
        end
        begin
            @ap = APIParameters.new(params)
        rescue ArgumentError => e
            halt 412, { :error => e.message }.to_json
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
        javascript "pages/index"
        erb :index
    end

    get '/test-index' do
        javascript "pages/test-index"
        erb :'test-index'
    end

    #-------------------------------------

    %w[about sources].each do |page|
        get '/' + page do
            @title = t.taginfo[page]
            section page
            erb page.to_sym
        end
    end

    %w[help].each do |page|
        get '/' + page do
            @title = t.misc.help
            section page
            erb page.to_sym
        end
    end

    %w[keys tags relations].each do |page|
        get '/' + page do
            @title = t.osm[page]
            section page
            javascript "/pages/#{ page }"
            erb page.to_sym
        end
    end

    #-------------------------------------

    get %r{/js/([a-z][a-z](-[a-zA-Z]+)?)/texts.js} do |lang, _|
        trans = R18n::I18n.new(lang, 'i18n').t.to_hash

        trans.delete('human_time')
        trans.each_key do |item|
            if trans[item].is_a?(String)
                trans.delete(item)
            end
        end

        expires next_update
        content_type 'text/javascript'
        'const texts = ' + JSON.generate(trans, { indent: '  ', object_nl:"\n" }) + ';'
    end

    get %r{/js/([a-z][a-z](-[a-zA-Z]+)?)/(.*).js} do |lang, _, js|
        expires next_update
        @lang = lang
        @trans = R18n::I18n.new(lang, 'i18n')
        erb :"#{js}.js", :layout => false, :content_type => 'text/javascript'
    end

    #--------------------------------------------------------------------------

    not_found do
        content_type :html
        erb :not_found
    end

    #--------------------------------------------------------------------------

    # current API (version 4)
    load 'lib/api/v4/key.rb'
    load 'lib/api/v4/keys.rb'
    load 'lib/api/v4/project.rb'
    load 'lib/api/v4/projects.rb'
    load 'lib/api/v4/relation.rb'
    load 'lib/api/v4/relations.rb'
    load 'lib/api/v4/search.rb'
    load 'lib/api/v4/site.rb'
    load 'lib/api/v4/tag.rb'
    load 'lib/api/v4/tags.rb'
    load 'lib/api/v4/unicode.rb'
    load 'lib/api/v4/wiki.rb'

    # test API (unstable, do not use)
    load 'lib/api/test/langtag.rb'

    # user interface
    load 'lib/ui/compare.rb'
    load 'lib/ui/embed.rb'
    load 'lib/ui/keys.rb'
    load 'lib/ui/projects.rb'
    load 'lib/ui/relation.rb'
    load 'lib/ui/reports.rb'
    load 'lib/ui/search.rb'
    load 'lib/ui/tags.rb'

    SECTIONS.each_key do |section|
        load "lib/ui/#{ section }.rb"
    end

    # run application
    run! if app_file == $PROGRAM_NAME

end
