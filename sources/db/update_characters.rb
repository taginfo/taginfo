#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: DB
#
#  update_characters.rb
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

require 'sqlite3'

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-db.db')
db.results_as_hash = true

regexes = [
    [ 'plain',   %r{^[a-z]([a-z_]*[a-z])?$} ],
    [ 'colon',   %r{^[a-z][a-z_:]*[a-z]$} ],
    [ 'letters', %r{^[\p{L}\p{M}]([\p{L}\p{M}\p{N}_:]*[\p{L}\p{M}\p{N}])?$}u ],
    [ 'space',   %r{[\s\p{Z}]}u ],
    [ 'problem', %r{[=+/&<>;\@'"?%#\\,\p{C}]}u ]
];

keys = {}
db.execute("SELECT key FROM keys").map{ |row| row['key'] }.each do |key|
    keys[key] = 'rest'
    regexes.each do |type, regex|
        if key.match(regex)
            keys[key] = type
            break
        end
    end 
end

db.execute('BEGIN TRANSACTION');

keys.each do |key, type|
    db.execute("UPDATE keys SET characters=? WHERE key=?", type, key);
end

db.execute('COMMIT');

