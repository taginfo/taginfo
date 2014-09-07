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

projects = db.execute("SELECT id, fetch_json FROM projects WHERE status='OK' ORDER BY id")

projects.each do |id, json|
    puts "  #{id}..."
    begin
        data = JSON.parse(json, { :symbolize_names => true, :create_additions => false })
        db.transaction do |db|
            db.execute("UPDATE projects SET data_format=?, data_url=? WHERE id=?", data[:data_format], data[:data_url], id)

            if data[:data_updated]
                db.execute("UPDATE projects SET data_updated=? WHERE id=?", data[:data_updated], id)
            end

            if data[:project]
                p = data[:project]
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
            end

            if data[:tags]
                data[:tags].each do |d|
                    on = { 'node' => 0, 'way' => 0, 'relation' => 0, 'area' => 0 }
                    if d[:object_types] && d[:object_types].class == Array
                        d[:object_types].each do |type|
                            on[type] = 1
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
    rescue JSON::ParserError
        db.execute("UPDATE projects SET status='PARSE_ERROR' WHERE id=?", id)
    end
end


#-- THE END -------------------------------------------------------------------
