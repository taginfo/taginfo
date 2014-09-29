#!/usr/bin/ruby
#
#  check-translations.rb DIR LANG
#

v=RUBY_VERSION.split('.').map{ |x| x.to_i }
if (v[0]*100+v[1])*100+v[0] < 10901
    STDERR.puts "You need at least Ruby 1.9.1 to run taginfo"
    exit(1)
end

#------------------------------------------------------------------------------

require 'yaml'

dir  = ARGV[0]
lang = ARGV[1]

i18n_en   = YAML.load_file("#{dir}/en.yml")
i18n_lang = YAML.load_file("#{dir}/#{lang}.yml")

def look_for_error(path, data)
    if data.nil?
        puts "No data for #{path.sub(/^\./, '')}"
        return true
    elsif data.class == Hash
        data.keys.sort.each do |key|
            if look_for_error(path + '.' + key, data[key])
                return true
            end
        end
    end
    return false
end

def walk(path, en, other)
    en.keys.sort.each do |key|
        name = path.sub(/^\./, '') + '.' + key
        if en[key].class == Hash
            if other.nil?
                puts "MISSING: #{name} [en=#{en[key]}]"
            else
                walk(path + '.' + key, en[key], other[key])
            end
        else
#            puts "#{name} [#{en[key]}] [#{other[key]}]"
            if other.nil?|| ! other[key]
                puts "MISSING: #{name} [en=#{en[key]}]"
            end
        end
    end
end


if look_for_error('', i18n_lang)
    exit 1
end

walk('', i18n_en, i18n_lang)

