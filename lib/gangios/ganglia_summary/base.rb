require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Plugin Ganglia Summary", true

module Gangios
  module Base
    class Enumerator
      include Document::GangliaSummary

      add_init_proc do
        @xpath = @options.delete :xpath
        debug "Get Parms xpath: #{@xpath}, klass: #{@klass}, options: #{options}"

        next if @data[:gmetad_summary]
        @data[:gmetad_summary] = GMetad.get_data '/?filter=summary'
      end

      add_each_proc do |name|
        each_data = @each_data[:gmetad_summary]
        next unless each_data
        data = each_data.elements[@xpath] if name.kind_of? TrueClass
        data = each_data.next_element if name.kind_of? FalseClass
        data = @data.elements["#{@xpath}[@NAME='#{name}']"] if name.kind_of? String

        @each_data.merge! gmetad_summary: data
        ret = data.attribute('NAME') if data
        next ret
      end
    end

    class EnumHost < Enumerator
      field :up, type: :Integer, xpath: 'HOSTS'
      field :down, type: :Integer, xpath: 'HOSTS'

      add_init_proc do
        next unless defined? Document::Ganglia

        # if defined Document::Ganglia
        # get the normal data from gmetad 
        unless @data[:gmetad] then
          name = @options[:cluster]
          if name then
            request = "/#{name}"
            xpath = "/GRID/CLUSTER[@NAME='#{name}']"
          else
            request = '/'
            xpath = '/GRID'
          end
          @data[:gmetad] = GMetad.get_data request, xpath
        end
      end
    end

    class Grid
      include Document::GangliaSummary
      add_ganglia_init

      field :name, type: :String
      field :authority, type: :String
      field :localtime, type: :Integer

      has_many :clusters
      has_many :hosts, enumerator: EnumHost, sort: :gmetad, xpath: "CLUSTER/HOST"
      has_many :metrics, klass: Metrics, xpath: 'METRICS'
    end

    class Cluster
      include Document::GangliaSummary
      add_ganglia_init

      field :name, type: :String
      field :localtime, type: :Integer
      field :owner, type: :String
      field :latlong, type: :String
      field :url, type: :String
      field :gridname, type: :Custom, xpath: '..', attribute: 'NAME'

      has_many :hosts, enumerator: EnumHost, sort: :gmetad
      has_many :metrics, klass: Metrics, xpath: 'METRICS'
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

debug "Plugin Ganglia Summary Load Success"
