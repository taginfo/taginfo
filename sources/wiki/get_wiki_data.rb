#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  get_wiki_data.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Reads all the wiki pages from 'tagpages.list' and gets their content from
#  the OSM wiki. The pages are parsed and the information stored in the
#  sqlite database 'taginfo-wiki.db' which must have been initialized before.
#
#  All files are in DIR or the current directory if no directory was given on
#  the command line.
#
#  This script writes copious debugging information to STDOUT. You might want
#  to redirect that to a file.
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

require 'pp'

require 'json'
require 'net/http'
require 'uri'
require 'sqlite3'

require 'lib/mediawikiapi.rb'

#------------------------------------------------------------------------------

class WikiPage

    @@pages = {}

    attr_accessor :content
    attr_accessor :description, :image, :group, :onNode, :onWay, :onArea, :onRelation, :has_templ
    attr_reader :type, :namespace, :title, :tag, :key, :value, :lang, :ttype, :tags_implies, :tags_combination, :tags_linked, :parsed

    def initialize(type, namespace, title)
        @type      = type       # 'page' or 'redirect'
        @namespace = namespace  # 'XX' (mediawiki namespace or '')
        @title     = title      # wiki page title

        @tag       = title.gsub(/^([^:]+:)?(Key|Tag):/, '') # complete tag (key=value)
        @key       = @tag.sub(/=.*/, '')                    # key
        if @tag =~ /=/
            @value = @tag.sub(/.*?=/, '')                   # value (if any)
        end
        if title =~ /^(.*):(Key|Tag):/
            @lang  = $1.downcase                            # IETF language tag
            @ttype = $2.downcase                            # 'tag' or 'key'
        else
            @lang  = 'en'
        end

        @has_templ  = false

        @tags_implies     = []
        @tags_combination = []
        @tags_linked      = []

        @group      = ''
        @onNode     = false
        @onWay      = false
        @onArea     = false
        @onRelation = false

        @parsed = nil

        @@pages[@title] = self
    end

    def self.pages
        @@pages.values.sort{ |a,b| a.title <=> b.title }
    end

    def self.find(name)
        @@pages[name]
    end

    # Has this wiki page a name that we can understand and process?
    def valid?
        return false if @lang  !~ /^[a-z]{2}(-[a-z0-9-]+)?$/
        return false if @ttype == 'key' && ! @value.nil?
        return false if @ttype == 'tag' &&   @value.nil?
        return false if @key   =~ %r{/}
        return false if @value =~ %r{/}
        return true
    end

    # Return parameters for API call to read this page.
    def params
        { :title => title, :action => 'raw' }
    end

    def add_tag_link(tag)
        @tags_linked << tag
    end

    def insert(db)
        db.execute(
            "INSERT INTO wikipages (lang, tag, key, value, title, tgroup, type, has_templ, parsed, description, image, on_node, on_way, on_area, on_relation, tags_implies, tags_combination, tags_linked) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            lang,
            tag,
            key,
            value,
            title,
            group,
            type,
            has_templ,
            parsed     ? 1 : 0,
            description,
            image,
            onNode     ? 1 : 0,
            onWay      ? 1 : 0,
            onArea     ? 1 : 0,
            onRelation ? 1 : 0,
            tags_implies.    sort.uniq.join(','),
            tags_combination.sort.uniq.join(','),
            tags_linked.     sort.uniq.join(',')
        )
    end

    # Parse content of the wiki page. This will find the templates
    # and their parameters.
    def parse_content
        @parsed = true
        text = @content

        # dummy template as base context
        context = [ Template.new ]

        loop do
            # split text into ('before', 'token', 'after')
            m = /^(.*?)(\{\{|\}\}|[|=])(.*)$/m.match(text)

            # we are done if there are no more tokens
            if m.nil?
                return
            end

            # do the right thing depending on next token
            case m[2]
                when '{{' # start of template
                    context.last.add_parameter(m[1].strip)
                    context << Template.new()
                when '}}' # end of template
                    context.last.add_parameter(m[1].strip)
                    c = context.pop
                    yield c
                    context.last.add_parameter(c)
                when '|' # template parameter
                    context.last.add_parameter(m[1].strip)
                    context.last.parname(nil)
                when '=' # named template parameter
                    parameter_name = (m[1].strip == ':') ? 'subkey' : m[1].strip
                    context.last.parname(parameter_name)
            end

            # 'after' is our next 'text'
            text = m[3]
        end
    rescue
        puts "Parsing of page #{title} failed"
        @parsed = false
    end

end

#------------------------------------------------------------------------------

class Template

    attr_reader :name, :parameters, :named_parameters

    def initialize()
        @name             = nil
        @parname          = nil
        @parameters       = []
        @named_parameters = {}
    end

    def parname(name)
        @parname = name
    end

    def add_parameter(value)
        if value != ''
            if @parname.nil? # positional parameter
                # first parameter is really the name of this template
                if @name.nil?
                    @name = value
                else
                    @parameters << value
                end
            else # named parameter
                @named_parameters[@parname] ||= []
                @named_parameters[@parname] << value
            end
        end
    end

end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'

api = MediaWikiAPI::API.new('wiki.openstreetmap.org', 80, '/w/index.php?')
api.add_header('User-agent', 'taginfo/0.1 (jochen@remote.org)')

db = SQLite3::Database.new(dir + '/taginfo-wiki.db')

db.execute('BEGIN TRANSACTION');

File.open(dir + '/tagpages.list') do |wikipages|
    wikipages.each do |line|
        line.chomp!
        t = line.split("\t")
        page = WikiPage.new(t[0], t[1], t[2])
        puts "page: (#{page.title}) (#{page.type}) (#{page.namespace}) (#{page.tag})"

        if page.valid?
            res = api.get(page.params)
            page.content = res.body

            page.parse_content do |template|
                puts "Template: #{template.name} [#{template.parameters.join(',')}] #{template.named_parameters.inspect}"
                if template.name == 'Key' || template.name == 'Tag'
                    tag = template.parameters[0]
                    if template.parameters[1]
                        tag += '=' + template.parameters[1]
                    end
                    page.add_tag_link(tag)
                end
                if template.name =~ /(Key|Value)Description$/
                    page.has_templ = true
                end
                if template.named_parameters['description']
                    desc = []
                    template.named_parameters['description'].each do |i|
                        if i.class == Template
                            desc << ' ' << i.parameters.join('=') << ' '
                        else
                            desc << i
                        end
                        page.description = desc.join('').strip
                    end
                end
                if template.named_parameters['image']
                    page.image = template.named_parameters['image'][0]
                end
                if template.named_parameters['group']
                    page.group = template.named_parameters['group'][0]
                end
                if template.named_parameters['onNode'] == ['yes']
                    page.onNode = true
                end
                if template.named_parameters['onWay'] == ['yes']
                    page.onWay = true
                end
                if template.named_parameters['onArea'] == ['yes']
                    page.onArea = true
                end
                if template.named_parameters['onRelation'] == ['yes']
                    page.onRelation = true
                end
                if template.named_parameters['implies']
                    template.named_parameters['implies'].each do |i|
                        if i.class == Template
                            page.tags_implies << i.parameters.join('=')
                        end
                    end
                end
                if template.named_parameters['combination']
                    template.named_parameters['combination'].each do |i|
                        if i.class == Template
                            page.tags_combination << i.parameters.join('=')
                        end
                    end
                end
            end
            page.insert(db)
        else
            puts "invalid page: #{page.title}"
        end
    end
end

db.execute('COMMIT');


#-- THE END -------------------------------------------------------------------
