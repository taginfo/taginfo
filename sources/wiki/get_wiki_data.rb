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

require 'pp'

require 'json'
require 'net/http'
require 'uri'
require 'sqlite3'

require './lib/mediawikiapi.rb'

#------------------------------------------------------------------------------

class WikiPage

    @@pages = {}

    attr_accessor :content
    attr_reader :type, :timestamp, :namespace, :title, :description, :image, :tag, :key, :value, :lang, :ttype, :tags_implies, :tags_combination, :tags_linked, :parsed, :has_templ, :group, :onNode, :onWay, :onArea, :onRelation

    def self.pages
        @@pages.values.sort{ |a,b| a.title <=> b.title }
    end

    def self.find(name)
        @@pages[name]
    end

    def initialize(type, timestamp, namespace, title)
        @type      = type       # 'page' or 'redirect'
        @timestamp = timestamp  # page last touched
        @namespace = namespace  # 'XX' (mediawiki namespace or '')
        @title     = title      # wiki page title

        @has_templ  = false
        @parsed = nil

        @tags_linked = []
        @group = ''

        @@pages[@title] = self
    end

    # Has this wiki page a name that we can understand and process?
    def check_title
        return :wrong_lang_format if @lang  !~ /^[a-z]{2}(-[a-z0-9-]+)?$/
        return :lang_en           if @title =~ /^en:/i
        return :value_for_key     if @ttype == 'key' && ! @value.nil?
        return :no_value_for_tag  if @ttype == 'tag' &&   @value.nil?
        return :slash_in_key      if @key   =~ %r{/}
        return :slash_in_value    if @value =~ %r{/}
        return :ok
    end

    # Return parameters for API call to read this page.
    def params
        { :title => title, :action => 'raw' }
    end

    def add_tag_link(tag)
        @tags_linked << tag
    end

    # Parse content of the wiki page. This will find the templates
    # and their parameters.
    def parse_content(db)
        @parsed = true
        text = @content.gsub(%r{<!--.*?-->}, '')

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
                    parse_template(c, db)
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
    rescue => ex
        puts "Parsing of page #{title} failed '#{ex.message}'"
        @parsed = false
    end

    def set_image(ititle, db)
        if !ititle.nil? && ititle.match(%r{^(file|image):(.*)$}i)
            @image = "File:#{$2}"
        else
            puts "invalid image: page='#{title}' image='#{ititle}'"
            db.execute('INSERT INTO invalid_image_titles (page_title, image_title) VALUES (?, ?)', title, ititle)
            @image = ''
        end
    end

    def parse_template(template, db)
        puts "Template: #{template.name} [#{template.parameters.join(',')}] #{template.named_parameters.inspect}"
        if template.name == 'Key' || template.name == 'Tag'
            tag = template.parameters[0]
            if template.parameters[1]
                tag += '=' + template.parameters[1]
            end
            add_tag_link(tag)
        end
        if template.name =~ /(Key|Value|Relation)Description$/
            @has_templ = true
            if template.named_parameters['description']
                desc = []
                template.named_parameters['description'].each do |i|
                    if i.class == Template
                        desc << ' ' << i.parameters.join('=') << ' '
                    else
                        desc << i
                    end
                    @description = desc.join('').strip
                end
            end
            if template.named_parameters['image']
                set_image(template.named_parameters['image'][0], db)
            end
            if template.named_parameters['group']
                @group = template.named_parameters['group'][0]
            end
            if template.named_parameters['onNode'] == ['yes']
                @onNode = true
            end
            if template.named_parameters['onWay'] == ['yes']
                @onWay = true
            end
            if template.named_parameters['onArea'] == ['yes']
                @onArea = true
            end
            if template.named_parameters['onRelation'] == ['yes']
                @onRelation = true
            end
            if template.named_parameters['implies']
                template.named_parameters['implies'].each do |i|
                    if i.class == Template
                        tags_implies << i.parameters.join('=')
                    end
                end
            end
            if template.named_parameters['combination']
                template.named_parameters['combination'].each do |i|
                    if i.class == Template
                        tags_combination << i.parameters.join('=')
                    end
                end
            end
        end
    end
end

