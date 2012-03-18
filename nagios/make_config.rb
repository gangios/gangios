#!/usr/bin/env ruby

require 'rexml/document'
require 'socket'
require 'yaml'


$stdout = File.open 'check_ganglia.yml.in', 'w'
host, port = 'localhost', 8651

hosts = {}
metricnames = []

# Open Ganglia meta daemon socket and read xdl
TCPSocket.open(host, port) do |socket|
  doc = REXML::Document.new socket
  doc.elements.each '/GANGLIA_XML/GRID/CLUSTER/HOST' do |host|
    hosts[host.attribute 'NAME'] = host.attribute 'IP'
    host.elements.each 'METRIC' do |metric|
      metricname = metric.attribute('NAME').to_s
      units = metric.attribute('UNITS').to_s
      next if metricnames.include? metricname
      metricnames.push metricname
      puts "# #{metricname} #{units}"

      description = ''
      metric.elements.each 'EXTRA_DATA/EXTRA_ELEMENT[@NAME="DESC"]' do |desc|
        description = desc.attribute 'VAL'
      end
      puts "# #{description}"

      description = ''
      metric.elements.each 'EXTRA_DATA/EXTRA_ELEMENT[@NAME="TITLE"]' do |desc|
        description = desc.attribute 'VAL'
      end

      title = ''
      metricname.split('_').each do |word|
        title += word.capitalize + ' '
      end
      title.chop!

      puts <<-EOT
#{title}:
  value: $#{metricname}$
  critical: $? 
  warning: $? 
  description: #{description} is $?#{units}
EOT
    end
  end
end

yaml = YAML.load_file 'check_ganglia.yml' rescue exit
$stdout = File.open 'ganglia-services.cfg', 'w'

puts <<-EOT
define command {
  command_name            check_ganglia
  command_line            $USER1$/check_ganglia
}

define hostgroup {
  hostgroup_name          ganglia-servers
  alias                   Ganglia servers
}

define servicegroup {
  servicegroup_name       ganglia-metrics
  alias                   Ganglia Metrics
}

define service {
  use                     generic-service
  host_name               localhost
  service_description     Ganglia
  check_command           check_ganglia
}

define host {
  use                     generic-host
  name                    ganglia-host
  active_checks_enabled   1
  passive_checks_enabled  1
  max_check_attempts      4
  hostgroups              ganglia-servers
  notification_interval   0                   ; set > 0 if you want to be renotified
}

define service {
  use                     generic-service
  name                    ganglia-service
  active_checks_enabled   0
  passive_checks_enabled  1
  hostgroup_name          ganglia-servers
  service_groups          ganglia-metrics
  check_command           check_ping
  notification_interval   0                   ; set > 0 if you want to be renotified
}

EOT

hosts.each do |hostname, ip|
  puts <<-EOT
  define host {
    use                     ganglia-host
    host_name               #{hostname}
    alias                   #{hostname}
    address                 #{ip}
  }

  EOT
end

yaml.each do |title, conf|
  puts <<-EOT
  define service {
    use                     ganglia-service
    service_description     #{title}
  }

  EOT
end
