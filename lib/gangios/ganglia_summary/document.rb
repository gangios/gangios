require "rexml/document"
require File.join(File.dirname(__FILE__), "../ganglia/document")

module Gangios
  module Document
    module GangliaSummary
      def self.included base
        base.extend Methods
      end

      module Methods
        include Ganglia::MethodsBase
        def plugin_name
          :gmetad_summary
        end

        def request_suffix
          "?filter=summary"
        end
      end
    end
  end
end
