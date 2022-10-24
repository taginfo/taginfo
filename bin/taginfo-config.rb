#!/usr/bin/env ruby
#
#  taginfo-config.rb KEY [DEFAULT]
#

require 'json'

require File.expand_path(File.dirname(__FILE__)) + '/../web/lib/config.rb'

taginfo_config = TaginfoConfig.new(File.expand_path(File.dirname(__FILE__)) + '/../../taginfo-config.json')

value = taginfo_config.get(ARGV[0], ARGV[1])
if value.nil?
    puts ''
    exit 1
end

puts value

