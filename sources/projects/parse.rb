#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  parse.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2014-2023  Jochen Topf <jochen@topf.org>
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

require 'json'
require 'sqlite3'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
database = SQLite3::Database.new(dir + '/taginfo-projects.db')

#------------------------------------------------------------------------------

# Simple logging class
class Log

    def initialize
        @messages = []
        @state = 0
    end

    def fatal(message)
        @messages << "FATAL: #{message}"
        @state = 3 if @state < 3
    end

    def error(message)
        @messages << "ERROR: #{message}"
        @state = 2 if @state < 2
    end

    def warning(message)
        @messages << "WARNING: #{message}"
        @state = 1 if @state < 1
    end

    def get_log
        @messages.join("\n")
    end

    def get_state
        return 'OK' if @state < 3

        'PARSE_ERROR'
    end

end

#------------------------------------------------------------------------------

def parse_and_check(id, data, log, db)
    unless data.is_a?(Hash)
        log.fatal "JSON TOP-LEVEL IS NOT AN OBJECT."
        return
    end

    unless data[:data_format].is_a?(Integer) && data[:data_format] == 1
        log.fatal "UNKNOWN OR MISSING data_format (KNOWN FORMATS: 1)."
        return
    end

    db.execute("UPDATE projects SET data_format=?, data_url=? WHERE id=?", [data[:data_format], data[:data_url], id])

    if data[:data_updated]
        if data[:data_updated].is_a?(String) && data[:data_updated].match(/^[0-9]{8}T[0-9]{6}Z$/)
            db.execute("UPDATE projects SET data_updated=? WHERE id=?", [data[:data_updated], id])
        else
            log.error "project.data_updated MUST USE FORMAT 'yyyymmddThhmmssZ'. CURRENT VALUE '#{data[:data_updated]}' IGNORED."
        end
    end

    data.each_key do |property|
        unless property.match(/^(data_format|data_updated|data_url|project|tags)$/)
            log.warning "UNKNOWN PROPERTY: '#{property}'."
        end
    end

    unless data[:project]
        log.fatal "MISSING project."
        return
    end

    unless data[:project].is_a?(Hash)
        log.fatal "project MUST BE AN OBJECT."
        return
    end

    p = data[:project].clone

    unless p[:name].is_a?(String)
        log.fatal "MISSING project.name OR NOT A STRING."
    end

    unless p[:description].is_a?(String)
        log.fatal "MISSING project.description OR NOT A STRING."
    end

    unless p[:project_url].is_a?(String)
        log.fatal "MISSING project.project_url OR NOT A STRING."
    end

    unless p[:contact_name].is_a?(String)
        log.error "MISSING project.contact_name OR NOT A STRING."
    end

    unless p[:contact_email].is_a?(String)
        log.error "MISSING project.contact_email OR NOT A STRING."
    end

    if p[:doc_url] && !p[:doc_url].is_a?(String)
        log.error "OPTIONAL project.doc_url MUST BE STRING."
    end

    if p[:icon_url] && !p[:icon_url].is_a?(String)
        log.error "OPTIONAL project.icon_url MUST BE STRING."
    end

    db.execute("UPDATE projects SET name=?, description=?, project_url=?, doc_url=?, icon_url=?, contact_name=?, contact_email=? WHERE id=?",
               [
                   p[:name],
                   p[:description],
                   p[:project_url],
                   p[:doc_url],
                   p[:icon_url],
                   p[:contact_name],
                   p[:contact_email],
                   id
               ])

    p.delete(:name)
    p.delete(:description)
    p.delete(:project_url)
    p.delete(:doc_url)
    p.delete(:icon_url)
    p.delete(:contact_name)
    p.delete(:contact_email)
    p.delete(:keywords) # ignored for future extensions

    p.each_key do |property|
        log.warning "project HAS UNKNOWN PROPERTY: '#{property}'."
    end

    unless data[:tags]
        log.fatal "MISSING tags."
        return
    end

    unless data[:tags].is_a?(Array)
        log.fatal "tags MUST BE AN ARRAY."
        return
    end

    data[:tags].each_with_index do |d, n|
        if d[:key].nil?
            log.error "MISSING tags.#{n}.key.\n"
        elsif !d[:key].is_a?(String)
            log.error "tags.#{n}.key MUST BE A STRING.\n"
        else
            has_error = false
            on = { 'node' => 0, 'way' => 0, 'relation' => 0, 'area' => 0 }
            if d[:object_types]
                if d[:object_types].instance_of?(Array)
                    if d[:object_types] == []
                        log.warning "EMPTY tags.#{n}.object_types IS INTERPRETED AS 'ALL TYPES'. PLEASE REMOVE object_types OR ADD SOME TYPES."
                        on = { 'node' => 1, 'way' => 1, 'relation' => 1, 'area' => 1 }
                    else
                        d[:object_types].each do |type|
                            if type.match(/^(node|way|relation|area)$/)
                                on[type] = 1
                            else
                                log.error "UNKNOWN OBJECT TYPE FOR #{d[:key]}: '#{type}' (ALLOWED ARE: node, way, relation, area)."
                                has_error = true
                            end
                        end
                    end
                else
                    log.error "tags.#{n}.object_types (FOR KEY '#{d[:key]}') MUST BE AN ARRAY."
                    has_error = true
                end
            else
                on = { 'node' => 1, 'way' => 1, 'relation' => 1, 'area' => 1 }
            end

            if d[:value] && !d[:value].is_a?(String)
                log.error "OPTIONAL tag.X.value MUST BE STRING."
                has_error = true
            end

            if d[:description] && !d[:description].is_a?(String)
                log.error "OPTIONAL tag.X.description MUST BE STRING."
                has_error = true
            end

            if d[:doc_url] && !d[:doc_url].is_a?(String)
                log.error "OPTIONAL tag.X.doc_url MUST BE STRING."
                has_error = true
            end

            if d[:icon_url] && !d[:icon_url].is_a?(String)
                log.error "OPTIONAL tag.X.icon_url MUST BE STRING."
                has_error = true
            end

            if !has_error
                db.execute("INSERT INTO project_tags (project_id, key, value, description, doc_url, icon_url, on_node, on_way, on_relation, on_area) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                           [
                               id,
                               d[:key],
                               d[:value],
                               d[:description],
                               d[:doc_url],
                               d[:icon_url],
                               on['node'],
                               on['way'],
                               on['relation'],
                               on['area'],
                           ])
            end
        end
    end
end

#------------------------------------------------------------------------------

database.execute("SELECT id, fetch_json FROM projects WHERE status='OK' ORDER BY id").each do |id, json|
    puts "  #{id}..."
    begin
        data = JSON.parse(json, { :symbolize_names => true, :create_additions => false })

        database.transaction do |db|
            log = Log.new
            parse_and_check(id, data, log, db)
            db.execute("UPDATE projects SET error_log=?, status=? WHERE id=?", [log.get_log, log.get_state, id])
        end
    rescue JSON::ParserError
        database.execute("UPDATE projects SET status='JSON_ERROR' WHERE id=?", [id])
    end
end

#-- THE END -------------------------------------------------------------------
