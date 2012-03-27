require "rexml/document"

module Gangios
  module Document
    module Ganglia
      def self.included base
        base.extend Methods
      end

      module MethodsBase
        include Define
        def plugin
          :gmetad
        end

        def add_ganglia_init request = nil, xpath = nil
          add_init_proc do |args = nil|
            next if @data.has_key? :gmetad

            # work for gmetad request and rexml xpath
            request = GMetad.get_request type, args unless request
            xpath = GMetad.get_xpath type, args unless xpath

            @data[:gmetad] = GMetad.get_data request, xpath
            debug "Get GMetad Data #{@data[:gmetad].inspect}"
            raise "No such #{type} - #{args}" if @data[:gmetad].nil?
          end
        end

        # Define attributes reading data from xml
        # use @data[:gmetad_summary](REXML::Element)
        # the attribute return a string
        def field(name, options = {})
          type = options[:type]
          database = options[:database] || plugin
          debug "Create Field #{name} as #{type} use database #{database}"
          unless [:String, :Integer, :Float, :Metric, :Extra, :Custom].include? type
            raise ArgumentError, "unknown type - #{type}"
          end
          if type == :Extra then
            type = :String
            options[:xpath] = "" unless options[:xpath]
            options[:xpath] += "EXTRA_DATA/EXTRA_ELEMENT[@NAME='#{name.to_s.upcase}']"
            options[:attribute] = "VAL"
          end

          self.add_attribute_names name

          safe_define_method name do
            element = @data[database]
            element = element.elements[options[:xpath]] if options.has_key? :xpath
            attr_name = options[:attribute] || name.to_s.upcase
            attribute = element.attribute(attr_name).to_s if element

            case type
            when :String
              return attribute
            when :Integer
              return attribute.to_i
            when :Float
              return attribute.to_f
            when :Metric
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
            when :Custom
              return attribute
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

          klass = options[:klass] || classname.to_class(Gangios::Base)
          xpath = options[:xpath] || "//#{name.to_s.chop.upcase}"
          enumerator = options[:enumerator] || Base::Enumerator

          safe_define_method name do |options = {}|
            options[:cluster] = name if self.class == Base::Cluster
            options[:xpath] = xpath
            enumerator.new klass, @data, options
          end
        end

        # define a function to get parent
        def belongs_to(name, options = {})
          # get klass:Class from classname:String
          classname = name.to_s.capitalize

          klass = options[:klass] || classname.to_class(Gangios::Base)
          xpath = options[:xpath] || ".."

          safe_define_method name do |options = {}|
            @data[database].elements[xpath]
            klass.new @data
          end
        end
      end

      module Methods
        include MethodsBase

        def add_ganglia_init request = nil, xpath = nil
          add_init_proc do |args = nil|
            next if @data.has_key? :gmetad

            # work for gmetad request and rexml xpath
            request = GMetad.get_request type, args unless request
            xpath = GMetad.get_xpath type, args unless xpath

            @data[:gmetad] = GMetad.get_data request, xpath
            debug "Get GMetad Data #{@data[:gmetad].inspect}"
            raise "No such #{type} - #{args}" if @data[:gmetad].nil?
          end
        end
      end
    end
  end
end
