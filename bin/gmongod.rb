#!/usr/bin/env ruby
require 'rubygems'

require 'mongo'
Conn = Mongo::Connection.new
DB = Conn['gangios']
Coll = DB['logs']

require 'gangios/gdaemon'

module DBSaver		
	def self.start
		loop do
			begin
				data = readline
				Parser.parse data
			rescue Exception => e
				debug e
			end
		end
	end

	def self.stop
	end
end

module Parser
	def self.parse(line)
		if /^<(\d+)>1 ([-:T\d]+)[+-]\d{2}:\d{2} (\w+) (\w+) (\d+|-) (\w+|-) (\w+|-) (.+)$/ =~ line then
			data = {}
			data['severity'], data['level'] = $1.to_i.divmod 8
			data['timestamp'] = $2
			data['hostname'] = $3
			data['application'] = $4
			data['pid'] = $5
			data['messageid'] = $6
			data['structured_data'] = $7
			data['msg'] = $8
			Coll.insert(data)
		end
	end
end

Gangios::GDaemon.daemonize DBSaver
