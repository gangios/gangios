require "rexml/document"

module Gangios
  module Document
    module Ganglia
      def self.included base
        base.extend Methods
      end

      module MethodsBase
        include Define
        def plugin_name
          :gmetad
        end

        def request_suffix
          ""
        end

        def add_ganglia_init request = nil, xpath = nil
          type = self.to_s.split('::').last.downcase.to_sym
          database = plugin_name
          suffix = request_suffix

          add_init_proc do |args|
            # if @data.has_key? database then
            #   raise "Unexpected data" unless @data[database].attribute('NAME') == args[type]
            #   next
            # end
            next if @data.has_key? database

            # work for gmetad request and rexml xpath
            request = GMetad.get_request(type, args) + suffix unless request
            xpath = GMetad.get_xpath type, args unless xpath

            @data[database] = GMetad.get_data request, xpath
            raise "No such #{type} - #{args}" if @data[database].nil?
          end
        end

        # Define attributes reading data from xml
        # use @data[:gmetad_summary](REXML::Element)
        # the attribute return a string
        def field(name, options = {})
          type = options[:type]
          database = options[:database] || plugin_name
          debug "Create Field #{name} as #{type} use database #{database}"
          unless %w(String Integer Float Metric Extra).include? type
            raise ArgumentError, "unknown type - #{type}"
          end
          if type == 'Extra' then
            type = 'String'
            options[:xpath] = "" unless options[:xpath]
            options[:xpath] += "EXTRA_DATA/EXTRA_ELEMENT[@NAME='#{name.to_s.upcase}']"
            options[:attribute] = "VAL"
          end

          self.add_attribute_names name
          xpath = options[:xpath]
          attr_name = options[:attribute] || name.to_s.upcase

          safe_define_method name do
            element = @data[database]
            element = element.elements[xpath] if xpath
            attribute = element.attribute(attr_name).to_s if element

            case type
            when 'String'
              return attribute
            when 'Integer'
              return attribute.to_i
            when 'Float'
              return attribute.to_f
            when 'Metric'
              mtype = element.attribute('TYPE').to_s if element

              # ganglia check result has 5 types
              # double float uint16 uint32 string
              case mtype
              when 'double', 'float'
                return attribute.to_f if attribute.include? '.'
                return attribute.to_i
              when 'uint16', 'uint32'
                return attribute.to_i
              else
                return attribute
              end
            end
          end

          # alias name to id
          if name == :name then
            alias_method :id, :name
            alias_method :to_s, :id
          end
        end

        # define a function to get enumerator
        def has_many(name, options = {})
          # get klass:Class from classname:String
          classname = name.to_s.chop.capitalize

          klass = options[:klass] || classname.to_class(Base)
          xpath = options[:xpath] || "#{name.to_s.chop.upcase}"
          sort = options[:sort] || plugin_name
          enumerator = options[:enumerator] || Base::Enumerator
          debug "Create Has_Many #{name} use enumerator #{enumerator} sort #{sort}"

          safe_define_method name do |options = {}|
            options[:xpath] = xpath
            enumerator.new klass, sort, @data, options
          end
        end

        # define a function to get parent
        def belongs_to(name, options = {})
          # get klass:Class from classname:String
          classname = name.to_s.capitalize

          klass = options[:klass] || classname.to_class(Base)
          xpath = options[:xpath] || ".."

          safe_define_method name do |options = {}|
            @data[database].elements[xpath]
            klass.new @data
          end
        end
      end

      module Methods
        include Ganglia::MethodsBase
        def plugin_name
          :gmetad
        end

        def request_suffix
          ""
        end
      end
    end

    module GangliaSummary
      def self.included base
        base.extend Methods
      end

      def get_data_by_summary(cluster)
        if cluster then
          request = "/#{cluster}"
          xpath = "/GRID/CLUSTER[@NAME='#{cluster}']"

          @data[:gmetad] = GMetad.get_data request, xpath
        else
          @data[:gmetad] = GMetad.get_data '/'
        end
      end
      
      module Methods
        include Ganglia::MethodsBase
        def plugin_name
          :gmetad_summary
        end

        def request_suffix
          "?filter=summary"
        end
      end
    end
  end
end
