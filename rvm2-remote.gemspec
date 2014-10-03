lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rvm2/remote/version'

Gem::Specification.new do |spec|
  spec.name        = 'rvm2-remote'
  spec.version     = ::Rvm2::Remote::VERSION
  spec.license     = 'Apache2'

  spec.authors     = ['Michal Papis']
  spec.email       = ['mpapis@gmail.com']

  spec.homepage    = 'https://github.com/rvm/rvm2-remote'
  spec.summary     =
  spec.description = 'Invoke commands on remote hosts'

  spec.add_dependency('session')
  spec.add_dependency('net-ssh')
  spec.add_development_dependency('rake')

  spec.files        = Dir.glob('lib/**/*.rb')
  spec.test_files   = Dir.glob('test/**/*.rb')
end
