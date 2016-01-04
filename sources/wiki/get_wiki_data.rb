#!/usr/bin/env ruby
# coding: utf-8
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

require 'json'
require 'net/http'
require 'uri'
require 'sqlite3'

require 'mediawikiapi.rb'

#------------------------------------------------------------------------------

# Descriptions of keys and tags should only contain plain text, not HTML,
# wiki templates, links or other wiki syntax.
PROBLEMATIC_DESCRIPTION = %r{[<>{}\[\]]}

# The format of a wikidata item.
WIKIDATA_FORMAT = %r{^Q[0-9]+}

# The format of a mediawiki page title.
PAGE_TITLE_FORMAT = %r{^([-_:.,= ()]|[[:alnum:]])+$}

# Format of image titles
IMAGE_TITLE_FORMAT = %r{^(file|image):(.*)$}i

# Language code format (something link 'en', or 'en_GB')
LANGUAGE_CODE = %r{^[a-z][a-z](_[a-z]+)?$}i

CONTAINS_SLASH = %r{/}

HTML_COMMENT = %r{<!--.*?-->}

# All the template names this script knows about
KNOWN_TEMPLATES = %r{^(?:template:)?(?:[a-z][a-z](?:-[a-z]+)?:)?(rtl|ar|relatedterm|relatedtermlist|wikipedia|key|tag|icon(node|way|area|relation)|wikiicon|(key|value|relation)description)$}i

