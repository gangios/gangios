require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Plugin Ganglia", true

module Gangios
  module Base
    class Enumerator
      include Document::Ganglia

      unless defined? Document::GangliaSummary then
        add_init_proc do
          @xpath = @options.delete :xpath
          debug "Get Parms xpath: #{@xpath}"

          next if @data.has_key? :gmetad
          @data[:gmetad] = GMetad.get_data '/'
        end
      end

      add_each_proc do |name|
        each_data = @each_data[:gmetad]
        next unless each_data
        data = each_data.elements[@xpath] if name.kind_of? TrueClass
        data = each_data.next_element if name.kind_of? FalseClass
        data = @data.elements["#{@xpath}[@NAME='#{name}']"] if name.kind_of? String

        @each_data.merge! gmetad: data
        ret = data.attribute('NAME') if data
        next ret
      end
    end

    class Grid
      include Document::Ganglia
      add_ganglia_init unless defined? Document::GangliaSummary

      field :name, type: :String
      field :authority, type: :String
      field :localtime, type: :Integer

      has_many :clusters
      has_many :hosts, xpath: "/CLUSTER/HOST"
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
  end
end

debug "Plugin Ganglia Load Success"