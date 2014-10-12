=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.
=end

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'remote-exec/version'

Gem::Specification.new do |spec|
  spec.name        = 'remote-exec'
  spec.version     = ::RemoteExec::VERSION
  spec.licenses    = ['MIT']

  spec.authors     = ['Michal Papis']
  spec.email       = ['mpapis@gmail.com']

  spec.homepage    = 'https://github.com/remote-exec/remote-exec'
  spec.summary     = 'Invoke commands on remote hosts'

  spec.add_dependency('ruby-hooks', '~>1.1')
  spec.add_dependency('session', '~>3.2')
  spec.add_dependency('net-ssh', '~>2.9')
  spec.add_development_dependency('guard-minitest', '~>2.3')
  spec.add_development_dependency('guard-yard', '~>2.1')
  spec.add_development_dependency('rake', '~>10.3')
  spec.add_development_dependency("minitest", "~>5.4")
  spec.add_development_dependency("mocha", '~>1.1')

  spec.files        = Dir.glob('lib/**/*.rb')
  spec.test_files   = Dir.glob('test/**/*.rb')
end
