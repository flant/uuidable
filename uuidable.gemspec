# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uuidable/version'

Gem::Specification.new do |spec|
  spec.name          = 'uuidable'
  spec.version       = Uuidable::VERSION
  spec.authors       = ['Sergey Gnuskov']
  spec.email         = ['sergey.gnuskov@flant.com']

  spec.summary       = 'Helps using uuid everywhere in routes instead of id for ActiveRecord models.'
  spec.description   = ''
  spec.homepage      = 'https://github.com/flant/uuidable'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7'

  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'travis', '~> 1.8', '>= 1.8.2'

  spec.add_dependency 'activerecord', '>= 4.2', '< 8.0'
  spec.add_dependency 'mysql-binuuid-rails', '>= 1.3', '< 2'
  spec.add_dependency 'uuidtools', '>= 2.1', '< 3'
end
