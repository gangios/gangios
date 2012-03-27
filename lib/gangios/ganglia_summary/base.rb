require File.join(File.dirname(__FILE__), "document")

debug "Start Initialize Plugin Ganglia Summary", true

module Gangios
  module Base
    class Enumerator
      include Document::GangliaSummary

      add_init_proc do
        @xpath = @options.delete :xpath
        debug "Get Parms xpath: #{@xpath}, klass: #{@klass}, options: #{options}"

        if @klass == Host then
          # if defined Document::Ganglia
          # get the normal data from gmetad 
          unless @data[:gmetad] then
            request = '/'
            request += "#{@options[:cluster]}" if @options[:cluster]
            @data[:gmetad] = GMetad.get_data request, '/GRID'
            debug "Get GMetad Data #{@data[:gmetad].inspect}"
          end
        end

        next if @data[:gmetad_summary]
        @data[:gmetad_summary] = GMetad.get_data '/?filter=summary'
      end

      safe_define_method :each do |&block|
        @data[:gmetad_summary].elements.each @xpath do |data|
          # debug "Enumerator.each called, xpath: #{@xpath}, data: #{data.inspect}"
          block.call @klass.new @data.merge({gmetad_summary: data})
        end

        self
      end
    end

    class Hosts < Enumerator
      field :up, type: :Integer, xpath: 'HOSTS'
      field :down, type: :Integer, xpath: 'HOSTS'

      if defined? Document::Ganglia then
        re_define_method :each do |&block|
          @data[:gmetad].elements.each @xpath do |data|
            # debug "Enumerator.each called, xpath: #{@xpath}, data: #{data.inspect}"

            block.call @klass.new @data.merge({gmetad: data})
          end
        end

        self
      end
    end

    class Grid
      include Document::GangliaSummary
      add_ganglia_summary_init

      field :name, type: :String
      field :authority, type: :String
      field :localtime, type: :Integer

      has_many :clusters
      has_many :hosts, enumerator: Hosts
      has_many :metrics, klass: Metrics, xpath: 'METRICS'
    end

    class Cluster
      include Document::GangliaSummary
      add_ganglia_summary_init

      field :name, type: :String
      field :localtime, type: :Integer
      field :owner, type: :String
      field :latlong, type: :String
      field :url, type: :String
      field :gridname, type: :Custom, xpath: '..', attribute: 'NAME'

      has_many :hosts, enumerator: Hosts
      has_many :metrics, klass: Metrics, xpath: 'METRICS'
    end

    class Metrics
      include Document::GangliaSummary
      add_ganglia_summary_init

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
