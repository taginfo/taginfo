#!/usr/bin/env ruby
#
#  taginfo-config.rb KEY [DEFAULT]
#

require 'json'

require __dir__ + '/../web/lib/config.rb'

taginfo_config = TaginfoConfig.new(__dir__ + '/../../taginfo-config.json')

value = taginfo_config.get(ARGV[0], ARGV[1])
if value.nil?
    puts ''
    exit 1
end

puts value
