require "coveralls"
require "simplecov"

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter,
  ]
  command_name "Unit Tests"
  add_filter "/test/"
end

Coveralls.noisy = true

require 'minitest/autorun'

module Rvm2
  class Shell
    module Runner
    end
    module Command
    end
  end
end

# Autoload all lib/**/*.rb files so simplecov does not misses anything
Dir[File.expand_path("../../lib/**/*.rb", __FILE__)].each{|f| require f }
