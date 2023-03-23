#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  get_page_list.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Gets the list of all wiki pages from the OSM wiki.
#
#  Two files will be written: 'all_wiki_pages.list' contains a list of all
#  pages in the wiki (currently not used), 'interesting_wiki_pages.list'
#  contains all wiki pages about keys, tags, or relations which will be read
#  in a later step.
#
#  Both files have the format:
#
#  <type> TAB <namespace> TAB <title>
#
#  The <type> is either 'page' or 'redirect', depending on whether this is a
#  proper wiki page or a redirect to another wiki page, respectively.
#
#  The <namespaces> gives the namespace this page is in. This is empty for the
#  main namespace.
#
#  <title> is the full title of the wiki page including leading namespaces etc.
#
#  The files will be created in DIR or in the current directory, if no directory
#  was given on the command line.
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

require 'net/http'
require 'uri'
require 'json'

require 'mediawikiapi'

#------------------------------------------------------------------------------

def get_namespaces(api)
    data = api.query(:meta => 'siteinfo', :siprop => 'namespaces')
    namespaces = {}
    data['query']['namespaces'].each_value do |ns|
        if ns['canonical'] =~ /^[A-Z]{2}$/
            namespaces[ns['canonical']] = ns['id']
        end
    end
    namespaces
end

def get_page_list(api, namespaceid, options)
    continue = ''
    gapcontinue = ''
    loop do
        data = api.query(:generator => 'allpages', :gaplimit => 'max', :gapcontinue => gapcontinue, :continue => continue, :gapnamespace => namespaceid, :gapfilterredir => options[:redirect] ? 'redirects' : 'nonredirects', :prop => 'info')
        data['query']['pages'].each do |_, v|
            yield v['touched'], v['title'].gsub(/\s/, '_')
        end
        return unless data['continue']

        continue = data['continue']['continue']
        gapcontinue = data['continue']['gapcontinue']
        # puts "apfrom=#{apfrom}"
    end
end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'

api = MediaWikiAPI::API.new

namespaces = get_namespaces(api)

# add main namespace
namespaces[''] = 0

allpages = File.open(dir + '/all_wiki_pages.list', 'w')
tagpages = File.open(dir + '/interesting_wiki_pages.list', 'w')

namespaces.keys.sort.each do |namespace|
    id = namespaces[namespace]
    puts "Reading namespace '#{ namespace }' with id '#{ id }'..."

    get_page_list(api, id, :redirect => false) do |timestamp, page|
        line = ['page', timestamp, namespace, page].join("\t")
        allpages.puts line
        if page =~ /^([^:]+:)?(Key|Tag|Relation):(.+)$/
            tagpages.puts line
        end
    end

    get_page_list(api, id, :redirect => true) do |timestamp, page|
        line = ['redirect', timestamp, namespace, page].join("\t")
        allpages.puts line
        if page =~ /^([^:]+:)?(Key|Tag|Relation):(.+)$/
            tagpages.puts line
        end
    end
end

tagpages.close
allpages.close

#-- THE END -------------------------------------------------------------------
