# web/lib/config.rb

class TaginfoConfig

    attr_reader :id

    def initialize(configfile, id = nil)
        open(configfile) do |file|
            @config = JSON.parse(file.gets(nil), { :create_additions => false })
        end
        @id = id
    end

    def prefix
        if @id
            return '/' + @id
        end

        ''
    end

    def get(key, default = nil)
        tree = @config
        key.split('.').each do |i|
            tree = tree[i]
            return default unless tree
        end
        tree.nil? ? default : tree
    end

    # Config without anything that a security concious admin wouldn't want to
    # be public. Currently everything that contains local paths is removed.
    def sanitized_config
        c = @config
        c['paths'] && c.delete('paths')
        c['sources']&.delete('db')
        c['sources']&.delete('chronology')
        c['logging']&.delete('directory')

        c
    end

end
