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
        def plugin
          :gmetad_summary
        end

        def add_ganglia_summary_init request = nil, xpath = nil
          type = self.to_s.split('::').last.downcase.to_sym

          add_init_proc do |args = nil|
            next if @data.has_key? :gmetad_summary

            # work for gmetad_summary request and rexml xpath
            request = GMetad.get_request(type, args) + "?filter=summary" unless request
            xpath = GMetad.get_xpath type, args unless xpath

            @data[:gmetad_summary] = GMetad.get_data request, xpath
            debug "Get GMetad Data #{@data[:gmetad_summary].inspect}"
            raise "No such #{type} - #{args}" if @data[:gmetad_summary].nil?
          end
        end

        # define all find etc. as class method
        # for Grid Cluster & Host
        def def_class_finders
          re_define_class_method :all do |options = {}|
            if options.kind_of? String then
              return self.new options
            end

            # change id to name
            if options.has_key? :id then
              options[:name] = options.delete :id
            end

            klass.new GMetad.get_data('/?filter=summary', '/'), options
          end
        end
      end
    end
  end
end
