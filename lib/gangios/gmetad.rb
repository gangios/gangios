require "rexml/document"
require "socket"

module Gangios
  module GMetad

    # use request and host:port
    # default host:port are localhost:8652
    # return a REXML::Document object
    def self.get_data request, args
      host = args[:host] || 'localhost'
      port = args[:port] || 8652
      s = TCPSocket.new host, port
      begin
        s.puts request
        doc = REXML::Document.new s
      ensure
        s.close
      end
      return doc
    end
  end

  # marcos to define functions & attributes
  # Ruby Metaprogramming!
  module Define

    # define attributes reading data from xml
    # use @data(REXML::Element)
    # the attribute return a string
    def define_attr *args
      args.each do |arg|
        class_eval <<-END
          def #{arg}
            @data.attribute('#{arg.to_s.upcase}').to_s
          end
        END
      end
    end

    # same as define_attr, but
    # the attribute return a number(float)
    def define_attr_f *args
      args.each do |arg|
        class_eval <<-END
          def #{arg}
            @data.attribute('#{arg.to_s.upcase}').to_s.to_f
          end
        END
      end
    end

    # same as define_attr, but
    # the attribute return a integer
    def define_attr_i *args
      args.each do |arg|
        class_eval <<-END
          def #{arg}
            @data.attribute('#{arg.to_s.upcase}').to_s.to_i
          end
        END
      end
    end

    # same as define_attr, but
    # reading data from <EXTRA_DATA><EXTRA_ELEMENT here! /></EXTRA_DATA>
    def define_attr_extra *args
      args.each do |arg|
        class_eval <<-END
          def #{arg}
            @data.elements["EXTRA_DATA/EXTRA_ELEMENT[@NAME='#{arg.to_s.upcase}']"].attribute('VAL').to_s
          end
        END
      end
    end

    # define a class as enumerator
    # this class provide 2 functions
    # [] and each to access data
    def define_enum_class mod, cmod, tag
      class_eval <<-END
        class #{mod}
          extend Define
          define_init

          def [] name
            #{cmod}.new :data => @data.elements["#{tag}[@NAME='\#{name}']"]
          end

          def each
            @data.elements.each '#{tag}' do |data|
              yield #{cmod}.new :data => data
            end
          end
        end
      END
    end

    # define a default initialize function
    def define_init hash = false
      str_eval = <<-END
        def initialize data
      END
      if hash then
        str_eval += <<-END
          data = data[:data]
        END
      end
      str_eval += <<-END
          raise TypeError, "\#{data} not kind of REXML::Element" unless data.kind_of? REXML::Element
          @data = data
        end
      END
      class_eval str_eval
    end

    # define a function to get enumerator
    def define_enum func, mod, element = nil
      str_eval = <<-END
        def #{func}
          #{mod}.new @data
      END
      if element
        str_eval.chop!
        str_eval += ".elements['#{element}']\n"
      end
      str_eval += <<-END
        end
      END
      class_eval str_eval
    end
  end

  # extend Define module to get the marcos
  extend Define

  # ##############################
  # Summary data ?filter=summary
  class GridSummary
    def initialize(args = {})
      doc = GMetad.get_data "/?filter=summary", args
      @data = doc.elements['/GANGLIA_XML/GRID']
    end

    extend Define
    define_attr :name, :authority
    define_attr_f :localtime
    define_enum :clusters, :ClustersSummary
    define_enum :hosts, :HostsSummary, 'HOSTS'
    define_enum :metrics, :MetricsSummary
  end

  class ClusterSummary
    def initialize(cluster, args = {})
      if cluster.kind_of? Hash then
        @data = cluster[:data]
      elsif cluster.kind_of? String then
        doc = GMetad.get_data "/#{cluster}?filter=summary", args
        data = doc.elements['/GANGLIA_XML/GRID/CLUSTER']
        name = data.attribute('NAME').to_s
        raise ArgumentError, "No such cluster - #{cluster}" unless name == cluster
        @data = data
      else
        raise ArgumentError
      end
    end

    extend Define
    define_attr :name, :owner, :latlong, :url
    define_attr_i :localtime
    define_enum :hosts, :HostsSummary, 'HOSTS'
    define_enum :metrics, :MetricsSummary
  end

  class HostsSummary
    extend Define
    define_init

    define_attr_i :up, :down
  end

  class MetricSummary
    extend Define
    define_init true

    define_attr :name, :type, :units
    define_attr_f :sum
    define_attr_i :num
    define_attr_extra :group, :desc, :title
    alias_method :val, :sum
  end

  define_enum_class :ClustersSummary, :ClusterSummary, 'CLUSTER'
  define_enum_class :MetricsSummary, :MetricSummary, 'METRICS'

  # ##############################
  # All data without ?filter
  class Grid
    def initialize(args = {})
      doc = GMetad.get_data "/", args
      @data = doc.elements['/GANGLIA_XML/GRID']
    end

    extend Define
    define_attr :name, :authority
    define_attr_i :localtime
    define_enum :clusters, :Clusters
    define_enum :hosts, :Hosts
  end

  class Cluster
    def initialize(cluster, args = {})
      if cluster.kind_of? Hash then
        @data = cluster[:data]
      elsif cluster.kind_of? String then
        doc = GMetad.get_data "/#{cluster}", args
        data = doc.elements['/GANGLIA_XML/GRID/CLUSTER']
        name = data.attribute('NAME').to_s
        raise ArgumentError, "No such cluster - #{cluster}" unless name == cluster
        @data = data
      else
        raise ArgumentError
      end
    end

    extend Define
    define_attr :name, :owner, :latlong, :url
    define_attr_i :localtime
    define_enum :hosts, :Hosts
  end

  class Host
    def initialize(host, cluster = nil, args = {})
      if host.kind_of? Hash then
        @data = host[:data]
      elsif host.kind_of? String then
        if cluster.kind_of? String then
          doc = GMetad.get_data "/#{cluster}/#{host}", args
          data = doc.elements['/GANGLIA_XML/GRID/CLUSTER/HOST']
          name = data.attribute('NAME').to_s
          raise ArgumentError, "No such host - #{host}" unless name == host
          @data = data
        else
          doc = GMetad.get_data "/", args
          data = doc.elements["/GANGLIA_XML/GRID/CLUSTER/HOST[@NAME='#{host}']"]
          raise ArgumentError, "No such host - #{host}" unless data
          @data = data
        end
      else
        raise ArgumentError
      end
    end

    extend Define
    define_attr :name, :ip, :location, :tags
    define_attr_i :reported, :tn, :tmax, :dmax, :gmond_started
    define_enum :metrics, :Metrics
  end

  class Metric
    extend Define
    define_init true

    define_attr :name, :type, :units
    define_attr_f :val
    define_attr_i :tn, :tmax, :dmax
    define_attr_extra :group, :desc, :title
  end

  define_enum_class :Clusters, :Cluster, 'CLUSTER'
  define_enum_class :Hosts, :Host, '//HOST'
  define_enum_class :Metrics, :Metric, 'METRIC'
end