
class APIDoc

    @@paths = {}

    attr_accessor :version, :path, :parameters, :paging, :filter, :sort, :query, :result, :description, :example

    def self.paths
        @@paths
    end

    def initialize(version, path, doc)
        @version = version
        @path = path
        @doc = doc

        doc.each_pair do |k,v|
            instance_variable_set("@#{k}".to_sym, v)
        end

        @@paths[version] = {} unless @@paths[version]
        @@paths[version][path] = self
    end

    def complete_path
        '/api/' + version.to_s + '/' + path
    end

    def show_paging
        paging || 'no'
    end

    def show_filter
        return '<i>none</i>' unless filter
        list = []
        filter.keys.sort{ |a,b| a.to_s <=> b.to_s }.each do |f|
            list << "<tt>#{f}</tt> (#{filter[f][:doc]})"
        end
        list.join('<br/>')
    end

    def show_example
        return '' if example.nil?
        params = []
        example.each_pair do |k,v|
            params << "#{k}=#{v}"
        end
        complete_path + '?' + params.join('&')
    end

    def show_sort
        return '<i>none</i>' unless sort
        sort.map{ |s| "<tt>#{s}</tt>" }.join(', ')
    end

    def show_query
        return '<i>none</i>' unless query
        query
    end

    def show_result
        return '<i>unknown</i>' if result.nil?
        return result if result.is_a?(String)
        '<pre>' + JSON.pretty_generate(result).gsub(/"(STRING|INT|FLOAT|BOOL)"/, '\1') + '</pre>'
    end

end

