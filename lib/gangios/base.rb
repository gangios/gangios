require "gangios/utiles"
require "gangios/gmetad"
require "gangios/document"
require "gangios/finders"

module Gangios
  module Base
    module Summary
    # ##############################
    # Summary data ?filter=summary
      class Grid
        def initialize(options = {})
          @data = GMetad.get_data "/?filter=summary", '/', options
        end
      end

      class Cluster
        def initialize(cluster, options = {})
          if cluster.kind_of? Hash then
            @data = cluster[:data]
          elsif cluster.kind_of? String then
            options[:name] = cluster
            @data = GMetad.get_data "/#{cluster}?filter=summary", '/CLUSTER', options
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

        include Finders
        define_each
      end

      class Clusters
        include Document
        define_init

        include Finders
        define_each
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

        include Finders
        define_each Metric, 'METRICS'
      end

      class Grid
        include Document
        field :name, type: String
        field :authority, type: String
        field :localtime, type: Integer

        has_many :clusters
        has_many :hosts, tag: 'HOSTS'
        has_many :metrics
      end

      class Cluster
        include Document
        field :name, type: String
        field :localtime, type: Integer
        field :owner, type: String
        field :latlong, type: String
        field :url, type: String

        has_many :hosts, tag: 'HOSTS'
        has_many :metrics

        include Finders
        define_all "/?filter=summary", '/CLUSTER'
      end

      class Metric
        include Document
        define_init true

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
      def initialize(options = {})
        @data = GMetad.get_data "/", '/', options
      end
    end

    class Cluster
      def initialize(cluster, options = {})
        if cluster.kind_of? Hash then
          @data = cluster[:data]
        elsif cluster.kind_of? String then
          options[:name] = cluster
          @data = GMetad.get_data "/#{cluster}", '/CLUSTER', options
        else
          raise ArgumentError
        end
      end
    end

    class Host
      def initialize(host, cluster = nil, options = {})
        if host.kind_of? Hash then
          @data = host[:data]
        elsif host.kind_of? String and cluster.kind_of? String then
          options[:name] = host
          @data = GMetad.get_data "/#{cluster}/#{host}", '/CLUSTER/HOST', options
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

      include Finders
      define_each
    end

    class Clusters
      include Document
      define_init

      include Finders
      define_each
    end

    class Hosts
      include Document
      define_init

      include Finders
      define_each Host, '//HOST'
    end

    class Metrics
      include Document
      define_init

      include Finders
      define_each
    end

    class Grid
      include Document
      field :name, type: String
      field :authority, type: String
      field :localtime, type: Integer

      has_many :clusters
      has_many :hosts
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

      include Finders
      define_all "/", '/CLUSTER'
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

      include Finders
      define_all "/", '/CLUSTER/HOST'
    end

    class Metric
      include Document
      define_init true

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