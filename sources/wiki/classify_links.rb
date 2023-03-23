#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  classify_links.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Read the links we got from get_links.rb, classify them, and add them to the
#  taginfo-wiki.db database.
#
#  Classification (link_class):
#
#   category - From a Category: page
#   how_to_map - From any "How to map" page
#   import - From any "Import" page
#   key_to_tag - From a Key to one of its Tags
#   ktr - From any Key/Tag/Relation page
#   map_features - From any "Map Features" page
#   proposed - From any "Proposed" page
#   rest - From anything else
#   same - From one language variant to another of the same Key/Tag/Relation
#   tag_to_key - From a Tag to its Key
#   template - From any "Template:" page
#   user - From any "User:" or "User talk:" page
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2017-2023  Jochen Topf <jochen@topf.org>
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

database = SQLite3::Database.new(dir + '/taginfo-wiki.db')
database.results_as_hash = true

# Regular expression matching Key/Tag/Relation pages in all languages
REGEXP_KTR = %r{'^(?:(.*):)?(Key|Tag|Relation):(.*)$'}.freeze

def classify_from(from)
    case from
    when /^Category:/
        'category'
    when /^(([A-Za-z]+):)?Template(_talk)?:/
        'template'
    when /Map_Features/i
        'map_features'
    when /Import/i
        'import'
    when /How_to_map_a$/
        'how_to_map'
    when /Proposed_features/i
        'proposed'
    when /^(([A-Za-z]+):)?User(_talk)?:/
        'user'
    else
        'rest'
    end
end

def classify_link(db, from, to)
    link_class = classify_from(from)

    fm = from.match(REGEXP_KTR)
    if fm
        from_lang = fm[1]
        from_type = fm[2]
        from_name = fm[3]
    end

    tm = to.match(REGEXP_KTR)
    if tm
        to_lang = tm[1]
        to_type = tm[2]
        to_name = tm[3]
    end

    if fm && tm
        link_class = if from_type == to_type && from_name == to_name
                         'same'
                     elsif from_type == 'Tag' && to_type == 'Key' && from_name.sub(/=.*/, '') == to_name
                         'tag_to_key'
                     elsif from_type == 'Key' && to_type == 'Tag' && to_name.sub(/=.*/, '') == from_name
                         'key_to_tag'
                     else
                         'ktr'
                     end
    end

    db.execute("INSERT INTO wiki_links (link_class, from_title, from_lang, from_type, from_name, to_title, to_lang, to_type, to_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
               [ link_class, from, from_lang, from_type, from_name, to, to_lang, to_type, to_name ])
    # puts "#{link_class}\t#{from}\t#{from_lang}\t#{from_type}\t#{from_name}\t#{to}\t#{to_lang}\t#{to_type}\t#{to_name}"
end

database.transaction do |db|
    File.open(dir + '/links.list') do |linkfile|
        linkfile.each do |line|
            line.chomp!
            (from, to) = line.split("\t")
            classify_link(db, from, to)
        end
    end
end

#-- THE END -------------------------------------------------------------------
