require "rexml/document"

module Gangios
  module Document
    def self.included base
      base.extend(Methods)
      base.def_attribute_names
      base.def_init_procs
      base.def_model_name
    end

    attr_accessor :data

    module Methods
      include Define

      def def_init_procs
        @@init_procs = {} unless defined? @@init_procs
        klass = self

        safe_define_method :call_init_procs do |args = nil|
          procs = @@init_procs[klass] || {}
          debug "Initialize #{self.class} instance, exec #{procs}, data: #{@data}", true
          procs.each do |plugin, proc|
            self.instance_exec args, &proc
          end
        end

        safe_define_class_method :init_procs do |&block|
          @@init_procs[klass]
        end

        safe_define_class_method :add_init_proc do |&block|
          debug "Add #{plugin} initialize proc to #{self}"
          @@init_procs[klass] = {} if @@init_procs[klass].nil?
          @@init_procs[klass][plugin] = block
        end

        safe_define_class_method :del_init_proc do |plugin|
          debug "Del #{plugin} initialize proc to #{self}"
          @@init_procs[klass] = {} if @@init_procs[klass].nil?
          @@init_procs[klass].delete plugin
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

      def def_model_name
        safe_define_class_method :model_name do
          Name.new self
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
    end
  end
end
