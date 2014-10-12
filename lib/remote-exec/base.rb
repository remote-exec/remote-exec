=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.
=end

require 'ruby/hooks'
require "remote-exec/version"

# Define minimal interface for execution handlers
class RemoteExec::Base
  extend Ruby::Hooks::InstanceHooks

  # called before connection attempt will be made, used when connection may fail
  # @!method before_connect
  # @return            [Hook]   the +Observable+ implementation to handle hooks
  # @yieldparam object [Object] the target that invoked the method
  define_hook :before_connect

  # called when connection attempt failed and we are about to sleep and retry
  # @!method on_connect_retry
  # @return               [Hook]      the +Observable+ implementation to handle hooks
  # @yieldparam object    [Object]    the target that invoked the method
  # @yieldparam exception [Exception] exception that made the connection attempt fail
  # @yieldparam retries   [Integer]   number of retries left
  define_hook :on_connect_retry

  # called when connection attempt failed and we no more retries left
  # @!method on_connect_fail
  # @return               [Hook]      the +Observable+ implementation to handle hooks
  # @yieldparam object    [Object]    the target that invoked the method
  # @yieldparam exception [Exception] exception that made the connection attempt fail
  define_hook :on_connect_fail

  # called after connection / session is esatablished
  # @!method after_connect
  # @return            [Hook]   the +Observable+ implementation to handle hooks
  # @yieldparam object [Object] the target that invoked the method
  define_hook :after_connect

  # called before terminating connection - only when needed
  # @!method before_shutdown
  # @return            [Hook]   the +Observable+ implementation to handle hooks
  # @yieldparam object [Object] the target that invoked the method
  define_hook :before_shutdown

  # called before executing command
  # @!method before_execute
  # @return             [Hook]   the +Observable+ implementation to handle hooks
  # @yieldparam object  [Object] the target that invoked the method
  # @yieldparam command [String] the command to execute
  define_hook :before_execute

  # called before executing command
  # @!method on_execute_data
  # @return            [Hook]   the +Observable+ implementation to handle hooks
  # @yieldparam object [Object] the target that invoked the method
  # @yieldparam stdout [String] standard output of the command, can be nil
  # @yieldparam stderr [String] standard error output of the command, can be nil
  define_hook :on_execute_data

  # called after executing command
  # @!method after_execute
  # @return             [Hook]    the +Observable+ implementation to handle hooks
  # @yieldparam object  [Object]  the target that invoked the method
  # @yieldparam command [String]  the executed command
  # @yieldparam result  [Integer] the executed command status code (0 - ok, >0 - fail)
  define_hook :after_execute

  # standard in place handler that ensures shutdown is called
  def initialize
    if block_given?
      begin
        yield self
      ensure
        shutdown
      end
    end
  end

  # minimal handler for shutdown
  def shutdown
    before_shutdown.changed_and_notify(self)
  end

end
