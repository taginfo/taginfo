#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Languages
#
#  import_wikipedias.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2020-2023  Jochen Topf <jochen@topf.org>
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

require 'cgi'
require 'sqlite3'

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-languages.db')

#------------------------------------------------------------------------------

wikimedias_file = "#{dir}/wikimedias.csv"

database.transaction do |db|
    File.open(wikimedias_file) do |file|
        file.each do |line|
            fields = line.split(',')
            next unless fields[2] == 'wikipedia'

            prefix = fields[1]
            language = CGI.unescapeHTML(fields[3])
            db.execute("INSERT INTO wikipedia_sites (prefix, language) VALUES (?, ?)", [prefix, language])
        end
    end
end

#-- THE END -------------------------------------------------------------------
