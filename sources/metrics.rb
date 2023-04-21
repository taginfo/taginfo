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

require 'sqlite3'

#------------------------------------------------------------------------------

DIR = ARGV[0]

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

#-- THE END -------------------------------------------------------------------
