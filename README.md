# Gangios

Several ruby modules for Ganglia Nagios & Syslog-ng

## Installation

Add this line to your application's Gemfile:

    gem 'gangios'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gangios

## Usage

Generate metric from Ruby and send it over UDP

    Gangios::GMetric.send(
      :name => 'packets_requests',
      :units => 'req/min',
      :type => 'uint16',    # unsigned 8-bit int
      :value => 100,        # value of metric
      :tmax => 60,          # maximum time in seconds between gmetric calls
      :dmax => 300          # lifetime in seconds of this metric
    )

To get summary information, use GridSummary, ClusterSummary

    grid = Gangios::GridSummary.new

    puts grid.hosts.up
    grid.metrics.each do |metric|
    	puts "#{metric.name}  =>  #{metric.val}" 
    end

    cluster = grid.clusters['clustername']
    # - or -
    cluster = Gangios::Cluster.new 'clustername'

    cluster.metrics.each do |metric|
    	puts "#{metric.name}  =>  #{metric.val}" 
    end

To get more information(information of each host), use Grid, Cluster & Host

    grid = Gangios::Grid.new
    grid.clusters.each do |cluster|
      cluster.hosts.each do |host|
        host.metrics.each do |metric|
          puts metric.name, metric.val, metric.desc, nil
        end
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Global setup: Set up git

    git config --global user.name "LiYang"
    git config --global user.email bbtfrr@gmail.com
      
Next steps:

    mkdir gangios
    cd gangios
    git init
    touch README
    git add README
    git commit -m 'first commit'
    git remote add origin git@github.com:bbtfr/gangios.git
    git push -u origin master
      
Existing Git Repo?

    cd existing_git_repo
    git remote add origin git@github.com:bbtfr/gangios.git
    git push -u origin master