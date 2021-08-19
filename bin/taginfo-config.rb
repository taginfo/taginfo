#!/usr/bin/env ruby
#
#  taginfo-config.rb KEY [DEFAULT]
#

require 'json'

require File.expand_path(File.dirname(__FILE__)) + '/../web/lib/config.rb'

TaginfoConfig.read

value = TaginfoConfig.get(ARGV[0], ARGV[1])
if value.nil?
    puts ''
    exit 1
end

puts value

