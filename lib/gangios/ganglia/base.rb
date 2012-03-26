require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Plugin Ganglia", true

module Gangios
  module Base
    class Enumerator
      include Document::Ganglia

      add_initialize_proc do
        @xpath = @options.delete :xpath
        debug "Get Parms xpath: #{@xpath}"

        next if @data.has_key? :gmetad
        classname = self.to_s
        if classname.include? 'Summary' then
          request_suffix = '?filter=summary'
        else
          request_suffix = nil
        end
        request = "/#{request_suffix}"

        @data[:gmetad] = GMetad.get_data request
      end

      safe_define_method :each do |&block|
        @data[:gmetad].elements.each @xpath do |data|
          # debug "Enumerator.each called, xpath: #{@xpath}, data: #{data.inspect}"
          block.call @klass.new @data.merge({gmetad: data})
        end

        self
      end
    end

    module Summary
    # ##############################
    # Summary data ?filter=summary
      class Hosts
        include Document
        include Document::Ganglia
        
        def initialize data, klass = nil, options = {}
          data[:gmetad] = data[:gmetad].elements['HOSTS']
          @data = data
        end

        field :up, type: Integer
        field :down, type: Integer
      end

      class Grid
        include Document::Ganglia
        add_ganglia_init

        field :name, type: String
        field :authority, type: String
        field :localtime, type: Integer

        has_many :clusters
        has_many :hosts, klass: Hosts
        has_many :metrics, xpath: 'METRICS'

        add_initialize_proc do |args = nil|
          puts "Grid"
        end
      end

      class Cluster
        include Document::Ganglia
        add_ganglia_init

        field :name, type: String
        field :localtime, type: Integer
        field :owner, type: String
        field :latlong, type: String
        field :url, type: String
        field :gridname, type: Custom, xpath: '..', attribute: 'NAME'

        has_many :hosts, klass: Hosts
        has_many :metrics, xpath: 'METRICS'
      end

      class Metric
        include Document::Ganglia
        add_ganglia_init

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
      include Document::Ganglia
      add_ganglia_init

      field :name, type: String
      field :authority, type: String
      field :localtime, type: Integer

      has_many :clusters
      has_many :hosts
    end

    class Cluster
      include Document::Ganglia
      add_ganglia_init

      include Document::Ganglia
      field :name, type: String
      field :localtime, type: Integer
      field :owner, type: String
      field :latlong, type: String
      field :url, type: String
      field :gridname, type: Custom, xpath: '..', attribute: 'NAME'

      has_many :hosts
    end

    class Host
      include Document::Ganglia
      add_ganglia_init

      include Document::Ganglia
      field :name, type: String
      field :ip, type: String
      field :reported, type: Integer
      field :tn, type: Integer
      field :tmax, type: Integer
      field :dmax, type: Integer
      field :location, type: String
      field :gmond_started, type: Integer
      field :gridname, type: Custom, xpath: '../..', attribute: 'NAME'
      field :clustername, type: Custom, xpath: '..', attribute: 'NAME'

      has_many :metrics
    end

    class Metric
      include Document::Ganglia
      add_ganglia_init

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

debug "Plugin Ganglia Load Success"