class KeyOrTagPage < WikiPage

    def initialize(type, timestamp, namespace, title)
        super(type, timestamp, namespace, title)

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

        @tags_implies     = []
        @tags_combination = []
        @onNode     = false
        @onWay      = false
        @onArea     = false
        @onRelation = false
    end

    def insert(db)
        db.execute(
            "INSERT INTO wikipages (lang, tag, key, value, title, body, tgroup, type, has_templ, parsed, description, image, on_node, on_way, on_area, on_relation, tags_implies, tags_combination, tags_linked) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            lang,
            tag,
            key,
            value,
            title,
            content,
            group,
            type,
            has_templ  ? 1 : 0,
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

end

class KeyPage < KeyOrTagPage
end

class TagPage < KeyOrTagPage
end

class RelationPage < WikiPage

    attr_reader :rtype

    def initialize(type, timestamp, namespace, title)
        super(type, timestamp, namespace, title)

        @rtype = title.gsub(/^([^:]+:)?Relation:/, '') # relation type
        if title =~ /^(.*):Relation:/
            @lang  = $1.downcase # IETF language tag
        else
            @lang  = 'en'
        end
    end

    def set_image(ititle, db)
        @image = "File:#{ititle}"
    end

    def insert(db)
        db.execute(
            "INSERT INTO relation_pages (lang, rtype, title, body, tgroup, type, has_templ, parsed, description, image, tags_linked) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            lang,
            rtype,
            title,
            content,
            group,
            type,
            has_templ  ? 1 : 0,
            parsed     ? 1 : 0,
            description,
            image,
            tags_linked.sort.uniq.join(',')
        )
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

class Cache

    def initialize(dir, db, api)
        @db = db
        @api = api
        @db.execute("ATTACH DATABASE ? AS cache", dir + '/wikicache.db')
        @current_pagetitles = {}
    end

    def get_page(page)
        @current_pagetitles[page.title] = page.timestamp
        @db.execute("SELECT * FROM cache.cache_pages WHERE title=? AND timestamp=?", page.title, page.timestamp) do |row|
            page.content = row['body']
            puts "Page #{ page.title } in cache (#{ page.timestamp })"
            return
        end
        @db.execute("DELETE FROM cache.cache_pages WHERE title=?", page.title);
        res = @api.get(page.params)
        page.content = res.body
        @db.execute("INSERT INTO cache.cache_pages (title, timestamp, body) VALUES (?, ?, ?)", page.title, page.timestamp, page.content);
        puts "Page #{ page.title } not in cache (#{ page.timestamp })"
    end

    # Removes pages from cache that are not in the wiki any more
    def cleanup
        @db.execute("SELECT title FROM cache.cache_pages") do |row|
            @current_pagetitles.delete(row['title'])
        end

        to_delete = @current_pagetitles.keys
        puts "Deleting pages from cache: #{ to_delete.join(' ') }"
        to_delete.each do |title|
            @db.execute("DELETE FROM cache.cache_pages WHERE title=?", title);
        end
    end

end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'

api = MediaWikiAPI::API.new('wiki.openstreetmap.org', 80, '/w/index.php?')

db = SQLite3::Database.new(dir + '/taginfo-wiki.db')
db.results_as_hash = true

cache = Cache.new(dir, db, api)

db.execute('BEGIN TRANSACTION')

File.open(dir + '/tagpages.list') do |wikipages|
    wikipages.each do |line|
        line.chomp!
        (type, timestamp, namespace, title) = line.split("\t")

        if title =~ /(^|:)Key:/
            page = KeyPage.new(type, timestamp, namespace, title)
        elsif title =~ /(^|:)Tag:/
            page = TagPage.new(type, timestamp, namespace, title)
        elsif title =~ /(^|:)Relation:/
            page = RelationPage.new(type, timestamp, namespace, title)
        else
            puts "Wiki page has wrong format: '#{title}'"
            next
        end

        puts "Parsing page: title='#{page.title}' type='#{page.type}' timestamp='#{page.timestamp}' namespace='#{page.namespace}'"

        reason = page.check_title
        if reason == :ok
            cache.get_page(page)
            page.parse_content(db)
            page.insert(db)
        else
            puts "invalid page: #{reason} #{page.title}"
            db.execute('INSERT INTO invalid_page_titles (reason, title) VALUES (?, ?)', reason.to_s, page.title)
        end
    end
end

cache.cleanup

db.execute('COMMIT')


#-- THE END -------------------------------------------------------------------
