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
#  Copyright (C) 2023-2025  Jochen Topf <jochen@topf.org>
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

def process_key_entry(db, item, prop, desc)
    m = item.match(%r{^http://www.wikidata.org/entity/([PQ][0-9]+)$})
    if m
        code = m[1]
    else
        db.execute("INSERT INTO wikidata_errors (wikidata, item, code, propvalue, description, error) VALUES ('P13786', ?, ?, ?, ?, ?)", [item, code, prop, desc, "Item has invalid format"])
        return
    end

    db.execute("INSERT INTO wikidata_keys (code, key) VALUES (?, ?)", [code, prop])
end

def process_tag_entry(db, item, prop, desc)
    m = item.match(%r{^http://www.wikidata.org/entity/([PQ][0-9]+)$})
    if m
        code = m[1]
    else
        db.execute("INSERT INTO wikidata_errors (wikidata, item, code, propvalue, description, error) VALUES ('P1282', ?, ?, ?, ?, ?)", [item, code, prop, desc, "Item has invalid format"])
        return
    end

    m = prop.match(%r{^([^=]+)=([^=]+)$})
    if m
        key = m[1]
        value = m[2]
    else
        db.execute("INSERT INTO wikidata_errors (wikidata, item, code, propvalue, description, error) VALUES ('P1282', ?, ?, ?, ?, ?)", [item, code, prop, desc, "Item has invalid format"])
        return
    end

    db.execute("INSERT INTO wikidata_tags (code, key, value) VALUES (?, ?, ?)", [code, key, value])
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

data = get_json('SELECT ?item ?itemLabel ?prop WHERE { ?item wdt:P13786 ?prop . SERVICE wikibase:label { bd:serviceParam wikibase:language "en" } }')

data.each do |entry|
    item = entry['item']['value']
    prop = entry['prop']['value']
    desc = entry['itemLabel']['value']
    process_key_entry(db, item, prop, desc)
end

data = get_json('SELECT ?item ?itemLabel ?prop WHERE { ?item wdt:P1282 ?prop . SERVICE wikibase:label { bd:serviceParam wikibase:language "en" } }')

data.each do |entry|
    item = entry['item']['value']
    prop = entry['prop']['value']
    desc = entry['itemLabel']['value']
    process_tag_entry(db, item, prop, desc)
end

data = get_json('SELECT DISTINCT ?item ?label (lang(?label) as ?label_lang) WHERE { ?item wdt:P1282|wdt:P13786 ?prop; rdfs:label ?label }')

data.each do |entry|
    item = entry['item']['value']
    label = entry['label']['value']
    lang = entry['label_lang']['value']
    process_label_entry(db, item, label, lang)
end

#-- THE END -------------------------------------------------------------------
