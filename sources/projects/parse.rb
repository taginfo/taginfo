#!/usr/bin/ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Projects
#
#  parse.rb
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2014  Jochen Topf <jochen@remote.org>
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
require 'sqlite3'

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-projects.db')

#------------------------------------------------------------------------------

class Log

    def initialize
        @messages = []
        @state = 0
    end

    def fatal(message)
        @messages << "FATAL: #{message}"
        if @state < 3
            @state = 3
        end
    end

    def error(message)
        @messages << "ERROR: #{message}"
        if @state < 2
            @state = 2
        end
    end

    def warning(message)
        @messages << "WARNING: #{message}"
        if @state < 1
            @state = 1
        end
    end

    def get_log
        return @messages.join("\n")
    end

    def get_state
        if @state < 3
            return 'OK'
        else
            return 'PARSE_ERROR'
        end
    end

end

#------------------------------------------------------------------------------

def parse_and_check(id, data, log, db)
    if data[:data_format] != 1
        log.fatal "UNKNOWN OR MISSING data_format (KNOWN FORMATS: 1)."
        return
    end

    db.execute("UPDATE projects SET data_format=?, data_url=? WHERE id=?", data[:data_format], data[:data_url], id)

    if data[:data_updated]
        if data[:data_updated].match(/^[0-9]{8}T[0-9]{6}Z$/)
            db.execute("UPDATE projects SET data_updated=? WHERE id=?", data[:data_updated], id)
        else
            log.error "project.data_updated MUST USE FORMAT 'yyyymmddThhmmssZ'. CURRENT VALUE IGNORED."
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

    p = data[:project].clone

    if ! p[:name]
        log.fatal "MISSING project.name."
    end

    if ! p[:description]
        log.fatal "MISSING project.description."
    end

    if ! p[:project_url]
        log.fatal "MISSING project.project_url."
    end

    if ! p[:contact_name]
        log.error "MISSING project.contact_name."
    end

    if ! p[:contact_email]
        log.error "MISSING project.contact_email."
    end

    db.execute("UPDATE projects SET name=?, description=?, project_url=?, doc_url=?, icon_url=?, contact_name=?, contact_email=? WHERE id=?",
        p[:name],
        p[:description],
        p[:project_url],
        p[:doc_url],
        p[:icon_url],
        p[:contact_name],
        p[:contact_email],
        id
    )

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

    data[:tags].each_with_index do |d, n|
        if d[:key].nil?
            log.error "MISSING tags.#{n}.key.\n"
        else
            on = { 'node' => 0, 'way' => 0, 'relation' => 0, 'area' => 0 }
            if d[:object_types]
                if d[:object_types].class == Array
                    if d[:object_types] == []
                        log.warning "EMPTY tags.#{n}.object_types IS INTERPRETED AS 'ALL TYPES'. PLEASE REMOVE object_types OR ADD SOME TYPES."
                        on = { 'node' => 1, 'way' => 1, 'relation' => 1, 'area' => 1 }
                    else
                        d[:object_types].each do |type|
                            if type.match(/^(node|way|relation|area)$/)
                                on[type] = 1
                            else
                                log.error "UNKNOWN OBJECT TYPE FOR #{d[:key]}: '#{type}' (ALLOWED ARE: node, way, relation, area)."
                            end
                        end
                    end
                else
                    log.error "tags.#{n}.object_types (FOR KEY '#{d[:key]}') MUST BE AN ARRAY."
                end
            else
                on = { 'node' => 1, 'way' => 1, 'relation' => 1, 'area' => 1 }
            end
            db.execute("INSERT INTO project_tags (project_id, key, value, description, doc_url, icon_url, on_node, on_way, on_relation, on_area) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
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
            );
        end
    end
end

#------------------------------------------------------------------------------

db.execute("SELECT id, fetch_json FROM projects WHERE status='OK' ORDER BY id").each do |id, json|
    puts "  #{id}..."
    begin
        data = JSON.parse(json, { :symbolize_names => true, :create_additions => false })

        db.transaction do |db|
            log = Log.new
            parse_and_check(id, data, log, db)
            db.execute("UPDATE projects SET error_log=?, status=? WHERE id=?", log.get_log(), log.get_state(), id)
        end
    rescue JSON::ParserError
        db.execute("UPDATE projects SET status='JSON_ERROR' WHERE id=?", id)
    end
end


#-- THE END -------------------------------------------------------------------
