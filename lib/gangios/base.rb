require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Main Program", true

module Gangios
  module Base
    class Enumerator
      include Document

      attr_reader :klass, :options

      def initialize klass, sort, data = {}, options = {}
        if data.kind_of? Hash and klass.kind_of? Class then
          @data = data
          @klass = klass
          @sort = sort
          @options = options if options.kind_of? Hash
        else
          raise ArgumentError
        end

        call_init_procs
      end

      def each &block
        klass = self.class
        procs = {}
        until klass == Object
          kprocs = klass.each_procs
          procs.merge! kprocs if kprocs
          klass = klass.superclass
        end

        debug "#{self.class}.each called, exec #{procs}, data #{@data} sort by #{@sort}", true
        first = procs.delete @sort
        @each_data = @data.clone
        name = self.instance_exec true, &first
        while name do
          procs.each do |plugin, proc|
            self.instance_exec name, &proc
          end
          yield @klass.new @each_data, name
          name = self.instance_exec false, &first
        end
      end

      module Methods
        attr_accessor :each_procs

        def add_each_proc &block
          debug "Add #{plugin_name} each proc to #{self}"
          self.each_procs = {} if self.each_procs.nil?
          self.each_procs[plugin_name] = block
        end

        def insert_each_proc &block
          debug "Add #{plugin_name} each proc to #{self}"
          self.each_procs = [] if self.each_procs.nil?
          self.each_procs[plugin_name] = block
        end
      end
      extend Methods
    end

    class Grid
      include Document

      def initialize arg1 = nil, arg2 = nil
        args = {}

        if arg1.kind_of? Hash then
          @data = arg1
          args[:grid] = arg2
        elsif arg1.nil? or arg1.kind_of? String then
          @data = {}
          args[:grid] = arg1
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Cluster
      include Document

      def initialize arg1, arg2 = nil
        args = {}

        if arg1.kind_of? Hash then
          @data = arg1
          args[:cluster] = arg2
        elsif arg1.kind_of? String then
          @data = {}
          args[:cluster] = arg1
          args[:grid] = arg2 if arg2.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Host
      include Document

      def initialize arg1, arg2 = nil, arg3 = nil
        args = {}

        if arg1.kind_of? Hash then
          @data = arg1
          args[:host] = arg2
        elsif arg1.kind_of? String then
          @data = {}
          args[:host] = arg1
          args[:cluster] = arg2 if arg2.kind_of? String
          args[:grid] = arg3 if arg3.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Metric
      include Document

      def initialize arg1, arg2 = nil, arg3 = nil, arg4 = nil
        args = {}

        if arg1.kind_of? Hash then
          @data = arg1
          args[:metric] = arg2
        elsif arg1.kind_of? String and arg2.kind_of? String then
          @data = {}
          args[:metric] = arg1
          args[:host] = arg2
          args[:cluster] = arg3 if arg3.kind_of? String
          args[:grid] = arg4 if arg4.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Metrics
      include Document

      def initialize arg1, arg2 = nil, arg3 = nil
        args = {}

        if arg1.kind_of? Hash then
          @data = arg1
          args[:metrics] = arg2
        elsif arg1.kind_of? String then
          @data = {}
          args[:metrics] = arg1
          args[:cluster] = arg2 if arg2.kind_of? String
          args[:grid] = arg3 if arg3.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end
  end
end

debug "Main Program Load Success"