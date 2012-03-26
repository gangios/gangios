#!/usr/bin/env ruby
$debug = true
require File.join(File.dirname(__FILE__), "lib/gangios")

# # generate metric from Ruby and send it over UDP
# Gangios::GMetric.send(
#   :name => 'send_requests',
#   :units => 'req/min',
#   :type => 'uint16',     # unsigned 8-bit int
#   :value => 100,       # value of metric
#   :tmax => 60,          # maximum time in seconds between gmetric calls
#   :dmax => 300          # lifetime in seconds of this metric
# )


# # for summary
# grid = Gangios::Base::Summary::Grid.new
# puts grid

# begin
#   grid = Gangios::Base::Summary::Grid.new 'gridname'
# rescue Exception => e
#   puts e
# end

# grids = Gangios::Base::Summary::Grid.all
# grids.each do |grid|
#   grid.metrics.each do |metric|
#     # puts "#{metric.name}  =>  #{metric.val}" 
#   end
# end

# begin
#   cluster = Gangios::Base::Summary::Cluster.new 'clustername'
# rescue Exception => e
#   puts e
# end

# # for more information
# grid = Gangios::Base::Grid.new
# grid.clusters.each do |cluster|
# 	puts cluster
#   cluster.hosts.each do |host|
#     puts host
#     host.metrics.each do |metric|
#       # puts "#{metric.name}  =>  #{metric.val}"
#     end
#   end
# end

# Gangios::Base::Summary::Cluster.all 
# # same as:
# Gangios::Base::Summary::Grid.new.clusters

class Grid < Gangios::Base::Summary::Grid
end
g = Grid.new
# puts g.data
# puts Grid.model_name.singular_route_key
# puts Grid.attribute_names
# puts Grid.initialize_procs

# class Cluster < Gangios::Base::Summary::Cluster
# end
# c = Cluster.new 'test'
# puts c.data
# puts Cluster.model_name.singular_route_key
# puts Cluster.attribute_names

# puts g.hosts.up
g.clusters.each do |c|
  puts c.name, c.gridname
  c.metrics.each do |m|
    puts "#{m.name}: #{m.val}", m.desc
  end
end

g.clusters.each
# Gangios::Base::Grid.new
# Gangios::Base::Cluster.new 'clustername'
# Gangios::Base::Host.new 'hostname'