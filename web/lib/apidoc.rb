
class APIDoc

    @@paths = {}

    attr_accessor :version, :path, :parameters, :paging, :filter, :sort, :result, :description, :example, :ui

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

    def show_parameters
        return '<span class="empty">none</span>' unless parameters
        list = []
        parameters.keys.sort{ |a,b| a.to_s <=> b.to_s }.each do |p|
            list << "<tt>#{p}</tt> &mdash; #{parameters[p]}"
        end
        list.join('<br/>')
    end

    def show_filter
        return '<span class="empty">none</span>' unless filter
        list = []
        filter.keys.sort{ |a,b| a.to_s <=> b.to_s }.each do |f|
            list << "<tt>#{f}</tt> &mdash; #{filter[f][:doc]}"
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

    def show_ui
        return '' if example.nil?
        ui
    end

    def show_sort
        return '<span class="empty">none</span>' unless sort
        sort.map{ |s| "<tt>#{s}</tt>" }.join(', ')
    end

    def show_result
        return '<span class="empty">unknown</span>' if result.nil?
        return result if result.is_a?(String)
        '<pre>' + JSON.pretty_generate(result).gsub(/"(STRING|INT|FLOAT|BOOL)"/, '\1') + '</pre>'
    end

end

