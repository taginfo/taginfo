#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  Taginfo source: Wikidata
#
#  import.rb
#
#  Get all wikidata items with property P1282 "OpenStreetMap tag or key" and
#  the value of that property.
#
#------------------------------------------------------------------------------
#
#  Copyright (C) 2023  Jochen Topf <jochen@topf.org>
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

require 'cgi'
require 'json'
require 'net/https'
require 'sqlite3'
require 'uri'

ENDPOINT = 'https://query.wikidata.org/sparql'.freeze

HEADERS = {
    'User-agent': 'taginfo/1.0 (https://wiki.osm.org/wiki/Taginfo)'
}.freeze

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-wikidata.db')

db.execute("PRAGMA journal_mode  = OFF")
db.execute("PRAGMA synchronous   = OFF")
db.execute("PRAGMA count_changes = OFF")
db.execute("PRAGMA temp_store    = MEMORY")
db.execute("PRAGMA cache_size    = 1000000")

#------------------------------------------------------------------------------

def get_uri(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.get(uri.request_uri, HEADERS)
end

def get_json(query)
    params = { query: query, format: 'json' }

    uri = URI.parse(ENDPOINT)
    uri.query = params.to_a.map{ |el| CGI.escape(el[0].to_s) + '=' + CGI.escape(el[1].to_s) }.join('&')

    response = get_uri(uri)
    response.body.force_encoding('UTF-8')

    json = JSON.parse(response.body)
    json['results']['bindings']
end

def process_item_entry(db, item, prop, desc)
    m = item.match(%r{^http://www.wikidata.org/entity/([PQ][0-9]+)$})
    if m
        code = m[1]
    else
        db.execute("INSERT INTO wikidata_p1282_errors (item, propvalue, description, error) VALUES (?, ?, ?, ?)", [item, prop, desc, "Item has invalid format"])
        return
    end

    m = prop.match(%r{^(Key|Tag|Relation|Role):(.*)$})
    if m
        ptype = m[1].downcase
        pcontent = m[2]
    else
        db.execute("INSERT INTO wikidata_p1282_errors (item, code, propvalue, description, error) VALUES (?, ?, ?, ?, ?)", [item, code, prop, desc, "Property value has invalid format (Must match /^(Key|Tag|Relation|Role):/)"])
        return
    end

    case ptype
    when "key"
        key = pcontent
    when "tag"
        (key, value) = pcontent.split('=')
    when "relation"
        rtype = pcontent
    when "role"
        rrole = pcontent
    end

    db.execute("INSERT INTO wikidata_p1282 (code, propvalue, ptype, key, value, relation_type, relation_role) VALUES (?, ?, ?, ?, ?, ?, ?)", [code, prop, ptype, key, value, rtype, rrole])
end

def process_label_entry(db, item, label, lang)
    m = item.match(%r{^http://www.wikidata.org/entity/([PQ][0-9]+)$})
    unless m
        print("Not a P or Q code: ", item)
        return
    end

    code = m[1]
    db.execute("INSERT INTO wikidata_labels (code, label, lang) VALUES (?, ?, ?)", [code, label, lang])
end

#------------------------------------------------------------------------------

data = get_json('SELECT ?item ?itemLabel ?prop WHERE { ?item wdt:P1282 ?prop . SERVICE wikibase:label { bd:serviceParam wikibase:language "en" } }')

data.each do |entry|
    item = entry['item']['value']
    prop = entry['prop']['value']
    desc = entry['itemLabel']['value']
    process_item_entry(db, item, prop, desc)
end

data = get_json('SELECT DISTINCT ?item ?label (lang(?label) as ?label_lang) WHERE { ?item wdt:P1282 ?prop; rdfs:label ?label }')

data.each do |entry|
    item = entry['item']['value']
    label = entry['label']['value']
    lang = entry['label_lang']['value']
    process_label_entry(db, item, label, lang)
end

#-- THE END -------------------------------------------------------------------
