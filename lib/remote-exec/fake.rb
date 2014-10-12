=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.
=end

require "remote-exec/base"

# Class to fake running commands and transfering files.
class RemoteExec::Fake < RemoteExec::Base

  ##
  # The story to tell in +execute+, take an array
  #
  # @example usage
  #
  #   [1, [[nil,"error\n"]]
  #
  # @return [Array] story to run in execute, format: [ return_status, [[ stdout, stderr],...] ]

  attr_accessor :story

  # Constructs a new Fake object.
  #
  # @yield [self] if a block is given then the constructed  object
  #               yields itself and calls `#shutdown` at the end,
  #               closing the remote connection

  def initialize
    after_connect.changed_and_notify(self)
    super
  end

  ##
  # Execute fake command
  #
  # @param command [String]  command string to execute
  # @return        [Integer] exit status of the command

  def execute(command)
    before_execute.changed_and_notify(self, command)
    last_status, outputs = @story
    outputs.each do |out, err|
      on_execute_data.changed_and_notify(self, out, err)
      yield(out, err) if block_given?
    end
    after_execute.changed_and_notify(self, command, last_status)
    last_status
  end

end
