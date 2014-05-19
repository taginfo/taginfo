# web/lib/config.rb

class TaginfoConfig

    @@config = {}

    def self.read
        open(File.expand_path(File.dirname(__FILE__)) + '/../../../taginfo-config.json') do |file|
            @@config = JSON.parse(file.gets(nil), { :create_additions => false })
        end
    end

    def self.get(key, default=nil)
        tree = @@config
        key.split('.').each do |i|
            tree = tree[i]
            return default unless tree
        end
        return tree.nil? ? default : tree
    end

    # Config without anything that a security concious admin wouldn't want to
    # be public. Currently everything that contains local paths is removed.
    def self.sanitized_config
        c = @@config
        c['sources'] && c['sources'].delete('db')
        c['logging'] && c['logging'].delete('directory')
        c['tagstats'] && c['tagstats'].delete('cxxflags')
        return c
    end

end

