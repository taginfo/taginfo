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
#  Copyright (C) 2013  Jochen Topf <jochen@remote.org>
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

require 'cgi'

module MediaWikiAPI

    class API

        def initialize(host, port=80, path='/w/api.php?')
            @host = host
            @port = port
            @path = path
            @headers = {}
            add_header('User-agent', 'taginfo/1.0 (http://wiki.osm.org/wiki/Taginfo)')
        end

        def add_header(name, value)
            @headers[name] = value
        end

        def build_path(params)
            @path + params.to_a.map{ |el| CGI::escape(el[0].to_s) + '=' + CGI::escape(el[1].to_s) }.join('&')
        end

        def get(params)
            path = build_path(params)
            http = Net::HTTP.start(@host, @port)
#            puts "Getting path [#{path}]"
            result = http.get(path, @headers)
            result.body.force_encoding('UTF-8')
            result
        end

        def query(params)
            params[:action] = 'query'
            params[:format] = 'json'
            result = get(params)
            JSON.parse(result.body)
        end

    end

end

#-- THE END -------------------------------------------------------------------
