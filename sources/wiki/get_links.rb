#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  get_links.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Get a list of pages linking to all Key/Tag/Relation pages from the OSM
#  wiki. This list will include links from other language versions of the
#  same Key/Tag/Relation, links from other Key/Tag/Relation pages and links
#  from all other wiki pages.
#
#  Output is on STDOUT with the title of the page the link is from a TAB
#  character and the title of the page the link is to. The underscore (_) is
#  used where there are spaces in a title.
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2015-2023  Jochen Topf <jochen@topf.org>
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

require 'net/http'
require 'uri'
require 'json'

require 'mediawikiapi'

#------------------------------------------------------------------------------

def what_links_to(api, title)
    blcontinue = nil
    loop do
        options = { :action => 'query', :list => 'backlinks', :bltitle => title, :bllimit => 500 }
        if blcontinue
            options[:blcontinue] = blcontinue
        end
        data = api.query(options)
        data['query']['backlinks'].each do |bl|
            bl['title'].gsub!(/\s/, '_')
            puts "#{bl['title']}\t#{title}"
        end

        return unless data['query-continue']

        blcontinue = data['query-continue']['backlinks']['blcontinue'].gsub(/\s/, '_')
    end
end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'

api = MediaWikiAPI::API.new

File.open(dir + '/interesting_wiki_pages.list') do |tagpages|
    tagpages.each do |line|
        line.chomp!
        (_type, _timestamp, _namespace, title) = line.split("\t")
        what_links_to(api, title)
    end
end

#-- THE END -------------------------------------------------------------------
