require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Plugin Ganglia", true

module Gangios
  module Base
    class Enumerator
      # for ganglia summary data
      # include Document::GangliaSummary

      add_init_proc :gmetad_summary do
        @xpath = @options.delete :xpath
        debug "Get Parms xpath: #{@xpath}, klass: #{@klass}, options: #{options}"

        # next if @data[:gmetad_summary]
        # @data[:gmetad_summary] = GMetad.get_data '/?filter=summary'
      end

      [:gmetad_summary, :gmetad].each do |database|
        add_each_proc database do |name|
          each_data = @each_data[database]
          next unless each_data
          data = each_data.elements[@xpath] if name.kind_of? TrueClass
          data = each_data.next_element if name.kind_of? FalseClass
          data = each_data.elements["#{@xpath}[@NAME='#{name}']"] if name.kind_of? String

          @each_data.merge! database => data
          ret = data.attribute('NAME').to_s if data
          next ret
        end
      end
    end

    class Grid
      include Document::GangliaSummary
      add_ganglia_init

      field :name, type: :String
      field :authority, type: :String
      field :localtime, type: :Integer
      field :hosts_up, type: :Integer, xpath: 'HOSTS', attribute: 'UP'
      field :hosts_down, type: :Integer, xpath: 'HOSTS', attribute: 'DOWN'

      has_many :clusters
      has_many :hosts, sort: :gmetad, xpath: "CLUSTER/HOST"
      has_many :metrics, klass: Metrics, xpath: 'METRICS'
    
      alias_method :hosts_origin, :hosts
      def hosts
        # get the normal data from gmetad 
        unless @data[:gmetad] then
          @data[:gmetad] = GMetad.get_data '/'
        end

        hosts_origin
      end
    end

    class Cluster
      include Document::GangliaSummary
      add_ganglia_init

      field :name, type: :String
      field :localtime, type: :Integer
      field :owner, type: :String
      field :latlong, type: :String
      field :url, type: :String
      field :hosts_up, type: :Integer, xpath: 'HOSTS', attribute: 'UP'
      field :hosts_down, type: :Integer, xpath: 'HOSTS', attribute: 'DOWN'
      field :gridname, type: :String, xpath: '..', attribute: 'NAME'

      has_many :hosts, sort: :gmetad
      has_many :metrics, klass: Metrics, xpath: 'METRICS'

      alias_method :hosts_origin, :hosts
      def hosts
        # get the normal data from gmetad 
        unless @data[:gmetad] then
          name = self.name
          request = "/#{name}"
          xpath = "/GRID/CLUSTER[@NAME='#{name}']"

          @data[:gmetad] = GMetad.get_data request, xpath
        end

        hosts_origin
      end
    end

    class Host
      include Document::Ganglia
      add_ganglia_init

      field :name, type: :String
      field :ip, type: :String
      field :reported, type: :Integer
      field :tn, type: :Integer
      field :tmax, type: :Integer
      field :dmax, type: :Integer
      field :location, type: :String
      field :gmond_started, type: :Integer
      field :gridname, type: :String, xpath: '../..', attribute: 'NAME'
      field :clustername, type: :String, xpath: '..', attribute: 'NAME'

      has_many :metrics, sort: :gmetad
    end

    class Metric
      include Document::Ganglia
      add_ganglia_init

      field :name, type: :String
      field :val, type: :Metric
      field :type, type: :String
      field :units, type: :String
      field :tn, type: :Integer
      field :tmax, type: :Integer
      field :dmax, type: :Integer
      field :group, type: :Extra
      field :desc, type: :Extra
      field :title, type: :Extra
    end

    class Metrics
      include Document::GangliaSummary
      add_ganglia_init

      field :name, type: :String
      field :sum, type: :Metric
      field :num, type: :Integer
      field :type, type: :String
      field :units, type: :String
      field :group, type: :Extra
      field :desc, type: :Extra
      field :title, type: :Extra
      alias_method :val, :sum
    end
  end
end

debug "Plugin Ganglia Load Success"