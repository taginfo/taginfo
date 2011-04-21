#!/usr/bin/ruby
#
#  get_distribution_image DB KEY
#

require 'rubygems'
require 'sqlite3'

filename = ARGV[0]
key = ARGV[1]

db = SQLite3::Database.new(filename)

db.execute("SELECT png FROM key_distributions WHERE key=?", key) do |row|
    puts row[0]
end

