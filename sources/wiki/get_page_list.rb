#!/usr/bin/env ruby
# coding: utf-8
#------------------------------------------------------------------------------
#
#  get_page_list.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Gets the list of all wiki pages from the OSM wiki.
#
#  Two files will be written: 'allpages.list' contains all pages in the wiki,
#  'tagpages.list' contains all pages about tags from the wiki. Both have the
#  format:
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
#  Copyright (C) 2013-2015  Jochen Topf <jochen@topf.org>
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
#  with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#------------------------------------------------------------------------------

require 'net/http'
require 'uri'
require 'json'

require 'mediawikiapi.rb'

#------------------------------------------------------------------------------

def get_namespaces(api)
    data = api.query(:meta => 'siteinfo', :siprop => 'namespaces')
    namespaces = {}
    data['query']['namespaces'].values.each do |ns|
        if ns['canonical'] =~ /^[A-Z]{2}$/
            namespaces[ns['canonical']] = ns['id']
        end
    end
    namespaces
end

def get_page_list(api, namespaceid, options)
    apfrom = ''
    loop do
        data = api.query(:generator => 'allpages', :gaplimit => 'max', :gapfrom => apfrom, :gapnamespace => namespaceid, :gapfilterredir => options[:redirect] ? 'redirects' : 'nonredirects', :prop => 'info')
        data['query']['pages'].each do |k,v|
            yield v['touched'], v['title'].gsub(/\s/, '_')
        end
        if data['query-continue']
            apfrom = data['query-continue']['allpages']['gapcontinue'].gsub(/\s/, '_')
#            puts "apfrom=#{apfrom}"
        else
            return
        end
    end
end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'

api = MediaWikiAPI::API.new('wiki.openstreetmap.org')

namespaces = get_namespaces(api)

# add main namespace
namespaces[''] = 0

allpages = File.open(dir + '/allpages.list', 'w')
tagpages = File.open(dir + '/tagpages.list', 'w')

namespaces.keys.sort.each do |namespace|
    id = namespaces[namespace]

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
