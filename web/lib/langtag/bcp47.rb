# web/lib/langtag/bcp47.rb

# This module contains code related to the IETF BCP47 "Tags for Identifying
# Languages" and the IANA language subtag registry.
module BCP47
    SUBTAG_TYPES = %w[ language script region variant ].freeze

    def self.get_filter(param)
        if param && SUBTAG_TYPES.include?(param)
            param
        else
            ''
        end
    end

    class Nametag

        TAG_PATTERN       = %r{^([A-Za-z0-9]+:)?([a-z]+_)?name(:[A-Za-z0-9-]+)?$}.freeze
        LANG_PATTERN      = %r{^[a-z]{2,3}$}.freeze
        LANG_PATTERN_CI   = %r{^[A-Za-z]{2,3}$}.freeze
        SCRIPT_PATTERN    = %r{^[A-Z][a-z]{3}$}.freeze
        SCRIPT_PATTERN_CI = %r{^[A-Za-z]{4}$}.freeze
        REGION_PATTERN    = %r{^[A-Z]{2}$}.freeze
        REGION_PATTERN_CI = %r{^[A-Za-z]{2}$}.freeze

        attr_reader :prefix, :type, :langtag, :langtag_state, :lang, :lang_state, :lang_note, :script, :script_state, :script_note, :region, :region_state, :region_note, :notes

        def get_by_code(stype, subtag)
            @db.select("SELECT * FROM languages.subtags WHERE stype=? AND subtag=?", stype, subtag).execute do |row|
                return row
            end
            nil
        end

        def initialize(db, key)
            @db = db
            @lang = ''
            @lang_state = ''
            @lang_note = ''
            @script = ''
            @script_state = ''
            @script_note = ''
            @region = ''
            @region_state = ''
            @region_note = ''

            if !key.match(TAG_PATTERN)
                return
            end

            @prefix  = ::Regexp.last_match(1) ? ::Regexp.last_match(1).chop : ''
            @type    = ::Regexp.last_match(2) ? ::Regexp.last_match(2).chop : ''
            @langtag = ::Regexp.last_match(3) ? ::Regexp.last_match(3)[1, 1000] : ''
            if @langtag == ''
                return
            end

            subtags = @langtag.split('-')

            @lang = subtags.shift
            if @lang.match(LANG_PATTERN)
                lang_entry = get_by_code('language', @lang)
                if lang_entry
                    @lang_state = 'good'
                    @lang_note = lang_entry['description']
                    @default_script = lang_entry['suppress_script']
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
                    script_entry = get_by_code('script', @script)
                    if script_entry
                        @script_state = 'good'
                        @script_note = script_entry['description']
                        @default_script = script_entry['suppress_script']
                    else
                        @script_state = 'okay'
                        @script_note = '(Script subtag not in registry)'
                    end
                else
                    @script_state = 'bad'
                    @script_note = '(Script subtags should be titlecase)'
                end
            end

            return if subtags.empty?
            return unless subtags[0].match(REGION_PATTERN)

            @region = subtags.shift
        end

    end
end
