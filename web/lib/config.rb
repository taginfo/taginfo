# web/lib/config.rb

class TaginfoConfig

    @@config = {}

    def self.read
        open('../../taginfo-config.json') do |file|
            @@config = JSON.parse(file.gets(nil))
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

end

