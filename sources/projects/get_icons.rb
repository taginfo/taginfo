#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  get_icons.rb
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

vips_available = true
begin
    require 'vips'
rescue LoadError
    vips_available = false
end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-projects.db')

USER_AGENT = 'taginfo/1.0 (https://github.com/taginfo/taginfo)'.freeze

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

projects = database.execute("SELECT id, icon_url FROM projects WHERE status='OK' AND (icon_url LIKE 'http://%' OR icon_url LIKE 'https://%') ORDER BY id")

projects.each do |id, url|
    response = fetch(url)
    if response.code == '200'
        content_type = response['content-type'].force_encoding('UTF-8')
        content_type.sub!(/ *;.*/, '')
        if vips_available && ['image/png', 'image/jpg'].include?(content_type)
            input_image = Vips::Image.new_from_source(Vips::Source.new_from_memory(response.body), '')
            if input_image.width > 32 || input_image.height > 32
                resized_image = input_image.resize(32.to_f / [input_image.width, input_image.height].max)
                puts "  #{id} #{url} #{content_type} (#{input_image.width}x#{input_image.height} RESIZED TO #{resized_image.width}x#{resized_image.height})"
                image = SQLite3::Blob.new(if content_type == 'image/png'
                                              resized_image.pngsave_buffer
                                          else
                                              resized_image.jpgsave_buffer
                                          end)
            else
                puts "  #{id} #{url} #{content_type} (#{input_image.width}x#{input_image.height} USED AS IS)"
                image = SQLite3::Blob.new(response.body)
            end
            database.execute("UPDATE projects SET icon_type = ?, icon = ? WHERE id = ?", [ content_type, image, id ])
        elsif content_type =~ %r{^image/}
            puts "  #{id} #{url} #{content_type} (USED AS IS)"
            image = SQLite3::Blob.new(response.body)
            database.execute("UPDATE projects SET icon_type = ?, icon = ? WHERE id = ?", [ content_type, image, id ])
        else
            puts "  #{id} #{url} ERROR content-type=#{content_type}"
        end
    else
        puts "  #{id} #{url} ERROR code=#{response.code}"
    end
rescue StandardError => e
    puts "  #{id} #{url} ERROR: #{e.full_message}"
end

#-- THE END -------------------------------------------------------------------
