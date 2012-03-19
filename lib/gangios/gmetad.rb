require "rexml/document"
require "socket"

module Gangios
  module GMetad
    # use request and host:port
    # default host:port are localhost:8652
    # return a REXML::Document object
    def self.get_doc(request, options)
      host = options[:host] || 'localhost'
      port = options[:port] || 8652
      s = TCPSocket.new(host, port)
      begin
        s.puts request
        doc = REXML::Document.new s
      ensure
        s.close
      end
      return doc
    end

    def self.get_data(request, xpath, options)
      doc = GMetad.get_doc request, options
      xpath = '/GANGLIA_XML/GRID' + xpath
      ret = doc.elements[xpath]
      if options[:name] then
          rname = options[:name]
          name = ret.attribute('NAME').to_s
          raise ArgumentError, "No such cluster - #{rname}" unless name == rname
      end
      raise RuntimeError, "No data" if ret.nil?
      return ret
    end
  end
end