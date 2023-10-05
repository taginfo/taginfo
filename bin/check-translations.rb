#!/usr/bin/env ruby
#
#  check-translations.rb DIR LANG
#

require 'yaml'

dir  = ARGV[0]
lang = ARGV[1]

i18n_en   = YAML.load_file("#{dir}/en.yml")
i18n_lang = YAML.load_file("#{dir}/#{lang}.yml")

def look_for_error(path, data)
    if data.nil?
        puts "No data for #{path.sub(/^\./, '')}"
        return true
    elsif data.instance_of?(Hash)
        data.keys.sort.each do |key|
            if look_for_error(path + '.' + key, data[key])
                return true
            end
        end
    end
    false
end

def walk(path, lang_en, lang_other)
    lang_en.keys.sort.each do |key|
        name = path.sub(/^\./, '') + '.' + key
        if lang_en[key].instance_of?(Hash)
            if lang_other.nil?
                puts "MISSING: #{name} [en=#{ lang_en[key] }]"
            else
                walk(path + '.' + key, lang_en[key], lang_other[key])
                if lang_other[key] && lang_other[key].empty?
                    lang_other.delete(key)
                end
            end
        elsif lang_other.nil? || !lang_other[key]
            puts "MISSING: #{name} [en=#{ lang_en[key] }]"
        else
            lang_other.delete(key)
        end
    end
end

if look_for_error('', i18n_lang)
    exit 1
end

walk('', i18n_en, i18n_lang)

unless i18n_lang.empty?
    puts "keys in translation that are not in English version:"
    pp i18n_lang
end
