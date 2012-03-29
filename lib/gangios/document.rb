require "rexml/document"

module Gangios
  module Document
    def self.included base
      base.extend(Methods)
    end

    attr_accessor :data

    def call_init_procs args = nil
      klass = self.class
      procs = {}
      until klass == Object
        kprocs = klass.init_procs
        procs = kprocs.merge procs if kprocs
        klass = klass.superclass
      end

      debug "Initialize #{self.class} instance, exec #{procs}, data: #{@data}", true
      procs.each do |plugin, proc|
        # self.send proc, args
        self.instance_exec args, &proc
      end
    end

    module Methods
      include Define

      attr_accessor :init_procs
      attr_accessor :attr_names

      def add_init_proc name = plugin_name, &block
        debug "Add #{name} initialize proc to #{self}"
        self.init_procs = {} if self.init_procs.nil?
        self.init_procs[name] = block
      end

      def add_attribute_names attribute
        self.attr_names = [] if self.attr_names.nil?
        self.attr_names << attribute
      end

      def attribute_names
        klass = self.class
        names = []
        until klass == Object
          knames = klass.attr_names
          names += knames.values if knames
          klass = klass.superclass
        end
      end

      def model_name
        Name.new self
      end

      class Name
        def initialize klass
          @klass = klass
        end

        def singular_route_key
          @klass.to_s.split('::').join('_').downcase
        end
      end
    end
  end
end
