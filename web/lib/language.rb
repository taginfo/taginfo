# web/lib/language.rb
class Language

    @@languages = {}

    attr_reader :code, :english_name, :native_name

    def initialize(options)
        @code         = options['code']
        @english_name = options['english_name']
        @native_name  = options['native_name']
        @@languages[@code] = self
    end

    def self.[](code)
        @@languages[code] || new('code' => code, 'english_name' => '(unknown)', 'native_name' => '(unknown)')
    end

    def self.each
        @@languages.keys.sort.each do |lang|
            yield @@languages[lang]
        end
    end

    def self.has?(code)
        @@languages.key?(code)
    end

end
