module GTFS
  module Model
    def self.included(base)
      base.extend ClassMethods

      base.class_variable_set('@@optional_attrs', [])
      base.class_variable_set('@@required_attrs', [])

      attr_accessor :feed

      def valid?
        !self.class.required_attrs.any?{|f| self.send(f.to_sym).nil?}
      end

      def initialize(attrs)
        attrs.each do |key, val|
          instance_variable_set("@#{key}", val)
        end
      end

      def id
      end

      def <=>(other)
        id <=> other.id
      end

      def name
      end

      def parents
        @parents ||= Set.new
      end

      def children
        @children ||= Set.new
      end

      def pclink(other)
        return if other.nil?
        self.children << other
        other.parents << self
      end
    end

    module ClassMethods

      #####################################
      # Getters for class variables
      #####################################

      def optional_attrs
        self.class_variable_get('@@optional_attrs')
      end

      def required_attrs
        self.class_variable_get('@@required_attrs')
      end

      def attrs
       required_attrs + optional_attrs
      end

      #####################################
      # Helper methods for setting up class variables
      #####################################

      def has_required_attrs(*attrs)
        self.class_variable_set('@@required_attrs', attrs)
      end

      def has_optional_attrs(*attrs)
        self.class_variable_set('@@optional_attrs', attrs)
      end

      def required_file(required)
        self.define_singleton_method(:required_file?) {required}
      end

      def collection_name(collection_name)
        self.define_singleton_method(:name) {collection_name}

        self.define_singleton_method(:singular_name) {
          self.to_s.split('::').last.
            gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            tr("-", "_").downcase
        }
      end

      def uses_filename(filename)
        self.define_singleton_method(:filename) {filename}
      end

      def each(filename, options={}, feed=nil)
        raise InvalidSourceException.new("File does not exist: #{filename}") unless File.exists?(filename)
        GTFS::Parse.parse_filename(filename, use_symbols: options[:use_symbols], skip_inequal_rows: options[:skip_inequal_rows]) do |row|
          model = self.new(row)
          model.feed = feed
          yield model if options[:strict] == false || model.valid?
        end
      end

      # Debugging only
      def parse_models(data, options={}, feed=nil)
        return [] if data.nil? || data.empty?
        models = []
        GTFS::Parse.parse_data(data, use_symbols: options[:use_symbols], skip_inequal_rows: options[:skip_inequal_rows]) do |row|
          model = self.new(row.to_hash)
          model.feed = feed
          models << model if options[:strict] == false || model.valid?
        end
        models
      end
    end
  end
end
