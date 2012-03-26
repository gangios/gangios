require "rexml/document"
require "gangios/utiles"

module Gangios
  module Document
    module Ganglia
      def self.included base
        base.extend(Methods)
      end

      module Methods
        include Define

        def add_ganglia_init request = nil, xpath = nil
          classname = self.to_s
          if classname.include? 'Summary' then
            request_suffix = '?filter=summary'
          else
            request_suffix = nil
          end

          type = classname.split('::').last.downcase.to_sym

          add_initialize_proc do |args = nil|
            next if @data.has_key? :gmetad

            # work for gmetad request and rexml xpath
            if request.nil? then
              case type
              when :grid
                request = "/#{request_suffix}"
                xpath = "/GRID"
              when :cluster
                request = "/#{args[:cluster]}#{request_suffix}"
                xpath = "/GRID"
                xpath += "[@NAME='#{args[:grid]}']" if args.has_key? :grid
                xpath += "/CLUSTER"
                xpath += "[@NAME='#{args[:cluster]}']" if args.has_key? :cluster
                xpath += "/HOST"
              when :host
                if args.has_key? :cluster then
                  request = "/#{args[:cluster]}/#{args[:host]}#{request_suffix}"
                else
                  request = "/#{request_suffix}"
                end
                xpath = "/GRID"
                xpath += "[@NAME='#{args[:grid]}']" if args.has_key? :grid
                xpath += "/CLUSTER"
              when :metric
                if request_suffix then
                  if args.has_key? :cluster then
                    request = "/#{args[:cluster]}#{request_suffix}"
                    xpath = "/GRID"
                    xpath += "[@NAME='#{args[:grid]}']" if args.has_key? :grid
                    xpath += "/CLUSTER[@NAME='#{args[:cluster]}']"
                    xpath += "/METRICS"
                  else
                    request = "/#{request_suffix}"
                    xpath = "/GRID"
                    xpath += "[@NAME='#{args[:grid]}']" if args.has_key? :grid
                    xpath += "/METRICS"
                  end
                else
                  if args.has_key? :host then
                    if args.has_key? :cluster then
                      request = "/#{args[:cluster]}/#{args[:host]}#{request_suffix}"
                    else
                      request = "/#{request_suffix}"
                    end
                    xpath = "/GRID"
                    xpath += "[@NAME='#{args[:grid]}']" if args.has_key? :grid
                    xpath += "/CLUSTER"
                    xpath += "[@NAME='#{args[:cluster]}']" if args.has_key? :cluster
                    xpath += "/METRIC"
                  else
                    raise "No hostname to get metric - #{name}"
                  end
                end
              else
                raise "Unknown type - #{type}"
              end
            end

            name = args[type]
            raise "Nil XPath" if xpath.nil?
            xpath += "[@NAME='#{name}']" if name

            @data[:gmetad] = GMetad.get_data request, xpath
            debug "Get GMetad Data #{@data[:gmetad].inspect}"
            raise "No such #{type} - #{name}" if @data[:gmetad].nil?
          end
        end

        # Define attributes reading data from xml
        # use @data[:gmetad](REXML::Element)
        # the attribute return a string
        def field(name, options = {})
          type = options[:type].to_s.split('::').last
          self.add_attribute_names name
          case type
          when 'String'
            safe_define_method name do
              @data[:gmetad].attribute(name.to_s.upcase).to_s
            end
          when 'Integer'
            safe_define_method name do
              @data[:gmetad].attribute(name.to_s.upcase).to_s.to_i
            end
          when 'Float'
            safe_define_method name do
              @data[:gmetad].attribute(name.to_s.upcase).to_s.to_f
            end
          when 'Metric'
            safe_define_method name do
              type = @data[:gmetad].attribute('TYPE').to_s
              ret = @data[:gmetad].attribute(name.to_s.upcase).to_s

              # ganglia check result has 5 types
              # double float uint16 uint32 string
              case type
              when 'double', 'float'
                return ret.to_f if ret.include? '.'
                ret.to_i
              when 'uint16', 'uint32'
                ret.to_i
              else
                ret
              end
            end
          when 'Extra'
            safe_define_method name do
              element = @data[:gmetad].elements["EXTRA_DATA/EXTRA_ELEMENT[@NAME='#{name.to_s.upcase}']"]
              element.attribute('VAL').to_s if element
            end
          when 'Custom'
            safe_define_method name do
              element = @data[:gmetad].elements[options[:xpath]] if options.has_key? :xpath
              attr_name = options[:attribute] || name.to_s.upcase
              element.attribute(attr_name).to_s if element
            end
          else
            raise ArgumentError, "unknown type - #{type}"
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
          if self.to_s.include? 'Summary' then
            klass = classname.to_class(Gangios::Base::Summary)
          else
            klass = classname.to_class(Gangios::Base)
          end

          enum_klass = options[:klass] || Base::Enumerator
          xpath = options[:xpath] || "//#{name.to_s.chop.upcase}"

          safe_define_method name do |options = {}|
            options[:xpath] = xpath
            enum_klass.new klass, @data, options
          end
        end

        # define all find etc. as class method
        # for Grid Cluster & Host
        def def_class_finders
          # get klass:Class from classname:String
          if classname.include? 'Summary' then
            request = '/?filter=summary'
          else
            request = '/'
          end

          re_define_class_method :all do |options = {}|
            if options.kind_of? String then
              return self.new options
            end

            # change id to name
            if options.has_key? :id then
              options[:name] = options.delete :id
            end

            klass.new GMetad.get_data(request, '/'), options
          end
        end
      end
    end
  end
end
