=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.

Partially based on test-kitchen by Fletcher Nichol <fnichol@nichol.ca>
License: https://github.com/test-kitchen/test-kitchen/blob/459238b88c/LICENSE
=end

require 'net/ssh'
require 'ruby/hooks'
require "remote/exec/base"

class Remote::Exec::Ssh < Remote::Exec::Base
  attr_reader :hostname, :username
  attr_accessor :options

  def initialize(hostname, username, options = {})
    @hostname = hostname
    @username = username
    @options = options
    if block_given?
      yield self
      shutdown
    end
  end

  def shutdown
    return if @ssh.nil?
    before_shutdown.changed_and_notify(self, ssh)
    ssh.shutdown!
  ensure
    @ssh = nil
  end

  ##
  # Execute command on remote host
  #
  # @param cmd [String]  command string to execute
  # @return    [Integer] exit status of the command

  # TODO: make it run in one session
  def execute(command)
    last_status = nil
    ssh.open_channel do |channel|

      channel.request_pty
      before_execute.changed_and_notify(self, channel, command)

      channel.exec(command) do |ch, success|

        channel.on_data do |ch, data|
          on_execute_data.changed_and_notify(self, channel, data, nil)
          yield(data, nil) if block_given?
        end

        channel.on_extended_data do |ch, type, data|
          on_execute_data.changed_and_notify(self, channel, nil, data)
          yield(nil, data) if block_given?
        end

        channel.on_request("exit-status") do |ch, data|
          last_status = data.read_long
        end

      end

      channel.wait
      after_execute.changed_and_notify(self, channel, last_status)
    end
    ssh.loop
    last_status
  end

  def ssh
    @ssh ||= establish_connection
  end

  # Establish a connection session to the remote host.
  #
  # @return [Net::SSH::Connection::Session] the SSH connection session
  # @api private
  def establish_connection
    rescue_exceptions = [
      Errno::EACCES,
      Errno::EADDRINUSE,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::ENETUNREACH,
      Errno::EHOSTUNREACH,
      Net::SSH::Disconnect,
    ]
    retries = options[:ssh_retries] || 3

    begin
      before_connect.changed_and_notify(self)
      ssh = Net::SSH.start(hostname, username, options)
    rescue *rescue_exceptions => e
      retries -= 1
      if retries > 0
        on_connect_retry.changed_and_notify(self, e)
        sleep options[:ssh_timeout] || 1
        retry
      else
        on_connect_fail.changed_and_notify(self, e)
        raise e
      end
    end
    after_connect.changed_and_notify(self, ssh)
    ssh
  end

end
