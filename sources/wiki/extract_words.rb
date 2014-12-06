#!/usr/bin/env ruby
#------------------------------------------------------------------------------
#
#  extract_words.rb [DIR]
#
#------------------------------------------------------------------------------
#
#  Extracts words from wiki pages into their own table for full-text search.
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

require 'sqlite3'

#------------------------------------------------------------------------------

class Words

    def initialize
        @words = Hash.new
    end

    def add(key, value, lang, word)
        entry = [key, value]
        if @words[word]
            @words[word] << entry
        else
            @words[word] = [entry]
        end
    end

    # Remove words that appear too often
    def cleanup
        @words.delete_if do |k, v|
            v.size >= 10
        end
    end

    def invert
        @kvw = []
        @words.each do |word, entries|
            entries.each do |entry|
                key = entry[0]
                value = entry[1] || ''
                @kvw << [key, value, word]
            end
        end
    end

    def dump
        lastkey = ''
        lastvalue = ''
        words = []
        @kvw.sort.uniq.each do |key, value, word|
            if key != lastkey || value != lastvalue
                yield lastkey, lastvalue, words.join(',')
                words = []
                lastkey = key
                lastvalue = value
            else
                words << word
            end
        end
        yield lastkey, lastvalue, words.join(',')
    end

end

#------------------------------------------------------------------------------

class WordExtractor

    def initialize(words)
        @words = words
    end

    def interested_in(word, key, value, lang)
        # not interested in very short words
        return false if word.size <= 2

        # digits make for bad words
        return false if word =~ /\d/

#        # not interested if word == key or == value
#        key.downcase!
#        value.downcase! unless value.nil?
#        return false if word == key || word == value

        return true
    end

    def parse(key, value, lang, text)
        words = text.scan(/\w+/).sort.uniq
        words.each do |word|
            word.downcase!
            if interested_in(word, key, value, lang)
                @words.add(key, value, lang, word)
            end
        end
    end

end

#------------------------------------------------------------------------------

dir = ARGV[0] || '.'
db = SQLite3::Database.new(dir + '/taginfo-wiki.db')
db.results_as_hash = true

#------------------------------------------------------------------------------

words = Words.new
we = WordExtractor.new(words)

db.execute("SELECT * FROM wikipages") do |row|
#    puts "key=#{ row['key'] } value=#{ row['value'] } lang=#{ row['lang'] }"
    we.parse(row['key'], row['value'], row['lang'], row['body'])
end

words.cleanup
words.invert

#words.dump do |key, value, words|
#    puts "#{key}=#{value}: #{words}"
#end

db.transaction do |db|
    words.dump do |key, value, words|
        db.execute('INSERT INTO words (key, value, words) VALUES (?, ?, ?)', key, value, words)
    end
end


#-- THE END -------------------------------------------------------------------
