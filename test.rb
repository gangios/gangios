#!/usr/bin/env ruby
# $debug = true
start = Time.new
require File.join(File.dirname(__FILE__), "lib/gangios")
middle = Time.new
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

class Grid < Gangios::Base::Grid
end
g = Grid.new
# puts g.data
# puts Grid.model_name.singular_route_key
# puts Grid.attribute_names
# puts Grid.init_procs

# class Cluster < Gangios::Base::Summary::Cluster
# end
# c = Cluster.new 'test'
# puts c.data
# puts Cluster.model_name.singular_route_key
# puts Cluster.attribute_names

# puts g.hosts.up
# g.clusters.each do |c|
#   puts c.name, c.gridname
#   c.hosts.each do |h|
#     puts h.name, h.clustername, h.gridname
#     h.metrics.each do |m|
#       puts "#{m.name}: #{m.val}", m.desc
#     end
#   end
# end

# g.clusters.each do |c|
#   puts c.name, c.gridname
#   # c.metrics.each do |m|
#   #   puts "#{m.name}: #{m.val}", m.desc
#   # end
#   # puts c.hosts.up
#   c.hosts.each do |h|
#     puts h.name
#     h.metrics.each do |m|
#     	# puts "#{m.name}: #{m.val}", m.desc
#     end
#   end
# end

g.clusters.each do |c|
  puts c.name, c.gridname
  # c.metrics.each {}
  c.metrics.each do |m|
    # puts "#{m.name}: #{m.val}", m.desc
  end
  # puts c.hosts.up
  # puts c.data
  c.hosts.each do |h|
    puts h.name
    # h.metrics.each {}
    h.metrics.each do |m|
      # puts "#{m.name}: #{m.val}", m.desc
    end
  end
end

doc = Gangios::GMetad.get_data "/?filter=summary"
# puts doc
doc.elements.each 'METRICS' do |m|
  puts m.attribute('SUM')
end

# normal = Gangios::GMetad.get_doc "/"
# summary = Gangios::GMetad.get_doc "/?filter=summary"

# Gangios::Base::Grid.new
# Gangios::Base::Cluster.new 'clustername'
# Gangios::Base::Host.new 'hostname'
puts middle - start
puts Time.new - start