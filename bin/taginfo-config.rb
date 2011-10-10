#!/usr/bin/ruby
#
#  taginfo-config.rb [KEY]
#

require 'rubygems'
require 'json'

require File.expand_path(File.dirname(__FILE__)) + '/../web/lib/config.rb'

TaginfoConfig.read

value = TaginfoConfig.get(ARGV[0])
if value.nil?
    puts ''
    exit 1
end

puts value

