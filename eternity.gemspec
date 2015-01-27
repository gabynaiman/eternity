# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eternity/version'

Gem::Specification.new do |spec|
  spec.name          = 'eternity'
  spec.version       = Eternity::VERSION
  spec.authors       = ['Gabriel Naiman']
  spec.email         = ['gabynaiman@gmail.com']
  spec.summary       = 'Distributed database version control system'
  spec.description   = 'Distributed database version control system'
  spec.homepage      = 'https://github.com/gabynaiman/eternity'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redic', '~> 1.1.1'
  spec.add_dependency 'restruct', '~> 0.0.1'
  spec.add_dependency 'class_config', '~> 0.0.1'
  spec.add_dependency 'activerecord', '~> 3.2'

  if RUBY_PLATFORM == 'java'
    spec.add_dependency 'msgpack-jruby'
  else
    spec.add_dependency 'msgpack', '~> 0.5.9'
  end

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest', '~> 4.7'
  spec.add_development_dependency 'turn', '~> 0.9'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'pry-nav'
  spec.add_development_dependency 'database_cleaner', '~> 1.4'
  spec.add_development_dependency 'activerecord_uuid'

  if RUBY_PLATFORM == 'java'
    spec.add_development_dependency 'activerecord-jdbcpostgresql-adapter'
  else
    spec.add_development_dependency 'pg'
  end
end