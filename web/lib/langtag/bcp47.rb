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
        @@entry_by_subtag = Hash.new

        attr_accessor :type, :subtag, :added, :suppress_script, :scope

        def self.entries(type = nil)
            if type.nil? || type == ''
                @@entries
            else
                @@entries.select{ |entry| type == entry.type }
            end
        end

        def self.cleanup
            @@entries = @@entries.select do |entry|
                SUBTAG_TYPES.include?(entry.type) &&
                    entry.description != 'Private use' &&
                    (entry.type != 'language' || entry.scope != 'special') &&
                    (entry.type != 'script'   || !entry.subtag.match(%r{^Z}) ) &&
                    (entry.type != 'region'   || entry.subtag.match(%r{^[A-Z]{2}$}) )
            end
            SUBTAG_TYPES.each do |type|
                @@entry_by_subtag[type] = Hash.new
            end
            entries.each do |entry|
                @@entry_by_subtag[entry.type][entry.subtag] = entry
            end
        end

        def self.get_by_code(type, code)
            @@entry_by_subtag[type][code]
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

    class Nametag

        TAG_PATTERN       = %r{^([A-Za-z0-9]+:)?([a-z]+_)?name(:[A-Za-z0-9-]+)?$}
        LANG_PATTERN      = %r{^[a-z]{2,3}$}
        LANG_PATTERN_CI   = %r{^[A-Za-z]{2,3}$}
        SCRIPT_PATTERN    = %r{^[A-Z][a-z]{3}$}
        SCRIPT_PATTERN_CI = %r{^[A-Za-z]{4}$}
        REGION_PATTERN    = %r{^[A-Z]{2}$}
        REGION_PATTERN_CI = %r{^[A-Za-z]{2}$}

        attr_reader :prefix, :type, :langtag, :langtag_state, :lang, :lang_state, :lang_note, :script, :script_state, :script_note, :region, :region_state, :region_note, :notes

        def initialize(key)
            @lang = ''
            @lang_state = ''
            @lang_note = ''
            @script = ''
            @script_state = ''
            @script_note = ''
            @region = ''
            @region_state = ''
            @region_note = ''

            if key.match(TAG_PATTERN)
                @prefix  = $1 ? $1.chop : ''
                @type    = $2 ? $2.chop : ''
                @langtag = $3 ? $3[1,1000] : ''
                if @langtag != ''
                    subtags = @langtag.split('-')

                    @lang = subtags.shift
                    if @lang.match(LANG_PATTERN)
                        @lang_entry = Entry.get_by_code('language', @lang)
                        if @lang_entry
                            @lang_state = 'good'
                            @lang_note = @lang_entry.description
                            @default_script = @lang_entry.suppress_script
                        else
                            @lang_state = 'okay'
                            @lang_note = '(Language subtag not in registry)'
                        end
                    elsif @lang.match(LANG_PATTERN_CI)
                        @lang_state = 'bad'
                        @lang_note = '(Language subtags should be lowercase)'
                    else
                        @lang_state = 'bad'
                        @lang_note = '(Wrong format for language subtag)'
                    end

                    if !subtags.empty? && subtags[0].match(SCRIPT_PATTERN_CI)
                        @script = subtags.shift
                        if @script.match(SCRIPT_PATTERN)
                            @script_entry = Entry.get_by_code('script', @script)
                            if @script_entry
                                @script_state = 'good'
                                @script_note = @script_entry.description
                                @default_script = @script_entry.suppress_script
                            else
                                @script_state = 'okay'
                                @script_note = '(Script subtag not in registry)'
                            end
                        else
                            @script_state = 'bad'
                            @script_note = '(Script subtags should be titlecase)'
                        end
                    end

                    if !subtags.empty? && subtags[0].match(REGION_PATTERN)
                        @region = subtags.shift
                    end
                end
            end
        end

    end

end

