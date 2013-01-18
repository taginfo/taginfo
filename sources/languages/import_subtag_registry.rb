#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Languages
#
#  import_subtag_registry.rb
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

require 'rubygems'

require 'sqlite3'

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

dir = ARGV[0] || '.'

db = SQLite3::Database.new(dir + '/taginfo-languages.db')

registry_file = "#{dir}/language-subtag-registry"

file_date = nil

begin
    entry = nil
    last_key = nil
    open(registry_file) do |file|
        file.each do |line|
            line.chomp!
            if line == '%%'
                entry = Subtag.new
            elsif entry.nil? && line =~ /^File-Date: ([0-9]{4}-[0-9]{2}-[0-9]{2})$/
                file_date = $1
            elsif line =~ /^\s+(.*)/
                if entry.respond_to?(last_key)
                    entry.send(last_key, $1)
                end
            else
                (key, value) = line.split(/: /)
                key.downcase!
                key.gsub!(/[^a-z]/, '_')
                s = (key + '=').to_sym
                last_key = s
                if entry.respond_to?(s)
                    entry.send(s, value)
                end
            end
        end
    end
end

SUBTAG_TYPES = %w( language script region variant )

db.execute('BEGIN TRANSACTION');

Subtag.entries.each do |entry|
    if SUBTAG_TYPES.include?(entry.type) &&
        entry.description != 'Private use' &&
        (entry.type != 'language' || (entry.scope != 'special' && entry.scope != 'collection')) &&
        (entry.type != 'script'   || !entry.subtag.match(%r{^Z}) ) &&
        (entry.type != 'region'   || entry.subtag.match(%r{^[A-Z]{2}$}) )
        db.execute("INSERT INTO subtags (stype, subtag, added, suppress_script, scope, description, prefix) VALUES (?, ?, ?, ?, ?, ?, ?)",
            entry.type,
            entry.subtag,
            entry.added,
            entry.suppress_script,
            entry.scope,
            entry.description,
            entry.prefix
        )
    end
end

db.execute('COMMIT');


#-- THE END -------------------------------------------------------------------
