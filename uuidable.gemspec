lib = File.expand_path('../lib', __FILE__)
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

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'travis', '~> 1.8', '>= 1.8.2'

  spec.add_dependency 'activerecord', '>= 4.2', '< 6.0'
  spec.add_dependency 'uuidtools', '>= 2.1', '< 3'
end
