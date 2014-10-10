lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'remote/exec/version'

Gem::Specification.new do |spec|
  spec.name        = 'remote-exec'
  spec.version     = ::Remote::Exec::VERSION
  spec.licenses    = ['MIT']

  spec.authors     = ['Michal Papis']
  spec.email       = ['mpapis@gmail.com']

  spec.homepage    = 'https://github.com/remote-exec/remote-exec'
  spec.summary     =
  spec.description = 'Invoke commands on remote hosts'

  spec.add_dependency('ruby-hooks', '~>1.1')
  spec.add_dependency('session')
  spec.add_dependency('net-ssh')
  spec.add_development_dependency('rake')
  spec.add_development_dependency("minitest")
  spec.add_development_dependency("mocha")

  spec.files        = Dir.glob('lib/**/*.rb')
  spec.test_files   = Dir.glob('test/**/*.rb')
end
