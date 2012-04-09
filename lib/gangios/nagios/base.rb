debug "Start Initialize Plugin Nagios", true

module Gangios
  module Base
    class Enumerator
    end

    class Hosts
      add_init_proc :nagios do
        @data[:nagios] = Nagios::Status.new
        # @data[:nagios][:hosts][name]
      end
    end

    class Grid
    end

    class Cluster
    end

    class Host
      def status
        nagios = @data[:nagios]
        nagios.get_data if nagios.empty?
        @data[:nagios][:hosts][name]
      end
    end

    class Metric
      def status
        nagios = @data[:nagios]
        nagios.get_data if nagios.empty?
        @data[:nagios][:hosts][name]
      end
    end
  end
end

debug "Plugin Nagios Load Success"