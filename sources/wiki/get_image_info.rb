#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  get_image_info.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Gets meta information about images from the OSM wiki.
#
#  Reads the list of all images used in Key: and Tag: pages from the local
#  database and requests meta information (width, height, mime type, URL, ...)
#  for those images. Writes this data into the wiki_images table.
#
#  The database must be in DIR or in the current directory, if no directory
#  was given on the command line.
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

require 'pp'

require 'net/http'
require 'uri'
require 'json'
require 'sqlite3'

require './lib/mediawikiapi.rb'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-wiki.db')
db.results_as_hash = true

#------------------------------------------------------------------------------

api = MediaWikiAPI::API.new('wiki.openstreetmap.org')

image_titles = db.execute("SELECT DISTINCT(image) AS title FROM wikipages WHERE image IS NOT NULL AND image != '' UNION SELECT DISTINCT(image) AS title FROM relation_pages WHERE image IS NOT NULL AND image != ''").
                    map{ |row| row['title'] }.
                    select{ |title| title.match(%r{^(file|image):}i) }

db.transaction do |db|
    puts "Found #{ image_titles.size } different image titles"

    images_added = {}

    until image_titles.empty?
        some_titles = image_titles.slice!(0, 10)
        puts "Get image info for: #{ some_titles.join(' ') }"

        begin
            data = api.query(:prop => 'imageinfo', :iiprop => 'url|size|mime', :titles => some_titles.join('|'), :iiurlwidth => 10, :iiurlheight => 10)

            if !data['query']
                puts "Wiki API call failed (no 'query' field):"
                pp data
                next
            end

            normalized = data['query']['normalized']
            if normalized
                normalized.each do |n|
                    db.execute('UPDATE wikipages SET image=? WHERE image=?', n['to'], n['from'])
                    db.execute('UPDATE relation_pages SET image=? WHERE image=?', n['to'], n['from'])
                end
            end

            if !data['query']['pages']
                puts "Wiki API call failed (no 'pages' field):"
                pp data
                next
            end

            data['query']['pages'].each do |k,v|
                if v['imageinfo'] && ! images_added[v['title']]
                    info = v['imageinfo'][0]
                    if info['thumburl'].match(%r{^(.*/)[0-9]{1,4}(px-.*)$})
                        prefix = $1
                        suffix = $2
                    else
                        prefix = nil
                        suffix = nil
                        puts "Wrong thumbnail format: '#{info['thumburl']}'"
                    end
                    images_added[v['title']] = 1
                    db.execute("INSERT INTO wiki_images (image, width, height, size, mime, image_url, thumb_url_prefix, thumb_url_suffix) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                        v['title'],
                        info['width'],
                        info['height'],
                        info['size'],
                        info['mime'],
                        info['url'],
                        prefix,
                        suffix
                    )
                end
            end
        rescue
            puts "Wiki API call error:"
            pp data
        end
    end
end


#-- THE END -------------------------------------------------------------------
