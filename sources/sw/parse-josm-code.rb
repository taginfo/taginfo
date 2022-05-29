#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Software
#
#  parse-josm-code.rb
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

require 'sqlite3'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-sw.db')

#------------------------------------------------------------------------------

discardable_tags_section = false
discardable_tags = []

File.readlines(dir + '/josm/src/org/openstreetmap/josm/data/osm/AbstractPrimitive.java', chomp: true).each do |line|
    if line.match(/public static Collection<String> getDiscardableKeys/)
        discardable_tags_section = true
    end
    if line.match(/return discardable/)
        discardable_tags_section = false
    end
    if discardable_tags_section && line.match(/^ +"([^"]*)",?$/)
        discardable_tags << Regexp.last_match(1)
    end
end

database.transaction do |db|
    discardable_tags.each do |key|
        db.execute("INSERT INTO discardable_tags (source, key) VALUES ('josm', ?)", [key])
    end
end

#-- THE END -------------------------------------------------------------------
