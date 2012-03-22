require "rexml/document"

module Gangios
  module Document
    def self.included(base)
      base.extend(Methods)
      base.attribute_clean_names
    end

    attr_reader :data

    module Methods
      include Define

      # Returns an array of names for the attributes available on this object
      # Rails v3.1+ uses this meathod to automatically wrap params in JSON requests
      @@attributes = {}
      def attribute_clean_names
        @@attributes[self] = []
      end

      def attribute_names
        @@attributes[self]
      end

      def has_attribute? attribute
        @@attributes[self].include? attribute  
      end

      class Name
        def initialize klass
          @klass = klass
        end

        def singular_route_key
          @klass.to_s.split('::').last.downcase
        end
      end

      def model_name
        Name.new self
      end

      # Define attributes reading data from xml
      # use @data[:ganglia](REXML::Element)
      # the attribute return a string
      def field(name, options = {})
        type = options[:type].to_s.split('::').last
        @@attributes[self] << name
        case type
        when 'String'
          re_define_method name do
            @data[:ganglia].attribute(name.to_s.upcase).to_s
          end
        when 'Integer'
          re_define_method name do
            @data[:ganglia].attribute(name.to_s.upcase).to_s.to_i
          end
        when 'Float'
          re_define_method name do
            @data[:ganglia].attribute(name.to_s.upcase).to_s.to_f
          end
        when 'Metric'
          re_define_method name do
            type = @data[:ganglia].attribute('TYPE').to_s
            ret = @data[:ganglia].attribute(name.to_s.upcase).to_s

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
          re_define_method name do
            element = @data[:ganglia].elements["EXTRA_DATA/EXTRA_ELEMENT[@NAME='#{name.to_s.upcase}']"]
            element.attribute('VAL').to_s if element
          end
        else
          raise ArgumentError, "unknown type - #{type}"
        end

        # alias name to id
        if name == :name then
          alias_method :id, :name
          alias_method :to_s, :id
          alias_method :inspect, :id
        end
      end

      # define a function to get enumerator
      def has_many(name, options = {})
        # get klass:Class from classname:String
        classname = name.to_s.capitalize
        if self.to_s.include? 'Summary' then
          klass = classname.to_class(Gangios::Base::Summary)
        else
          klass = classname.to_class(Gangios::Base)
        end

        if options[:tag] then
          re_define_method name do
            klass.new @data[:ganglia].elements[options[:tag]]
          end
        else
          re_define_method name do
            klass.new @data[:ganglia]
          end
        end
      end

      # define a default initialize function
      def define_init
        re_define_method :initialize do |data, options = {}|
          # save options for each method
          # lazy evaluation
          @options = options

          data = data[:data] if data.kind_of? Hash
          raise TypeError, "#{data} not kind of REXML::Element" unless data.kind_of? REXML::Element
          @data = {}
          @data[:ganglia] = data
        end
      end

      # define each [] all find etc.
      # for instance of Grids Clusters & Hosts
      def define_finders(tag = nil)
        # get klass:Class from classname:String
        classname = self.to_s.chop
        if self.to_s.include? 'Summary' then
          klass = classname.to_class(Gangios::Base::Summary)
        else
          klass = classname.to_class(Gangios::Base)
        end

        tag = "//#{classname.split('::').last.upcase}" unless tag
        re_define_method :each do |options = {}, &block|
          raise LocalJumpError, 'no block given (yield)' if block.nil?

          xpath = tag
          # make the options to xpath
          options = @options.merge(options)
          if options then
            attrs = []
            options.each do |key, value|
              attrs << "@#{key.upcase}#{"='#{value}'" if value}"
            end
            xpath += "[#{attrs.join(' and ')}]"
          end

          @data[:ganglia].elements.each xpath do |data|
            block.call klass.new :data => data
          end

          return self
        end

        re_define_method :[] do |name, &block|
          @data[:ganglia].elements["#{tag}[@NAME='#{name}']"]
        end

        re_define_method :all do |options = {}|
          if options.kind_of? String then
            return klass.new options
          end

          @options.merge!(options)
          return self
        end

        alias_method :find, :all
      end

      # define all find etc. as class method
      # for Grid Cluster & Host
      def define_class_finders
        # get klass:Class from classname:String
        classname = self.to_s + 's'
        if classname.include? 'Summary' then
          klass = classname.to_class(Gangios::Base::Summary)
          request = '/?filter=summary'
        else
          klass = classname.to_class(Gangios::Base)
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

        alias_class_method :find, :all
      end
    end
  end
end
