# web/lib/projects.rb
class Project

    @@projects = Array.new

    @@attrs = [:id, :json_url, :fetch_date, :fetch_status, :fetch_json, :fetch_result, :data_format, :data_updated, :data_url, :name, :project_url, :doc_url, :icon_url, :description, :contact_name, :contact_email]

    @@attrs.each do |attr|
        attr_reader attr
    end

    # Enumerate all available projects
    def self.each
        @@projects.each do |project|
            yield project
        end
    end

    # Enumerate all available projects
    def self.each_with_index
        @@projects.each_with_index do |project, n|
            yield project, n
        end
    end

    # The number of available sources
    def self.size
        @@projects.size
    end

    def self.init
        db = SQL::Database.new.attach_sources

        db.select("SELECT * FROM projects.projects").execute() do |row|
            @@projects << Project.new(row)
        end
        
        db.close
    end

    def self.get(id)
        @@projects.select{ |p| p.id == id }[0]
    end

    def initialize(row)
        @@attrs.each do |s|
            instance_variable_set("@#{s}", row[s.to_s])
        end
    end

end
