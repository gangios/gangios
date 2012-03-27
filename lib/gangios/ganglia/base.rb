require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Plugin Ganglia", true

module Gangios
  module Base
    class Enumerator
      include Document::Ganglia

      unless defined? Document::GangliaSummary then
        add_initialize_proc do
          @xpath = @options.delete :xpath
          debug "Get Parms xpath: #{@xpath}"

          next if @data.has_key? :gmetad

          @data[:gmetad] = GMetad.get_data '/'
        end
      end

      safe_define_method :each do |&block|
        @data[:gmetad].elements.each @xpath do |data|
          # debug "Enumerator.each called, xpath: #{@xpath}, data: #{data.inspect}"
          block.call @klass.new @data.merge({gmetad: data})
        end

        self
      end
    end

    class Grid
      include Document::Ganglia
      add_ganglia_init unless defined? Document::GangliaSummary

      field :name, type: :String
      field :authority, type: :String
      field :localtime, type: :Integer

      has_many :clusters
      has_many :hosts
    end

    class Cluster
      include Document::Ganglia
      add_ganglia_init unless defined? Document::GangliaSummary

      field :name, type: :String
      field :localtime, type: :Integer
      field :owner, type: :String
      field :latlong, type: :String
      field :url, type: :String
      field :gridname, type: :Custom, xpath: '..', attribute: 'NAME'

      has_many :hosts
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
      field :gridname, type: :Custom, xpath: '../..', attribute: 'NAME'
      field :clustername, type: :Custom, xpath: '..', attribute: 'NAME'

      has_many :metrics
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
  end
end

debug "Plugin Ganglia Load Success"