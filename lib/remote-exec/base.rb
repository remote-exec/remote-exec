=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.
=end

require 'ruby-hooks'
require "remote-exec/version"

# Define minimal interface for execution handlers
class RemoteExec::Base
  extend RubyHooks::InstanceHooks

  # called before connection attempt will be made, used when connection may fail
  # @notify_param object [Object] the target that invoked the method
  define_hook :before_connect

  # called when connection attempt failed and we are about to sleep and retry
  # @notify_param object    [Object]    the target that invoked the method
  # @notify_param exception [Exception] exception that made the connection attempt fail
  # @notify_param retries   [Integer]   number of retries left
  define_hook :on_connect_retry

  # called when connection attempt failed and no more retries left
  # @notify_param object    [Object]    the target that invoked the method
  # @notify_param exception [Exception] exception that made the connection attempt fail
  define_hook :on_connect_fail

  # called after connection / session is esatablished
  # @notify_param object [Object] the target that invoked the method
  define_hook :after_connect

  # called before terminating connection - only when needed
  # @notify_param object [Object] the target that invoked the method
  define_hook :before_shutdown

  # called before executing command
  # @notify_param object  [Object] the target that invoked the method
  # @notify_param command [String] the command to execute
  define_hook :before_execute

  # called before executing command
  # @notify_param object [Object] the target that invoked the method
  # @notify_param stdout [String] standard output of the command, can be nil
  # @notify_param stderr [String] standard error output of the command, can be nil
  define_hook :on_execute_data

  # called after executing command
  # @notify_param object  [Object]  the target that invoked the method
  # @notify_param command [String]  the executed command
  # @notify_param result  [Integer] the executed command status code (0 - ok, >0 - fail)
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
