#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Merkaartor
#
#  import_merkaartor.rb
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

db = SQLite3::Database.new(dir + '/taginfo-merkaartor.db')

db.execute('BEGIN TRANSACTION');

template = 'default'
db.execute('INSERT INTO templates (name) VALUES (?)', template)

file = File.new(dir + '/git-source/Templates/' + template + '.mat')
doc = REXML::Document.new(file)

doc.elements.each('/templates/widgets/widget') do |widget|
    key = widget.attributes['tag']
    link = widget.elements['link'].attributes['src'] if widget.elements['link']
    selector = widget.elements['selector'].attributes['expr'] if widget.elements['selector']
    db.execute('INSERT INTO keys (template, key, tag_type, link, selector) VALUES (?, ?, ?, ?, ?)', template, key, widget.attributes['type'], link, selector)
    widget.elements.each('description') do |desc|
        db.execute('INSERT INTO key_descriptions (template, key, lang, description) VALUES (?, ?, ?, ?)', template, key, desc.attributes['locale'], desc.text)
    end
    widget.elements.each('value') do |valelement|
        value = valelement.attributes['tag']
        vlink = valelement.elements['link'].attributes['src'] if valelement.elements['link']
        db.execute('INSERT INTO tags (template, key, value, link) VALUES (?, ?, ?, ?)', template, key, value, vlink)
        widget.elements.each('description') do |desc|
            db.execute('INSERT INTO tag_descriptions (template, key, value, lang, description) VALUES (?, ?, ?, ?, ?)', template, key, value, desc.attributes['locale'], desc.text)
        end
    end
end


db.execute('COMMIT');


#-- THE END -------------------------------------------------------------------
