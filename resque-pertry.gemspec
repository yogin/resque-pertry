Gem::Specification.new do |s|
  s.name        = "resque-pertry"
  s.description = "Adds persistence to Resque jobs, and retry properties"
  s.version     = "1.0.3"
  s.authors     = [ "Anthony Powles" ]
  s.email       = "rubygems+resque-pertry@idreamz.net"
  s.summary     = "Allows job to be persistent, and be retried in case of failure"
  s.homepage    = "https://github.com/yogin/resque-pertry"
  s.license     = "MIT"
  s.files       = `git ls-files`.split($/)

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
  s.add_development_dependency "pry"

  s.add_dependency "activesupport", ">= 3.0.0"
  s.add_dependency "activerecord", ">= 3.0.0"
  s.add_dependency "resque"
  s.add_dependency "resque-scheduler", ">= 2.0.0"
  s.add_dependency "uuidtools", "~> 2.1.4"
end
