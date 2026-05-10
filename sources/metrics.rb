#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  metrics.rb [DATA-DIR]
#
#------------------------------------------------------------------------------
#
#  Extract some metrics in the form needed by Prometheus from database files
#  and write it to stdout.
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2026  Jochen Topf <jochen@topf.org>
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

require 'sqlite3'

#------------------------------------------------------------------------------

DIR = ARGV[0]
SRCDIR = ARGV[1]

dbfiles = Dir.entries(DIR)
            .select{ |name| name.match(/^taginfo-[a-z]+.db$/) }
            .map{ |name| name.match(/^taginfo-([a-z]+).db$/)[1] }
            .sort

def dbfile(dbname)
    "#{DIR}/taginfo-#{dbname}.db"
end

print("# HELP taginfo_database_size The size of a taginfo database in bytes\n")
print("# TYPE taginfo_database_size gauge\n")

dbfiles.each do |dbname|
    size = File.size(dbfile(dbname))
    print(%(taginfo_database_size_bytes{database="#{dbname}"} #{size}\n))
end

db = SQLite3::Database.new(dbfile('master'), { readonly: true, results_as_hash: true })

results = db.execute("SELECT id, strftime('%s', update_start) AS start, strftime('%s', update_end) AS finish FROM sources ORDER BY id")

print("\n")
print("# HELP taginfo_database_update_start_seconds The time when the last update of the taginfo database started\n")
print("# TYPE taginfo_database_update_start_seconds gauge\n")

results.each do |row|
    print(%(taginfo_database_update_start_seconds{database="#{row['id']}"} #{row['start']}\n))
end

print("\n")
print("# HELP taginfo_database_update_finish_seconds The time when the last update of the taginfo database finished\n")
print("# TYPE taginfo_database_update_finish_seconds gauge\n")

results.each do |row|
    print(%(taginfo_database_update_finish_seconds{database="#{row['id']}"} #{row['finish']}\n))
end

results = db.execute("SELECT strftime('%s', data_until) AS data_from FROM sources WHERE id = 'db'")

print("\n")
print("# HELP taginfo_data_from_seconds The last update from the OSM database reflected in the taginfo data\n")
print("# TYPE taginfo_data_from_seconds gauge\n")
print(%(taginfo_data_from_seconds #{results[0]['data_from']}\n))

#------------------------------------------------------------------------------
# Wiki image cache
#------------------------------------------------------------------------------

IMAGE_CACHE_DB = "#{SRCDIR}/wiki/wikicache-images.db"

IMAGE_CACHE_MODIFICATION_TIME_MS = File.mtime(IMAGE_CACHE_DB).to_i * 1000

db_wikicache_images = SQLite3::Database.new(IMAGE_CACHE_DB, { readonly: true, results_as_hash: true })

print("\n")
print("# HELP taginfo_image_cache_age_days A histogram of image cache age in days\n")
print("# TYPE taginfo_image_cache_age_days histogram\n")
(10..100).step(10).each do |days|
    results = db_wikicache_images.execute("SELECT count(*) AS count FROM cache_pages WHERE ((unixepoch() - timestamp) / (60*60*24)) <= #{days}")
    print(%(taginfo_image_cache_age_days_bucket{le="#{days}"} #{results[0]['count']} #{IMAGE_CACHE_MODIFICATION_TIME_MS}\n))
end

results = db_wikicache_images.execute("SELECT count(*) AS count FROM cache_pages")
print(%(taginfo_image_cache_age_days_bucket{le="+Inf"} #{results[0]['count']} #{IMAGE_CACHE_MODIFICATION_TIME_MS}\n))
print(%(taginfo_image_cache_age_days_count #{results[0]['count']} #{IMAGE_CACHE_MODIFICATION_TIME_MS}\n))

results = db_wikicache_images.execute("SELECT COALESCE(sum((unixepoch() - timestamp) / (60*60*24)), 0) AS sum FROM cache_pages")
print(%(taginfo_image_cache_age_days_sum #{results[0]['sum']} #{IMAGE_CACHE_MODIFICATION_TIME_MS}\n))

print("\n")
print("# HELP taginfo_image_cache_repository_count Number of entries in image cache from different repositories\n")
print("# TYPE taginfo_image_cache_repository_count gauge\n")
results = db_wikicache_images.execute("SELECT COALESCE(value->>'imagerepository', 'NULL') AS repo, count(*) AS count FROM cache_pages, json_each(cache_pages.body, '$.query.pages') GROUP BY 1");
results.each do |row|
    print(%(taginfo_image_cache_repository_count{repo="#{row['repo']}"} #{row['count']} #{IMAGE_CACHE_MODIFICATION_TIME_MS}\n))
end

#-- THE END -------------------------------------------------------------------
