#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: DB
#
#  update_characters.rb
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

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-db.db')
database.results_as_hash = true

database.execute("PRAGMA journal_mode  = OFF")
database.execute("PRAGMA synchronous   = OFF")
database.execute("PRAGMA count_changes = OFF")
database.execute("PRAGMA temp_store    = MEMORY")
database.execute("PRAGMA cache_size    = 1000000")

#------------------------------------------------------------------------------

REGEXES = [
    [ 'plain',   %r{^[a-z]([a-z_]*[a-z])?$} ],
    [ 'colon',   %r{^[a-z][a-z_:]*[a-z]$} ],
    [ 'letters', %r{^[\p{L}\p{M}]([\p{L}\p{M}\p{N}_:]*[\p{L}\p{M}\p{N}])?$}u ],
    [ 'space',   %r{\p{Z}}u ],
    [ 'problem', %r{[=+/&<>;@'"?%#\\,\p{C}]}u ]
].freeze

keys = {}
database.execute("SELECT key FROM keys WHERE characters IS NULL").map{ |row| row['key'] }.each do |key|
    keys[key] = 'rest'
    REGEXES.each do |type, regex|
        if key.match(regex)
            keys[key] = type
            break
        end
    end
end

database.transaction do |db|
    keys.each do |key, type|
        db.execute("UPDATE keys SET characters=? WHERE key=?", [type, key])
    end
end

#-- THE END -------------------------------------------------------------------
