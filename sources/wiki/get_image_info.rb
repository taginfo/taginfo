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
#  Wiki API request results are cached in wikicache-images.db.
#
#  The database must be in DIR or in the current directory, if no directory
#  was given on the command line.
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2023  Jochen Topf <jochen@topf.org>
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

require 'net/http'
require 'uri'
require 'json'
require 'sqlite3'

require 'mediawikiapi'

CACHE_HARD_EXPIRE = 60 # days
CACHE_SOFT_EXPIRE = 30 # days

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-wiki.db')
database.results_as_hash = true

database.execute("ATTACH DATABASE ? AS cache", dir + '/wikicache-images.db')

#------------------------------------------------------------------------------

time_spent_in_api_calls = 0

api = MediaWikiAPI::API.new

image_titles = database.execute("SELECT DISTINCT(image) AS title FROM wikipages WHERE image IS NOT NULL AND image != '' UNION SELECT DISTINCT(osmcarto_rendering) AS title FROM wikipages WHERE osmcarto_rendering IS NOT NULL AND osmcarto_rendering != '' UNION SELECT DISTINCT(image) AS title FROM relation_pages WHERE image IS NOT NULL AND image != ''").
                    map{ |row| row['title'] }.
                    select{ |title| title.match(%r{^(file|image):}i) }.
                    sort.
                    uniq

in_cache = 0
not_in_cache = 0

# Remove duplicate cache entries
database.execute("DELETE FROM cache_pages WHERE EXISTS (SELECT * FROM cache_pages b WHERE cache_pages.title=b.title AND cache_pages.timestamp < b.timestamp); ")

# Remove all very old cache entries
database.execute("DELETE FROM cache_pages WHERE timestamp < ?", [Time.now.to_i - (60 * 60 * 24 * CACHE_HARD_EXPIRE)])

# Remove some not so old cache entries
database.execute("DELETE FROM cache_pages WHERE timestamp < ? LIMIT 10", [Time.now.to_i - (60 * 60 * 24 * CACHE_SOFT_EXPIRE)])

database.transaction do |db|
    puts "Found #{ image_titles.size } different image titles"

    images_added = {}

    image_titles.each do |title|
        puts "Get image info for: #{ title }"

        begin
            result = nil
            database.execute("SELECT * FROM cache.cache_pages WHERE title=?", [title]) do |row|
                in_cache += 1
                puts "CACHE: Page '#{ title }' in cache"
                result = row['body']
            end

            if !result
                not_in_cache += 1
                puts "CACHE: Page '#{ title }' not in cache"
                starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
                response = api.get(:action => 'query', :format => 'json', :prop => 'imageinfo', :iiprop => 'url|size|mime', :titles => title, :iiurlwidth => 10, :iiurlheight => 10)
                result = response.body
                time_spent_in_api_calls += Process.clock_gettime(Process::CLOCK_MONOTONIC) - starting
                database.execute("INSERT INTO cache.cache_pages (title, timestamp, body) VALUES (?, ?, ?)", [title, Time.now.to_i, result])
            end

            data = JSON.parse(result, { :create_additions => false })

            if !data['query']
                puts "Wiki API call failed (no 'query' field):"
                pp data
                next
            end

            data['query']['normalized']&.each do |n|
                db.execute('UPDATE wikipages SET image=? WHERE image=?', [n['to'], n['from']])
                db.execute('UPDATE relation_pages SET image=? WHERE image=?', [n['to'], n['from']])
            end

            if !data['query']['pages']
                puts "Wiki API call failed (no 'pages' field):"
                pp data
                next
            end

            data['query']['pages'].each do |_, v|
                next unless v['imageinfo']
                next if images_added[v['title']]

                info = v['imageinfo'][0]
                if info['thumburl']&.match(%r{^(.*/)[0-9]{1,4}(px-.*)$})
                    prefix = Regexp.last_match(1)
                    suffix = Regexp.last_match(2)
                else
                    prefix = nil
                    suffix = nil
                    puts "Wrong thumbnail format: '#{info['thumburl']}'"
                end

                # The OSM wiki reports the wrong thumbnail URL for images
                # transcluded from Wikimedia Commons. This fixes those
                # URLs.
                if prefix && info['url'].match(%r{^https://upload\.wikimedia\.org/wikipedia/commons})
                    prefix.sub!('https://wiki.openstreetmap.org/w/images', 'https://upload.wikimedia.org/wikipedia/commons')
                end

                images_added[v['title']] = 1
                db.execute("INSERT INTO wiki_images (image, width, height, size, mime, image_url, thumb_url_prefix, thumb_url_suffix) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                           [
                               v['title'],
                               info['width'],
                               info['height'],
                               info['size'],
                               info['mime'],
                               info['url'],
                               prefix,
                               suffix
                           ])
            end
        rescue StandardError => e
            puts "Wiki API call error: #{e.message}"
            pp data
        end
    end
end

puts "In cache: #{ in_cache }"
puts "Not in cache: #{ not_in_cache }"
puts "Time spent in API calls: #{ time_spent_in_api_calls.to_i }s"

#-- THE END -------------------------------------------------------------------
