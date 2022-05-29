#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Software
#
#  parse-id-tagging-schema.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2022-2025  Jochen Topf <jochen@topf.org>
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

require 'json'
require 'sqlite3'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-sw.db')

#------------------------------------------------------------------------------

deprecated = File.open(dir + '/id-tagging-schema/dist/deprecated.json') do |file|
    JSON.parse(file.read, { :create_additions => false })
end

discarded = File.open(dir + '/id-tagging-schema/dist/discarded.json') do |file|
    JSON.parse(file.read, { :create_additions => false })
end

database.transaction do |db|
    deprecated.each do |entry|
        db.execute("INSERT INTO deprecated_tags_id_mapping (old_tags, replace_tags) VALUES (?, ?)", [JSON.generate(entry['old']), JSON.generate(entry['replace'])])
    end
    discarded.each do |k, _|
        db.execute("INSERT INTO discardable_tags (source, key) VALUES ('id', ?)", [k])
    end
end

#-- THE END -------------------------------------------------------------------