class WikiPage

    @@pages = {}

    attr_accessor :content
    attr_reader :type, :timestamp, :namespace, :title, :description, :image,
                :tag, :key, :value, :lang, :ttype,
                :tags_implies, :tags_combination, :tags_linked,
                :parsed, :has_templ, :group,
                :onNode, :onWay, :onArea, :onRelation,
                :status, :statuslink, :wikidata

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
        return :wrong_lang_format     if @lang  !~ /^[a-z]{2}(-[a-z0-9-]+)?$/
        return :lang_is_en            if @title =~ /^en:/i
        return :value_in_key_page     if defined?(@ttype) && @ttype == 'key' && ! @value.nil?
        return :no_value_for_tag_page if defined?(@ttype) && @ttype == 'tag' &&   @value.nil?
        return :slash_in_key          if defined?(@key) && CONTAINS_SLASH.match(@key)
        return :slash_in_value        if defined?(@value) && CONTAINS_SLASH.match(@value)
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
        text = @content.gsub(HTML_COMMENT, '')

        # dummy template as base context
        context = [ Template.new('dummy') ]

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
                    context << Template.new
                when '}}' # end of template
                    context.last.add_parameter(m[1].strip)
                    c = context.pop
                    if context.size == 0
                        raise "Template {{}} not balanced"
                    end
                    parse_template(c, context.size, db)
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
        puts "FATAL: Parsing of page '#{title}' failed '#{ex.message}':"
        puts ex.backtrace.join("\n")
        @parsed = false
        db.execute("INSERT INTO problems (location, reason, title, lang, key, value) VALUES ('page content', 'parsing failed', ?, ?, ?, ?)", [title, lang, key, value])
    end

    def set_image(ititle, db)
        @image = ''
        if ititle.nil?
            puts "ERROR: invalid image: page='#{title}' image=nil"
            db.execute("INSERT INTO problems (location, reason, title, lang, key, value) VALUES ('Template:Key/Value/RelationDescription', 'image parameter empty', ?, ?, ?, ?)", [title, lang, key, value])
        elsif IMAGE_TITLE_FORMAT.match(ititle)
            @image = "File:#{$2}"
            if ! PAGE_TITLE_FORMAT.match(ititle)
                puts "WARN: possible invalid character in image title: page='#{title}' image='#{ititle}'"
            end
        else
            puts "ERROR: invalid image: page='#{title}' image='#{ititle}'"
            db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Key/Value/RelationDescription', 'invalid image parameter', ?, ?, ?, ?, ?)", [title, lang, key, value, ititle])
        end
    end

    def parse_type(param_name, param, db)
        if param.is_a?(Array)
            if param.size > 1
                puts "ERROR: multiple values for #{location} parameter: #{param}"
                db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Key/Value/RelationDescription', 'multiple values for ' || ? || ' parameter', ?, ?, ?, ?, ?)", [param_name, title, lang, key, value, param.join(', ')])
                return
            end
            param = param[0]
        end
        if param
            if param == 'yes'
                return true
            elsif param == 'no'
                return false
            else
                puts "ERROR: invalid value for parameter: param_name=#{param_name} title=#{title} lang=#{lang} key=#{key} value=#{value} param=#{param}"
                db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Key/Value/RelationDescription', 'invalid value for ' || ? || ' parameter', ?, ?, ?, ?, ?)", [param_name, title, lang, key, value, param])
            end
        end
        return false
    end

    def parse_template_key_tag(template, level, db)
        tag = template.parameters[0]
        if tag
            if template.parameters[1]
                tag += '=' + template.parameters[1]
            end
            add_tag_link(tag)
        end
    end

    def parse_template_related_term(template, level, db)
        if template.parameters.size > 1
            lang = template.parameters.shift
        else
            lang = 'en'
        end
        term = template.parameters.shift
        if template.parameters.size != 0
            puts "ERROR: More than two parameters on RelatedTerm template"
        end
        puts "#{ "  " * level }Related term: lang='#{lang}' term='#{term}'"
        if LANGUAGE_CODE.match(lang)
            if defined?(@key)
                db.execute("INSERT INTO tag_page_related_terms (key, value, lang, term) VALUES (?, ?, ?, ?)", [@key, @value, lang, term])
            elsif defined?(@rtype)
                db.execute("INSERT INTO relation_page_related_terms (rtype, lang, term) VALUES (?, ?, ?)", [@rtype, lang, term])
            end
        else
            puts "ERROR: Language in related term template looks wrong: '#{lang}'"
            db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:RelatedTerm', 'invalid lang parameter', ?, ?, ?, ?, ?)", [title, self.lang, key, value, lang])
        end
    end

    def parse_template_wikipedia(template, level, db)
        lang = template.parameters[0]
        title = template.parameters[1]
        puts "#{ "  " * level }Wikipedia link: lang='#{lang}' title='#{title}'"
        if LANGUAGE_CODE.match(lang)
            if defined?(@key)
                db.execute("INSERT INTO tag_page_wikipedia_links (key, value, lang, title) VALUES (?, ?, ?, ?)", [@key, @value, lang, title])
            elsif defined?(@rtype)
                db.execute("INSERT INTO relation_page_wikipedia_links (rtype, lang, title) VALUES (?, ?, ?)", [@rtype, lang, title])
            end
        else
            puts "ERROR: Language in wikipedia link template looks wrong: '#{lang}'"
            db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Wikipedia', 'invalid lang parameter', ?, ?, ?, ?, ?)", [self.title, self.lang, key, value, lang])
        end
    end

    def parse_template_description(template, level, db)
        @has_templ = true

        if template.parameters != []
            puts "ERROR: positional parameter on description template"
            db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Key/Value/RelationDescription', 'has positional parameter', ?, ?, ?, ?, ?)", [title, lang, key, value, template.parameters.join(',')])
        end

        if template.named_parameters['description']
            desc = []
            template.named_parameters['description'].each do |i|
                if i.class == Template
                    desc << ' ' << i.parameters.join('=') << ' '
                else
                    desc << i
                end
                @description = desc.join('').strip
                if PROBLEMATIC_DESCRIPTION.match(@description)
                    puts "ERROR: problematic description: #{ @description }"
                    db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Key/Value/RelationDescription', 'description parameter should only contain plain text', ?, ?, ?, ?, ?)", [title, lang, key, value, description])
                end
            end
        end
        if template.named_parameters['image']
            img = template.named_parameters['image'][0]
            if img.class != Template
                set_image(img, db)
            end
        end
        if template.named_parameters['group']
            group = template.named_parameters['group'][0]
            if group.class != Template
                @group = group
            end
        end

        @onNode     = parse_type('onNode',     template.named_parameters['onNode'],     db)
        @onWay      = parse_type('onWay',      template.named_parameters['onWay'],      db)
        @onArea     = parse_type('onArea',     template.named_parameters['onArea'],     db)
        @onRelation = parse_type('onRelation', template.named_parameters['onRelation'], db)

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
        if template.named_parameters['status']
            @status = template.named_parameters['status'].join('')
        end
        if template.named_parameters['statuslink']
            @statuslink = template.named_parameters['statuslink'][0]
        end
        if template.named_parameters['wikidata']
            wikidata = template.named_parameters['wikidata'][0]
            if WIKIDATA_FORMAT.match(wikidata)
                @wikidata = wikidata
            else
                db.execute("INSERT INTO problems (location, reason, title, lang, key, value, info) VALUES ('Template:Key/Value/RelationDescription', 'wikidata parameter does not match Q###', ?, ?, ?, ?, ?)", [title, lang, key, value, wikidata])
            end
        end
    end

    def parse_template(template, level, db)
        spaces = "  " * level
        puts "#{spaces}Template: #{template.name} [#{template.parameters.join(',')}]"
        template.named_parameters.each do |k, v|
            puts "#{spaces}  #{k}: #{v}"
        end
        if template.name == 'key' || template.name == 'tag'
            parse_template_key_tag(template, level, db)
        end
        if template.name == 'relatedterm'
            parse_template_related_term(template, level, db)
        end
        if template.name == 'wikipedia'
            parse_template_wikipedia(template, level, db)
        end
        if template.name =~ /(key|value|relation)description$/
            parse_template_description(template, level, db)
        end
    end
