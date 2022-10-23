#!/usr/bin/env ruby
#
#  get_distribution_image DB KEY nodes|ways
#

require 'sqlite3'

filename = ARGV[0]
key      = ARGV[1]
type     = ARGV[2]

db = SQLite3::Database.new(filename)

db.execute("SELECT #{type} FROM key_distributions WHERE key=?", key) do |row|
    $stdout.write row[0]
end
