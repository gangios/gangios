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

        call_init_procs
      end
    end

    class Grid
      include Document

      def initialize grid = nil
        args = {}

        if grid.kind_of? Hash then
          @data = grid
        elsif grid.nil? or grid.kind_of? String then
          @data = {}
          args[:grid] = grid
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Cluster
      include Document

      def initialize cluster, grid = nil
        args = {}

        if cluster.kind_of? Hash then
          @data = cluster
        elsif cluster.kind_of? String then
          @data = {}
          args[:cluster] = cluster
          args[:grid] = grid if grid.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Host
      include Document

      def initialize host, cluster = nil, grid = nil
        args = {}

        if host.kind_of? Hash then
          @data = host
        elsif host.kind_of? String then
          @data = {}
          args[:host] = host
          args[:cluster] = cluster if cluster.kind_of? String
          args[:grid] = grid if grid.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end

    class Metric
      include Document

      def initialize metric, host = nil, cluster = nil, grid = nil
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

        call_init_procs args
      end
    end

    class Metrics
      include Document

      def initialize metric, cluster = nil, grid = nil
        args = {}

        if metric.kind_of? Hash then
          @data = metric
        elsif metric.kind_of? String then
          @data = {}
          args[:metric] = metric
          args[:cluster] = cluster if cluster.kind_of? String
          args[:grid] = grid if grid.kind_of? String
        else
          raise ArgumentError
        end

        call_init_procs args
      end
    end
  end
end

debug "Main Program Load Success"