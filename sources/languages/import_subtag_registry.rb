#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Languages
#
#  import_subtag_registry.rb
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

# A subtag of type language, script, region, or variant from the language
# subtag registry.
class Subtag

    @@entries = []

    attr_accessor :type, :subtag, :added, :suppress_script, :scope

    def self.entries
        @@entries
    end

    def initialize
        @@entries.push(self)
        @descriptions = []
        @prefixes = []
    end

    def description=(value)
        @descriptions.push(value)
    end

    def description
        @descriptions.join('. ')
    end

    def prefix=(value)
        @prefixes.push(value)
    end

    def prefix
        @prefixes.join(',')
    end

end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-languages.db')

#------------------------------------------------------------------------------

registry_file = "#{dir}/language-subtag-registry"

# file_date = nil

begin
    subtag = nil
    last_key = nil
    File.open(registry_file) do |file|
        file.each do |line|
            line.chomp!
            if line == '%%'
                subtag = Subtag.new
            elsif subtag.nil? && line =~ /^File-Date: ([0-9]{4}-[0-9]{2}-[0-9]{2})$/
                # file_date = $1
            elsif line =~ /^\s+(.*)/
                if subtag.respond_to?(last_key)
                    subtag.send(last_key, Regexp.last_match(1))
                end
            else
                (key, value) = line.split(/: /)
                key.downcase!
                key.gsub!(/[^a-z]/, '_')
                s = (key + '=').to_sym
                last_key = s
                if subtag.respond_to?(s)
                    subtag.send(s, value)
                end
            end
        end
    end
end

SUBTAG_TYPES = %w[ language script region variant ].freeze

database.transaction do |db|
    Subtag.entries.each do |entry|
        next unless SUBTAG_TYPES.include?(entry.type)
        next if entry.description == 'Private use'
        next if entry.type == 'language' && (entry.scope == 'special' || entry.scope == 'collection')
        next if entry.type == 'script'   && entry.subtag.match(%r{^Z})
        next if entry.type == 'region'   && !entry.subtag.match(%r{^[A-Z]{2}$})

        db.execute("INSERT INTO subtags (stype, subtag, added, suppress_script, scope, description, prefix) VALUES (?, ?, ?, ?, ?, ?, ?)",
                   [
                       entry.type,
                       entry.subtag,
                       entry.added,
                       entry.suppress_script,
                       entry.scope,
                       entry.description,
                       entry.prefix
                   ])
    end
end

#-- THE END -------------------------------------------------------------------
