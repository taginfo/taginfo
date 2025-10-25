#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  update_cache.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2014-2025  Jochen Topf <jochen@topf.org>
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
db = SQLite3::Database.new(dir + '/projects-cache.db')

project_list = ARGV[1] || 'project_list.txt'

USER_AGENT = 'taginfo/1.0 (https://github.com/taginfo/taginfo)'.freeze

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
    request['User-Agent'] = USER_AGENT
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

ids = projects.map{ |id, _| "'#{ id }'" }.join(',')

db.execute("DELETE FROM fetch_log WHERE id NOT IN(#{ ids })")

# Make sure the log is not growing indefinitely
db.execute("DELETE FROM fetch_log WHERE fetch_status != '200' AND date(fetch_date, '+1 week') < date('now')")

projects.each do |id, url|
    puts "  #{id} #{url}"
    now = Time.now.utc.iso8601
    begin
        response = fetch(url)
        begin
            last_modified = Time.parse(response['Last-Modified'] || response['Date']).utc.iso8601
        rescue ArgumentError
            last_modified = now
        end
        if response.code == '200'
            db.execute("DELETE FROM fetch_log WHERE id=?", [id])
        end
        db.execute("INSERT INTO fetch_log (id, json_url, last_modified, fetch_date, fetch_status, fetch_json) VALUES (?, ?, ?, ?, CAST(? AS TEXT), ?)",
                   [
                       id,
                       url,
                       last_modified,
                       now,
                       response.code,
                       response.body
                   ])
    rescue StandardError
        db.execute("INSERT INTO fetch_log (id, json_url, fetch_date, fetch_status) VALUES (?, ?, ?, '999')",
                   [
                       id,
                       url,
                       now,
                   ])
    end
    sleep(1)
end

#-- THE END -------------------------------------------------------------------
