require 'session'
require "remote-exec/base"

# Class to run local commands and transfer files localy.
class RemoteExec::Local < RemoteExec::Base
  # name of the shell to run
  attr_reader :shell

  # Constructs a new Local object.
  #
  # @param shell [String] name of the shell to run
  # @yield       [self]   if a block is given then the constructed
  # object yields itself and calls `#shutdown` at the end, closing the
  # remote connection

  def initialize(shell = "sh")
    @shell = shell
    super()
  end

  ##
  # Execute command locally
  #
  # @param command [String]  command string to execute
  # @return        [Integer] exit status of the command

  def execute(command)
    before_execute.changed_and_notify(self, command)
    shell_session.execute(command) do |out,err|
      on_execute_data.changed_and_notify(self, out, err)
      yield(out, err) if block_given?
    end
    last_status = shell_session.status
    after_execute.changed_and_notify(self, command, last_status)
    last_status
  end

private

  def shell_session
    @shell_session ||= Session::Sh.new(:prog => shell).tap do |shell|
      after_connect.changed_and_notify(self)
    end
  end
end