end

#------------------------------------------------------------------------------

class KeyOrTagPage < WikiPage

    def initialize(type, timestamp, namespace, title)
        super(type, timestamp, namespace, title)

        @tag       = title.gsub(/^([^:]+:)?(Key|Tag):/, '') # complete tag (key=value)
        @key       = @tag.sub(/=.*/, '')                    # key
        if @tag =~ /=/
            @value = @tag.sub(/.*?=/, '')                   # value (if any)
        else
            @value = nil
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
            "INSERT INTO wikipages (lang, tag, key, value, title, body, tgroup, type, has_templ, parsed, description, image, on_node, on_way, on_area, on_relation, tags_implies, tags_combination, tags_linked, status, statuslink, wikidata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [
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
            tags_linked.     sort.uniq.join(','),
            status,
            statuslink,
            wikidata
        ])
    end

end

#------------------------------------------------------------------------------

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
            "INSERT INTO relation_pages (lang, rtype, title, body, tgroup, type, has_templ, parsed, description, image, tags_linked) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [
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
        ])
    end

end

#------------------------------------------------------------------------------

class Template

    attr_reader :name, :parameters, :named_parameters

    def initialize(name=nil)
        @name             = name
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
                    if value.is_a?(String) && m = KNOWN_TEMPLATES.match(value)
                        @name = m[1].downcase
                    else
                        puts "WARN: Unknown template: #{ value }"
                        @name = value
                    end
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
        @in_cache = 0
        @not_in_cache = 0
    end

    def get_page(page)
        @current_pagetitles[page.title] = page.timestamp
        @db.execute("SELECT * FROM cache.cache_pages WHERE title=? AND timestamp=?", [page.title, page.timestamp]) do |row|
            page.content = row['body']
            puts "CACHE: Page '#{ page.title }' in cache (#{ page.timestamp })"
            @in_cache += 1
            return
        end
        @db.execute("DELETE FROM cache.cache_pages WHERE title=?", [page.title])
        res = @api.get(page.params)
        page.content = res.body
        @db.execute("INSERT INTO cache.cache_pages (title, timestamp, body) VALUES (?, ?, ?)", [page.title, page.timestamp, page.content])
        puts "CACHE: Page '#{ page.title }' not in cache (#{ page.timestamp })"
        @not_in_cache += 1
    end

    # Removes pages from cache that are not in the wiki any more
    def cleanup
        @db.execute("SELECT title FROM cache.cache_pages") do |row|
            @current_pagetitles.delete(row['title'])
        end

        to_delete = @current_pagetitles.keys
        puts "\n======================================================"
        puts "CACHE: Deleting pages from cache: #{ to_delete.join(' ') }"
        to_delete.each do |title|
            @db.execute("DELETE FROM cache.cache_pages WHERE title=?", [title])
        end
    end

    def print_stats
        puts "CACHE: Pages found in cache: #{@in_cache}"
        puts "CACHE: Pages not found in cache: #{@not_in_cache}"
    end

end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-wiki.db')
database.results_as_hash = true

#------------------------------------------------------------------------------

api = MediaWikiAPI::API.new('/w/index.php?')

cache = Cache.new(dir, database, api)

database.transaction do |db|

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
                puts "ERROR: Wiki page has wrong format: '#{title}'"
                next
            end

            puts "\n======================================================"
            puts "Parsing page: title='#{page.title}' type='#{page.type}' timestamp='#{page.timestamp}' namespace='#{page.namespace}'"

            reason = page.check_title
            if reason == :ok
                cache.get_page(page)
                page.parse_content(db)
                page.insert(db)
            else
                puts "ERROR: invalid page: #{reason} #{page.title}"
                db.execute("INSERT INTO problems (location, reason, title, lang, key, value) VALUES ('page title', ?, ?, ?, ?, ?)", [reason.to_s.gsub('_', ' '), page.title, page.lang, page.key, page.value])
            end
        end
    end

    cache.cleanup
    cache.print_stats

end


#-- THE END -------------------------------------------------------------------
