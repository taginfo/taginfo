#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Potlatch
#
#  import_potlatch.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2010  Jochen Topf <jochen@remote.org>
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

require 'pp'
require 'sqlite3'
require 'rexml/document'

dir = ARGV[0] || '.'

db = SQLite3::Database.new(dir + '/taginfo-potlatch.db')

db.execute('BEGIN TRANSACTION');

file = File.new(dir + '/git-source/resources/map_features.xml')
doc = REXML::Document.new(file)

doc.elements.each('/mapFeatures/category') do |category_element|
    db.execute('INSERT INTO categories (id, name) VALUES (?, ?)', category_element.attributes['id'], category_element.attributes['name'])
end

doc.elements.each('/mapFeatures/feature') do |feature_element|
    feature_name = feature_element.attributes['name']

    on = { :point => 0, :line => 0, :area => 0, :relation => 0 }

    fields = Hash.new
    feature_element.elements.each do |element|
        case element.name
            when 'tag'
                value = element.attributes['v'] == '*' ? nil : element.attributes['v']
                db.execute('INSERT INTO tags (key, value, feature_name) VALUES (?, ?, ?)', element.attributes['k'], value, feature_name)
            when /^(point|line|area|relation)$/
                on[$1.to_sym] = 1
            when /^(category|help)$/
                fields[element.name] = element.text.strip
            when 'icon'
                fields['icon_image']      = element.attributes['image']
                fields['icon_background'] = element.attributes['background']
                fields['icon_foreground'] = element.attributes['foreground']
        end
    end

    if on[:point] + on[:line] + on[:area] + on[:relation] == 0
        on = { :point => 1, :line => 1, :area => 1, :relation => 1 }
    end

    db.execute('INSERT INTO features (name, category_id, help, on_point, on_line, on_area, on_relation, icon_image, icon_background, icon_foreground) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        feature_name, fields['category'], fields['help'], on[:point], on[:line], on[:area], on[:relation], fields['icon_image'], fields['icon_background'], fields['icon_foreground'])
end

db.execute('COMMIT');


#-- THE END -------------------------------------------------------------------
