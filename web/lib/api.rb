
class API

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
        if params.empty?
            return complete_path
        else
            return complete_path + '?' + params.join('&')
        end
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
        '<pre>' + JSON.pretty_generate(result).gsub(/"(STRING|INT|FLOAT|BOOL|ARRAY_OF_STRINGS)"/, '\1') + '</pre>'
    end

end

class APIParameters

    attr_reader :page, :results_per_page, :sortorder
    attr_accessor :sortname

    def initialize(p)
        if p[:rp].nil? || p[:rp] == '0' || p[:rp] == '' || p[:page].nil? || p[:page] == '0' || p[:page] == ''
            @page = 0
            @results_per_page = 0
        else
            if p[:rp] !~ /^[0-9]{1,3}$/
                raise ArgumentError, 'results per page must be integer between 0 and 999'
            end
            if p[:page] !~ /^[0-9]{1,4}$/
                raise ArgumentError, 'page must be integer between 0 and 9999'
            end
            @page = p[:page].to_i
            @results_per_page = p[:rp].to_i
        end

        if p[:sortname].nil? || p[:sortname] == ''
            @sortname = nil
        else
            @sortname = p[:sortname].gsub(/[^a-z_]/, '_')
        end

        if p[:sortorder] == 'desc' || p[:sortorder] == 'DESC'
            @sortorder = 'DESC'
        else
            @sortorder = 'ASC'
        end
    end

    def do_paging?
        @results_per_page != 0
    end

    def first_result
        @results_per_page * (@page - 1)
    end

end

