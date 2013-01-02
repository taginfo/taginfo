# web/lib/langtag/bcp47.rb

# This module contains code related to the IETF BCP47 "Tags for Identifying
# Languages" and the IANA language subtag registry.
module BCP47

    REGISTRY_FILE = "lib/langtag/language-subtag-registry"
    SUBTAG_TYPES = %w( language script region variant )

    def self.get_filter(p)
        if p && SUBTAG_TYPES.include?(p)
            p
        else
            ''
        end
    end

    class Entry

        @@entries = Array.new

        attr_accessor :type, :subtag, :added, :suppress_script

        def self.entries(type = nil)
            if type.nil? || type == ''
                @@entries
            else
                @@entries.select{ |entry| type == entry.type }
            end
        end

        def self.cleanup
            @@entries = @@entries.select do |entry|
                SUBTAG_TYPES.include?(entry.type)
            end
        end

        def description=(value)
            @descriptions.push(value)
        end

        def description
            @descriptions.join('. ')
        end

        def prefix=(value)
            @prefixes.push(value)
        end

        def prefix
            @prefixes.join(', ')
        end

        def notes
            n = ''
            if suppress_script
                n += "Default script: #{suppress_script}"
            end
            unless @prefixes.empty?
                n += "Prefixes: #{prefix}"
            end
            n
        end

        def initialize
            @@entries.push(self)
            @descriptions = []
            @prefixes = []
        end
 
    end

    def self.read_registry
        entry = nil
        last_key = nil
        open(REGISTRY_FILE) do |file|
            file.each do |line|
                line.chomp!
                if line == '%%'
                    entry = Entry.new
                elsif line =~ /^\s+(.*)/
                    if entry.respond_to?(last_key)
                        entry.send(last_key, $1)
                    end
                else
                    (key, value) = line.split(/: /)
                    key.downcase!
                    key.gsub!(/[^a-z]/, '_')
                    s = (key + '=').to_sym
                    last_key = s
                    if entry.respond_to?(s)
                        entry.send(s, value)
                    end
                end
            end
        end
        Entry.cleanup
    end

end

