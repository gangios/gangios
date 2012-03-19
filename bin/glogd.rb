#!/usr/bin/env ruby
require 'rubygems'

require 'fssm'
require 'gangios/gdaemon'

# $debug = nil

WatchPath = {
	'/tmp' => '*.log'
}

$files = {}

module LogReader
	@files = {}
	
	WatchPath.each do |watchpath, glob|
		Dir.glob(File.join(watchpath, glob)) do |path|
			@files[path] = File.size(path)
		end
	end

	def self.start
		FSSM.monitor do
			WatchPath.each do |watchpath, glob|
				proc = Proc.new do |base, relative|
					next unless File.fnmatch? glob, relative
					LogReader.analyze path
				end

				path watchpath do
					update &proc
					create &proc
				end
			end
		end
	end

	def self.stop
	end
	
	def self.analyze path
		size = @files[path] rescue 0
		if File.size(path) < size
			size = 0
			debug "File #{path} truncated"
		end
		File.open(path) do |file|
			file.pos = size if size != 0
			Parser.parse file.readlines
		end
		
		flush
		@files[path] = File.size(path)
	end
end

module Parser
	def self.parse lines
		lines.each do |line|
			level = 5
			severity = 3
			priority = severity * 8 + level
			puts "<#{priority}>1 #{(Time.now.strftime("%FT%T"))}#{TIMEZONE} localhost gmond - - - #{line}"
		end
	end
end

Gangios::GDaemon.daemonize LogReader