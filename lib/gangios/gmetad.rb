require "rexml/document"
require "socket"

module Gangios
  module GMetad
    @@host = 'localhost'
    @@port = 8652
    def self.set_socket host, port
      @@host, @@port = host, port
    end

    def self.ready?
      TCPSocket.new(@@host, @@port) rescue return false
      return true
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

    def self.get_data request, xpath = ''
      doc = GMetad.get_doc request
      xpath = '/GANGLIA_XML' + xpath
      doc.elements[xpath]
    end
  end
end