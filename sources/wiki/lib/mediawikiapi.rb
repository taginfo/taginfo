# coding: utf-8
#------------------------------------------------------------------------------
#
#  MediaWikiAPI
#
#------------------------------------------------------------------------------
#
#  Simple helper class to access the Mediawiki API.
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2020  Jochen Topf <jochen@topf.org>
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

require 'cgi'
require 'uri'
require 'net/https'

module MediaWikiAPI

    class API

        def initialize(path='/w/api.php?')
            @url = 'https://wiki.openstreetmap.org' + path
            @headers = {}
            add_header('User-agent', 'taginfo/1.0 (https://wiki.osm.org/wiki/Taginfo)')
        end

        def add_header(name, value)
            @headers[name] = value
        end

        def build_path(params)
            URI(@url + params.to_a.map{ |el| CGI::escape(el[0].to_s) + '=' + CGI::escape(el[1].to_s) }.join('&'))
        end

        def get(params)
            uri = build_path(params)
            http = Net::HTTP.new(uri.host, uri.port)
            if uri.scheme == 'https'
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
#            puts "Getting path [#{uri.request_uri}]"
            response = http.get(uri.request_uri, @headers)
            response.body.force_encoding('UTF-8')
            response
        end

        def query(params)
            params[:action] = 'query'
            params[:format] = 'json'
            result = get(params)
            JSON.parse(result.body, { :create_additions => false })
        end

    end

end

#-- THE END -------------------------------------------------------------------
