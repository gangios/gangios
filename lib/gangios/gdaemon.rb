#!/usr/bin/env ruby
PROGRAMNAME = File.basename(__FILE__, '.rb')
TIMEZONE = Time.now.strftime("%z").insert(-3, ':')
$debug = $stdout

def flush
	$stdout.flush
end

def debug info
	if $debug then
		$debug.puts info.to_s 
		$debug.flush
	end
end	

module Gangios
	module GDaemon
		module PidFile
			def self.pid_fn
				File.join("/run/", "#{PROGRAMNAME}.pid")
			end

			def self.store pid
				begin
					File.open(pid_fn, 'w') do |file|
						file << pid
					end
				rescue Exception => e
					debug e
				end
			end

			def self.recall
				begin
					IO.read(pid_fn).to_i rescue nil
				rescue Exception => e
					debug e
				end
			end
			
			def self.cleanup
				begin
					File.unlink(pid_fn)
				rescue Exception => e
					debug e
				end
			end
		end

		UMASK=0
		WORKDIR = '/'
		MAXFD = 1024
		REDIRECT_TO = '/dev/null'
		USERNAME = 'nobody'

		def self.daemonize deamon, redirect = nil, setfork = false, setuid = nil
			if setfork then
				begin
					exit if fork
					if setuid then
						setuid = USERNAME unless setuid.kind_of? String
						Sys.setuid Etc.getpwnam.uid
						exit if fork
					end
				rescue Exception => e
					debug e
					exit
				end
			end

			Dir.chdir '/'
			File.umask UMASK

			if redirect then
				redirect = REDIRECT_TO unless redirect.kind_of? String
				$stdout = File.new redirect, 'a'
				$stderr = File.new redirect, 'a'
			end

			case !ARGV.empty? && ARGV[0]
			when 'start'
				start deamon
			when 'stop'
				stop deamon
			when 'restart'
				stop deamon
				start deamon
			when 'force-reload'
				reload deamon
			else
				puts "Usage: #{PROGRAMNAME} {start|stop|restart|force-reload}"
				exit
			end
		end
		
		def self.start deamon
			trap("SIGINT") do
				deamon.stop
				PidFile.cleanup
				debug "#{PROGRAMNAME}[#{$$}] stopped"
				exit
			end
			debug "#{PROGRAMNAME}[#{$$}] started"

			pid = PidFile.recall
			if pid then
				debug "#{PROGRAMNAME}[#{pid}] already running"
				exit
			end
			
			PidFile.store Process.pid
			deamon.start
		end

		def self.stop deamon
			pid = PidFile.recall
			if pid then
				begin 
					Process.kill("SIGINT", pid)
				rescue 
					PidFile.cleanup	
				else 
					sleep 1
				end
			else
				debug "#{PROGRAMNAME} pid file not found, is it running?"
				flush
			end
		end
		
		def self.reload deamon
			trap("SIGINT") do
				deamon.stop
				PidFile.cleanup
				exit
			end
			
			pid = PidFile.recall
			if pid then
				begin 
					Process.kill("SIGINT", pid)
				rescue 
				else
					debug "#{PROGRAMNAME}[#{pid}] already running"
					flush
					sleep 1
				end
			end
			
			PidFile.store Process.pid
			deamon.start
		end
	end
end