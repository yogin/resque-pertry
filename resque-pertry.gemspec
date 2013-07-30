Gem::Specification.new do |s|
  s.name        = "resque-pertry"
  s.description = "Use MySQL to add job persistence, and job retry mechanism"
  s.version     = "0.0.1"
  s.authors     = [ "Anthony Powles" ]
  s.email       = "rubygems+resque-pertry@idreamz.net"
  s.summary     = "Resque job persistence and retry mechanism"
  s.homepage    = "https://github.com/yogin/resque-pertry"
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
