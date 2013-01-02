#!/usr/bin/ruby

require 'lib/langtag/bcp47.rb'

BCP47::read_registry

puts "Languages:"

BCP47::Entry::entries('language').each do |entry|
    defscript = entry.suppress_script ? " (Script: #{entry.suppress_script})" : ''
    puts "  #{entry.subtag} - #{entry.description}#{defscript}"
end

puts "\nScripts:"

BCP47::Entry::entries('script').each do |entry|
    puts "  #{entry.subtag} - #{entry.description}"
end

puts "\nRegions:"

BCP47::Entry::entries('region').each do |entry|
    puts "  #{entry.subtag} - #{entry.description}"
end

puts "\nVariants:"

BCP47::Entry::entries('variant').each do |entry|
    puts "  #{entry.subtag} - #{entry.description}"
end

