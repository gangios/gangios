require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Main Program", true

module Gangios
  module Base
    class Enumerator
      include Document

      attr_reader :klass, :options

      def initialize klass, data = {}, options = {}
        if data.kind_of? Hash and klass.kind_of? Class then
          @data = data
          @klass = klass
          @options = options if options.kind_of? Hash
        else
          raise ArgumentError
        end

        call_initialize_procs
      end
    end

    module Summary
    # ##############################
    # Summary data
      class Grid
        include Document
        def_grid_init
      end

      class Cluster
        include Document
        def_cluster_init
      end

      class Metric
        include Document

        def initialize metric, cluster = nil, grid = nil
          args = {}

          if metric.kind_of? Hash then
            @data = metric
          elsif metric.kind_of? String and host.kind_of? String then
            @data = {}
            args[:metric] = metric
            args[:cluster] = cluster if cluster.kind_of? String
            args[:grid] = grid if grid.kind_of? String
          else
            raise ArgumentError
          end

          call_initialize_procs args
        end
      end
    end

    # ##############################
    # All data
    class Grid
      include Document
      def_grid_init
    end

    class Cluster
      include Document
      def_cluster_init
    end

    class Host
      include Document
      def_host_init
    end

    class Metric
      include Document

      def initialize metric, host, cluster = nil, grid = nil
        args = {}

        if metric.kind_of? Hash then
          @data = metric
        elsif metric.kind_of? String and host.kind_of? String then
          @data = {}
          args[:metric] = metric
          args[:host] = host
          args[:cluster] = cluster if cluster.kind_of? String
          args[:grid] = grid if grid.kind_of? String
        else
          raise ArgumentError
        end

        call_initialize_procs args
      end
    end
  end
end

debug "Main Program Load Success"