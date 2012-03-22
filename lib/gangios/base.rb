require "gangios/utiles"
require "gangios/gmetad"
require "gangios/document"

module Gangios
  module Base
    module Summary
    # ##############################
    # Summary data ?filter=summary
      class Grid
        def initialize grid
          @data = {}
          if grid.kind_of? Hash then
            @data[:ganglia] = grid[:data]
          elsif grid.kind_of? String then
            @data[:ganglia] = GMetad.get_data "/?filter=summary", "/GRID", grid
          else
            raise ArgumentError
          end
        end
      end

      class Cluster
        def initialize cluster
          @data = {}
          if cluster.kind_of? Hash then
            @data[:ganglia] = cluster[:data]
          elsif cluster.kind_of? String then
            @data[:ganglia] = GMetad.get_data "/#{cluster}?filter=summary", "/GRID/CLUSTER", cluster
          else
            raise ArgumentError
          end
        end
      end

      class Metric
      end

      class Grids
        include Document
        define_init
        define_finders
      end

      class Clusters
        include Document
        define_init
        define_finders
      end

      class Hosts
        include Document
        define_init

        field :up, type: Integer
        field :down, type: Integer
      end

      class Metrics
        include Document
        define_init
        define_finders "METRICS"
      end

      class Grid
        include Document
        field :name, type: String
        field :authority, type: String
        field :localtime, type: Integer

        has_many :clusters
        has_many :hosts, tag: "HOSTS"
        has_many :metrics

        define_class_finders
      end

      class Cluster
        include Document
        field :name, type: String
        field :localtime, type: Integer
        field :owner, type: String
        field :latlong, type: String
        field :url, type: String

        has_many :hosts, tag: "HOSTS"
        has_many :metrics

        define_class_finders
      end

      class Metric
        include Document
        define_init

        field :name, type: String
        field :sum, type: Metric
        field :num, type: Integer
        field :type, type: String
        field :units, type: String
        field :group, type: Extra
        field :desc, type: Extra
        field :title, type: Extra
        alias_method :val, :sum
      end
    end

    # ##############################
    # All data without ?filter
    class Grid
      def initialize grid
        @data = {}
        if grid.kind_of? Hash then
          @data[:ganglia] = grid[:data]
        elsif grid.kind_of? String then
          @data[:ganglia] = GMetad.get_data "/", "/GRID", grid
        else
          raise ArgumentError
        end
      end
    end

    class Cluster
      def initialize cluster
        @data = {}
        if cluster.kind_of? Hash then
          @data[:ganglia] = cluster[:data]
        elsif cluster.kind_of? String then
          @data[:ganglia] = GMetad.get_data "/#{cluster}", "/GRID/CLUSTER", cluster
        else
          raise ArgumentError
        end
      end
    end

    class Host
      def initialize host, cluster = nil
        @data = {}
        if host.kind_of? Hash then
          @data[:ganglia] = host[:data]
        elsif host.kind_of? String then
          if cluster.kind_of? String then
            @data[:ganglia] = GMetad.get_data "/#{cluster}/#{host}", "/GRID/CLUSTER/HOST", host
          elsif cluster.nil? then
            @data[:ganglia] = GMetad.get_data "/", "//HOST[@NAME='#{host}']", host
          end
        else
          raise ArgumentError
        end
      end
    end

    class Metric
    end

    class Grids
      include Document
      define_init
      define_finders
    end

    class Clusters
      include Document
      define_init
      define_finders
    end

    class Hosts
      include Document
      define_init
      define_finders
    end

    class Metrics
      include Document
      define_init
      define_finders
    end

    class Grid
      include Document
      field :name, type: String
      field :authority, type: String
      field :localtime, type: Integer

      has_many :clusters
      has_many :hosts

      define_class_finders
    end

    class Cluster
      include Document
      field :name, type: String
      field :localtime, type: Integer
      field :owner, type: String
      field :latlong, type: String
      field :url, type: String

      has_many :hosts
      has_many :metrics

      define_class_finders
    end

    class Host
      include Document
      field :name, type: String
      field :ip, type: String
      field :reported, type: Integer
      field :tn, type: Integer
      field :tmax, type: Integer
      field :dmax, type: Integer
      field :location, type: String
      field :gmond_started, type: Integer

      has_many :metrics

      define_class_finders
    end

    class Metric
      include Document
      define_init

      field :name, type: String
      field :val, type: Metric
      field :type, type: String
      field :units, type: String
      field :tn, type: Integer
      field :tmax, type: Integer
      field :dmax, type: Integer
      field :group, type: Extra
      field :desc, type: Extra
      field :title, type: Extra
    end
  end
end