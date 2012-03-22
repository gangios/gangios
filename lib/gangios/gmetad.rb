require "rexml/document"
require "socket"

module Gangios
  module GMetad
    @@host = 'localhost'
    @@port = 8652
    def self.set_socket host, port
      @@host, @@port = host, port
    end

    # use request and host:port
    # default host:port are localhost:8652
    # return a REXML::Document object
    def self.get_doc request
      s = TCPSocket.new(@@host, @@port) rescue return
      begin
        s.puts request
        doc = REXML::Document.new s
      ensure
        s.close
      end
      return doc
    end

    def self.get_data request, xpath, rname = nil
      doc = GMetad.get_doc request
      xpath = '/GANGLIA_XML' + xpath
      ret = doc.elements[xpath]
      if rname then
          lname = ret.attribute('NAME').to_s
          raise ArgumentError, "No such cluster - #{rname}" unless lname == rname
      end
      raise RuntimeError, "No data" if ret.nil?
      return ret
    end
  end
end