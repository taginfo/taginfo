#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Languages
#
#  import_unicode_data.rb
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
database = SQLite3::Database.new(dir + '/taginfo-languages.db')
database.results_as_hash = true

#------------------------------------------------------------------------------

unicode_data_file = "#{dir}/UnicodeData.txt"

mappings = database.execute("SELECT codepoint_from, codepoint_to, script FROM unicode_codepoint_script_mapping").map do |row|
    from = row['codepoint_from'].to_i
    to = row['codepoint_to'].to_i
    [(from..to), row['script']]
end

def get_script(mappings, codepoint)
    mappings.each do |m|
        if m[0].cover?(codepoint)
            return m[1]
        end
    end
    'Zzzz'
end

database.transaction do |db|
    File.open(unicode_data_file) do |file|
        file.each do |line|
            line.chomp!
            (codepoint, name, category) = line.split(';')
            codepoint = codepoint.to_i(16)
            script = get_script(mappings, codepoint)
            db.execute("INSERT INTO unicode_data (codepoint, script, category, name) VALUES (?, ?, ?, ?)", [codepoint, script, category, name])
        end
    end
end

#-- THE END -------------------------------------------------------------------
