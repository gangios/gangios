require "rexml/document"
require "socket"

module Gangios
  module GMetad
    @@host = 'localhost'
    @@port = 8652
    def self.set_socket host, port
      @@host, @@port = host, port
    end

    def self.socket
      return @@host, @@port
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

    def self.get_data request, xpath = '/GRID'
      doc = GMetad.get_doc request
      xpath = '/GANGLIA_XML' + xpath
      doc = doc.elements[xpath]
      debug "Get GMetad Data by request #{request} xpath #{xpath} #{doc.inspect}", false, :green
      doc
    end

    def self.get_xpath type, args = nil
      case type
      when :grid
        xpath = "/GRID"
        xpath += "[@NAME='#{args[:grid]}']" if args[:grid]
        xpath
      when :cluster
        xpath = "/GRID"
        xpath += "[@NAME='#{args[:grid]}']" if args[:grid]
        xpath += "/CLUSTER"
        xpath += "[@NAME='#{args[:cluster]}']"
        xpath
      when :host
        xpath = "/GRID"
        xpath += "[@NAME='#{args[:grid]}']" if args[:grid]
        xpath += "/CLUSTER"
        xpath += "[@NAME='#{args[:cluster]}']" if args[:cluster]
        xpath += "/HOST"
        xpath += "[@NAME='#{args[:host]}']"
        xpath
      when :metric
        xpath = "/GRID"
        xpath += "[@NAME='#{args[:grid]}']" if args[:grid]
        xpath += "/CLUSTER"
        xpath += "[@NAME='#{args[:cluster]}']" if args[:cluster]
        xpath += "/HOST"
        xpath += "[@NAME='#{args[:host]}']"
        xpath += "/METRIC"
        xpath += "[@NAME='#{args[:metric]}']"
        xpath
      end
    end

    def self.get_request type, args = nil
      case type
      when :grid
        "/"
      when :cluster
        "/#{args[:cluster]}"
      when :host
        if args[:cluster] then
          "/#{args[:cluster]}/#{args[:host]}"
        else
          "/"
        end
      when :metric
        if args[:cluster] then
          "/#{args[:cluster]}/#{args[:host]}"
        else
          "/"
        end
      end
    end
  end
end
