#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Languages
#
#  import_unicode_scripts.rb
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

#------------------------------------------------------------------------------

property_value_alias_file = "#{dir}/PropertyValueAliases.txt"
codepoint_script_mapping_file = "#{dir}/Scripts.txt"

scripts = {}

database.transaction do |db|
    File.open(property_value_alias_file) do |file|
        file.each do |line|
            line.chomp!
            next unless line.match(%r{^sc ;})

            (_, script, name) = line.split(%r{\s*;\s*})
            scripts[name] = script
            db.execute("INSERT INTO unicode_scripts (script, name) VALUES (?, ?)", [script, name])
        end
    end

    File.open(codepoint_script_mapping_file) do |file|
        file.each do |line|
            line.chomp!
            next if line == '' || line[0] == '#'

            unless line.match(%r{^([0-9A-F.]+) +; +([^ ]+) # (..) })
                puts "Line does not match: #{line}"
                next
            end

            codes = Regexp.last_match(1)
            name = Regexp.last_match(2)
            gc = Regexp.last_match(3)

            case codes
            when %r{^[0-9A-F]{4,5}$}
                from = codes.to_i(16)
                to   = from
            when %r{^([0-9A-F]{4,5})..([0-9A-F]{4,5})$}
                from = Regexp.last_match(1).to_i(16)
                to   = Regexp.last_match(2).to_i(16)
            else
                puts "Line does not match: #{line}"
                next
            end

            db.execute("INSERT INTO unicode_codepoint_script_mapping (codepoint_from, codepoint_to, script, category) VALUES (?, ?, ?, ?)", [from, to, scripts[name], gc])
        end
    end
end

#-- THE END -------------------------------------------------------------------
