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

  spec.add_dependency 'restruct', '~> 1.0'
  spec.add_dependency 'class_config', '~> 0.0'
  spec.add_dependency 'transparent_proxy', '~> 0.0'

  if RUBY_PLATFORM == 'java'
    spec.add_dependency 'msgpack-jruby', '~> 1.4'
  else
    spec.add_dependency 'msgpack', '~> 1.0'
  end

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 11.0'
  spec.add_development_dependency 'minitest', '~> 5.0', '< 5.11'
  spec.add_development_dependency 'minitest-colorin', '~> 0.1'
  spec.add_development_dependency 'minitest-line', '~> 0.6'
  spec.add_development_dependency "minitest-great_expectations"
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'pry-nav', '~> 0.2'

  if RUBY_VERSION < '2'
    spec.add_development_dependency 'term-ansicolor', '~> 1.3.0'
    spec.add_development_dependency 'tins', '~> 1.6.0'
    spec.add_development_dependency 'json', '~> 1.8'
  end
end