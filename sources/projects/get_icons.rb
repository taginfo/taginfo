#!/usr/bin/env ruby
# coding: utf-8
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  get_icons.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2014-2020  Jochen Topf <jochen@topf.org>
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

require 'net/https'
require 'uri'
require 'sqlite3'
require 'time'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-projects.db')

#------------------------------------------------------------------------------

def fetch(uri_str, limit = 10)
    raise ArgumentError, 'too many HTTP redirects' if limit == 0

    uri = URI(uri_str)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    case response
    when Net::HTTPRedirection then
        location = response['location']
        puts "    redirect to #{location}"
        fetch(location, limit - 1)
    else
        response
    end
end

projects = database.execute("SELECT id, icon_url FROM projects WHERE status='OK' AND (icon_url LIKE 'http://%' OR icon_url LIKE 'https://%') ORDER BY id")

projects.each do |id, url|
    puts "  #{id} #{url}"
    response = fetch(url)
    if response.code == '200'
        blob = SQLite3::Blob.new(response.body)
        database.execute("UPDATE projects SET icon = ? WHERE id = ?", [ blob, id ])
    end
end


#-- THE END -------------------------------------------------------------------
