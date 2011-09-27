# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "masochism/version"

Gem::Specification.new do |s|
  s.name        = "masochism"
  s.version     = Masochism::VERSION
  s.authors     = ["Trae Robrock"]
  s.email       = ["trobrock@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Simple gem to enable read slaves in Rails}
  s.description = %q{Simple gem to enable read slaves in Rails}

  s.rubyforge_project = "masochism"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rails", "=2.3.10"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mocha"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
