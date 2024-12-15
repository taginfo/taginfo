# web/lib/api.rb

require 'csv'

class API

    @@paths = {}

    # Maps from complete path (something like /api/4/key/combinations) to the
    # API object implementing this path.
    @@complete_paths = {}

    attr_accessor :version, :path, :parameters, :paging, :filter, :sort, :result, :description, :notes, :example, :ui, :formats

    def self.paths
        @@paths
    end

    def self.complete_paths
        @@complete_paths
    end

    def initialize(version, path, doc)
        @version = version
        @path = path
        @doc = doc
        @formats = [:json]

        doc.each_pair do |k, v|
            instance_variable_set("@#{k}".to_sym, v)
        end

        @@paths[version] = {} unless @@paths[version]
        @@paths[version][path] = self

        @@complete_paths[complete_path] = self
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
        parameters.keys.sort{ |a, b| a.to_s <=> b.to_s }.each do |p|
            list << "<tt>#{p}</tt> &mdash; #{parameters[p]}"
        end
        list.join('<br/>')
    end

    def show_filter
        return '<span class="empty">none</span>' unless filter

        list = []
        filter.keys.sort{ |a, b| a.to_s <=> b.to_s }.each do |f|
            list << "<tt>#{f}</tt> &mdash; #{filter[f][:doc]}"
        end
        list.join('<br/>')
    end

    def show_example
        return '' if example.nil?

        params = []
        example.each_pair do |k, v|
            params << "#{k}=#{v}"
        end
        return complete_path if params.empty?

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

    def stack_results(level, stack, result)
        result.each do |r|
            stack.push({
                :level => level,
                :name => "#{r[0]}:",
                :type => r[1].to_s.gsub(/_/, ' '),
                :desc => r[2]
            })
            if r[3]
                stack_results(level + 1, stack, r[3])
            end
        end
    end

    def show_result
        return '<span class="empty">unknown</span>' if result.nil?

        return result if result.is_a?(String)

        # old way of documenting now only used for old API versions
        # this can be removed when all API calls <v4 are removed
        if result.is_a?(Hash)
            return '<pre>' + JSON.pretty_generate(result).gsub(/"(STRING|INT|FLOAT|BOOL|ARRAY_OF_STRINGS)"/, '\1') + '</pre>'
        end

        stack = []
        stack_results(0, stack, result)

        '<table class="apiresults">' +
            stack.map{ |s| "<tr><td>#{ '&nbsp;&nbsp;&nbsp;&nbsp;' * s[:level] }<tt>#{ s[:name] }</tt></td><td>#{ s[:type] }</td><td>#{ s[:desc] }</td></tr>" }.join("\n") +
            '</table>'
    end

    def deprecated?
        !@superseded_by.nil?
    end

    def superseded_by
        '/api/' + @superseded_by
    end

end

class APIParameters

    attr_reader :page, :results_per_page, :sortorder, :format
    attr_accessor :sortname

    def initialize(params)
        if params[:rp].nil? || params[:rp] == '0' || params[:rp] == '' || params[:page].nil? || params[:page] == '0' || params[:page] == ''
            @page = 0
            @results_per_page = 0
        else
            if params[:rp] !~ /^[0-9]{1,3}$/
                raise ArgumentError, 'results per page must be integer between 0 and 999'
            end
            if params[:page] !~ /^[0-9]{1,6}$/
                raise ArgumentError, 'page must be integer between 0 and 999999'
            end

            @page = params[:page].to_i
            @results_per_page = params[:rp].to_i
        end

        @sortname = if params[:sortname].nil? || params[:sortname] == ''
                        nil
                    else
                        params[:sortname].gsub(/[^a-z_]/, '_')
                    end

        @sortorder = if params[:sortorder] == 'desc' || params[:sortorder] == 'DESC'
                         'DESC'
                     else
                         'ASC'
                     end

        if p[:format] == 'csv'
            @format = :csv
        else
            @format = :json
        end
    end

    def do_paging?
        @results_per_page != 0
    end

    def first_result
        @results_per_page * (@page - 1)
    end

end

def generate_result(api, total, data)
    if @ap.format == :csv
        attachment @attachment
        return generate_csv_result(api, total, data)
    end
    return generate_json_result(total, data)
end

def generate_csv_result(api, total, data)
    columns = api.result.find{ |d| d[0] == :data and d[1] == :ARRAY_OF_HASHES }[3].map{ |d| d[0].to_s }
    return CSV.generate do |csv|
        csv << columns
        data.each do |d|
            csv << d.values
        end
    end
end

def generate_json_result(total, data)
    result = {
        :url        => request.url,
        :data_until => @data_until_m
    }

    if @ap.results_per_page > 0
        result.merge!({
            :page   => @ap.page,
            :rp     => @ap.results_per_page
        })
    end

    result.merge!({
        :total      => total,
        :data       => data
    })

    JSON.generate(result, json_opts(params[:format]))
end

def get_png(table, type, key, value = nil)
    content_type :png
    @db.select("SELECT png FROM db.#{ table }_distributions").
        condition("object_type=?", type).
        condition('key = ?', key).
        condition_if('value = ?', value).
        get_first_value ||
        @db.select('SELECT png FROM db.key_distributions').
            is_null('key').
            get_first_value
end
