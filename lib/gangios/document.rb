require "rexml/document"

module Gangios
  module Document
    def self.included(base)
      base.extend(ClassMethods)
      base.attribute_clean_names
    end

    module ClassMethods
      # Redefine the method. Will undef the method if it exists or simply
      # just define it.
      def re_define_method(name, &block)
        undef_method(name) if method_defined?(name)
        define_method(name, &block)
      end

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

      # Define attributes reading data from xml
      # use @data(REXML::Element)
      # the attribute return a string
      def field(name, options = {})
        type = options[:type].to_s.split('::').last
        @@attributes[self] << name
        case type
        when 'String'
          re_define_method name do
            @data.attribute(name.to_s.upcase).to_s
          end
        when 'Integer'
          re_define_method name do
            @data.attribute(name.to_s.upcase).to_s.to_i
          end
        when 'Float'
          re_define_method name do
            @data.attribute(name.to_s.upcase).to_s.to_f
          end
        when 'Metric'
          re_define_method name do
            type = @data.attribute('TYPE').to_s
            ret = @data.attribute(name.to_s.upcase).to_s

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
            element = @data.elements["EXTRA_DATA/EXTRA_ELEMENT[@NAME='#{name.to_s.upcase}']"]
            element.attribute('VAL').to_s if element
          end
        else
          raise ArgumentError, "unknown type - #{type}"
        end
      end

      # define a function to get enumerator
      def has_many(name, options = {})
        # get klass:Class from classname:String
        classname = name.to_s.capitalize
        if options[:summary] then
          klass = classname.to_class(Gangios::Base::Summary)
        else
          klass = classname.to_class(Gangios::Base)
        end

        if options[:tag] then
          re_define_method name do
            klass.new @data.elements[options[:tag]]
          end
        else
          re_define_method name do
            klass.new @data
          end
        end
      end

      # define a default initialize function
      def define_init(hash = false)
        if hash then
          re_define_method :initialize do |data|
            data = data[:data]
            raise TypeError, "#{data} not kind of REXML::Element" unless data.kind_of? REXML::Element
            @data = data
          end
        else
          re_define_method :initialize do |data|
            raise TypeError, "#{data} not kind of REXML::Element" unless data.kind_of? REXML::Element
            @data = data
          end
        end
      end
    end
  end
end
