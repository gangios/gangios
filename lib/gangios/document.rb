require "rexml/document"

module Gangios
  module Document
    def self.included base
      base.extend(Methods)
      base.def_attribute_names
      base.def_initialize_procs
    end

    attr_accessor :data

    module Methods
      include Define

      def def_initialize_procs
        @@initialize_procs = {} unless defined? @@initialize_procs
        klass = self

        safe_define_method :call_initialize_procs do |args = nil|
          procs = @@initialize_procs[klass] || []
          debug "Initialize #{self.class} instance, exec #{procs}, data: #{@data}", true
          procs.each do |proc|
            self.instance_exec args, &proc
          end
        end

        safe_define_class_method :initialize_procs do |&block|
          @@initialize_procs[klass]
        end

        safe_define_class_method :add_initialize_proc do |&block|
          @@initialize_procs[klass] = [] if @@initialize_procs[klass].nil?
          @@initialize_procs[klass] << block
        end
      end

      def def_attribute_names
        @@attribute_names = {} unless defined? @@attribute_names
        klass = self

        safe_define_class_method :attribute_names do
          @@attribute_names[klass]
        end

        safe_define_class_method :add_attribute_names do |attribute|
          @@attribute_names[klass] = [] if @@attribute_names[klass].nil?
          @@attribute_names[klass] << attribute
        end
      end

      def def_grid_init
        re_define_method :initialize do |arg1 = nil|
          args = {}

          if arg1.kind_of? Hash then
            @data = arg1
          elsif arg1.nil? or arg1.kind_of? String then
            @data = {}
            args[:grid] = arg1
          else
            raise ArgumentError
          end

          call_initialize_procs args
        end
      end

      def def_cluster_init
        re_define_method :initialize do |arg1, arg2 = nil|
          args = {}

          if arg1.kind_of? Hash then
            @data = arg1
          elsif arg1.kind_of? String then
            @data = {}
            args[:cluster] = arg1
            args[:grid] = arg2 if arg2.kind_of? String
          else
            raise ArgumentError
          end

          call_initialize_procs args
        end
      end

      def def_host_init
        re_define_method :initialize do |arg1, arg2 = nil, arg3 = nil|
          args = {}

          if arg1.kind_of? Hash then
            @data = arg1
          elsif arg1.kind_of? String then
            @data = {}
            args[:host] = arg1
            args[:cluster] = arg2 if arg2.kind_of? String
            args[:grid] = arg3 if arg3.kind_of? String
          else
            raise ArgumentError
          end

          call_initialize_procs args
        end
      end

      class Name
        def initialize klass
          @klass = klass
        end

        def singular_route_key
          @klass.to_s.split('::').join('_').downcase
        end
      end

      def model_name
        Name.new self
      end
    end
  end
end
