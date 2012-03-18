# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gangios/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["bbtfr"]
  gem.email         = ["bbtfrr@gmail.com"]
  gem.description   = %q{Several tools for Ganglia & Nagios}
  gem.summary       = %q{Several tools for Ganglia & Nagios}
  gem.homepage      = "http://github.com/bbtfr/gangios"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "gangios"
  gem.require_paths = ["lib"]
  gem.version       = Gangios::VERSION
end
