Gem::Specification.new do |spec|
  spec.name         = "rasel"
  spec.version      = "0.0.1"
  spec.summary      = "Random Access Stack Esoteric Language"

  spec.author       = "Victor Maslov aka Nakilon"
  spec.email        = "nakilon@gmail.com"
  spec.license      = "MIT"
  spec.metadata     = {"source_code_uri" => "https://github.com/nakilon/rasel"}

  spec.add_development_dependency "minitest-around"
  spec.add_development_dependency "ruby-prof" unless ENV["CI"]

  spec.bindir       = "bin"
  spec.executable   = "rasel"
  spec.test_file    = "test.rb"
  spec.files        = %w{ LICENSE rasel.gemspec lib/rasel.rb bin/rasel }
end
