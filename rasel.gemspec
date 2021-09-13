Gem::Specification.new do |spec|
  spec.name         = "rasel"
  spec.version      = "1.2.0"
  spec.summary      = "Random Access Stack Esoteric Language"

  spec.author       = "Victor Maslov aka Nakilon"
  spec.email        = "nakilon@gmail.com"
  spec.license      = "MIT"
  spec.metadata     = {"source_code_uri" => "https://github.com/nakilon/rasel"}

  spec.add_dependency "json_pure"
  spec.add_dependency "webrick"
  spec.add_dependency "sinatra"
  spec.add_development_dependency "minitest-around"

  spec.files        = %w{ LICENSE rasel.gemspec lib/rasel.rb bin/jquery-3.6.0.min.js
                          bin/rasel bin/rasel-annotated bin/rasel-convert bin/rasel-ide }
  spec.executables  = %w{     rasel     rasel-annotated     rasel-convert     rasel-ide }
  spec.bindir       = "bin"
end
