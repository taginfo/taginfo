#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  import.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2014-2023  Jochen Topf <jochen@topf.org>
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
db = SQLite3::Database.new(dir + '/taginfo-projects.db')

project_list = ARGV[1] || 'project_list.txt'

#------------------------------------------------------------------------------

projects = []
File.open(project_list) do |file|
    file.each do |line|
        projects << line.chomp.split
    end
end

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
    when Net::HTTPRedirection
        location = response['location']
        puts "    redirect to #{location}"
        fetch(location, limit - 1)
    else
        response
    end
end

projects.each do |id, url|
    puts "  #{id} #{url}"
    begin
        response = fetch(url)
        begin
            last_modified = Time.parse(response['Last-Modified'] || response['Date']).utc.iso8601
        rescue ArgumentError
            last_modified = Time.now.utc
        end
        db.execute("INSERT INTO projects (id, json_url, last_modified, fetch_date, fetch_status, fetch_json, status, data_updated) VALUES (?, ?, ?, ?, CAST(? AS TEXT), ?, ?, ?)",
                   [
                       id,
                       url,
                       last_modified,
                       Time.now.utc.iso8601,
                       response.code,
                       response.body,
                       (response.code == '200' ? 'OK' : 'FETCH ERROR'),
                       last_modified
                   ])
    rescue StandardError
        db.execute("INSERT INTO projects (id, json_url, fetch_date, fetch_status, status) VALUES (?, ?, ?, ?, ?)",
                   [
                       id,
                       url,
                       Time.now.utc.iso8601,
                       '500',
                       'FETCH ERROR'
                   ])
    end
end

#-- THE END -------------------------------------------------------------------
