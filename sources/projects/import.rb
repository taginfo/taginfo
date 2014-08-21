#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  import.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2014  Jochen Topf <jochen@remote.org>
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

require 'net/http'
require 'sqlite3'
require 'time'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-projects.db')

project_list = ARGV[1] || 'project_list.txt'

#------------------------------------------------------------------------------

projects = []
open(project_list) do |file|
    file.each do |line|
        projects << line.chomp.split(' ')
    end
end

projects.each do |id, url|
    puts "  #{id} #{url}"
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)
        last_modified = Time.parse(response['Last-Modified']).utc.iso8601
        db.execute("INSERT INTO projects (id, json_url, last_modified, fetch_date, fetch_status, fetch_json, fetch_result, data_updated) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            id,
            url,
            last_modified,
            Time.now.utc.iso8601,
            response.code,
            response.body,
            (response.code == '200' ? 'OK' : 'FETCH ERROR'),
            last_modified
        );
    end
end


#-- THE END -------------------------------------------------------------------
