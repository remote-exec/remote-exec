=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.

Partially based on test-kitchen by Fletcher Nichol <fnichol@nichol.ca>
License: https://github.com/test-kitchen/test-kitchen/blob/459238b88c/LICENSE
=end

require 'net/ssh'
require 'ruby/hooks'
require "remote_exec/base"

# Class to help establish SSH connections, issue remote commands, and
# transfer files between a local system and remote node.
class RemoteExec::Ssh < RemoteExec::Base
  # hostname for the connection
  attr_reader :hostname
  # username for the connection
  attr_reader :username
  # options for the connection
  attr_accessor :options

  # Constructs a new Ssh object.
  #
  # @param hostname [String] the remote hostname (IP address, FQDN, etc.)
  # @param username [String] the username for the remote host
  # @param options  [Hash]   configuration options for ssh
  # @yield          [self]   if a block is given then the constructed
  # object yields itself and calls `#shutdown` at the end, closing the
  # remote connection
  def initialize(hostname, username, options = {})
    @hostname = hostname
    @username = username
    @options = options
    super()
  end

  # Shuts down the session connection, if it is still active.
  def shutdown
    super
    return if @ssh.nil?
    ssh.shutdown!
  ensure
    @ssh = nil
  end

  ##
  # Execute command on remote host
  #
  # @param command [String]  command string to execute
  # @return        [Integer] exit status of the command

  def execute(command)
    # TODO: make it run in one session
    @last_status = nil
    @command     = command
    ssh.open_channel(&method(:execute_open_channel))
    ssh.loop
    @last_status
  end

private

  def execute_open_channel(channel)
    before_execute.changed_and_notify(self, @command)
    channel.request_pty
    channel.exec(@command, &method(:execute_channel_exec))
    channel.wait
    after_execute.changed_and_notify(self, @command, @last_status)
  end

  def execute_channel_exec(channel, success)
    channel.on_data(&method(:execute_on_stdout))
    channel.on_extended_data(&method(:execute_on_stderr))
    channel.on_request("exit-status") do |channel, data|
      @last_status = data.read_long
    end
  end

  def execute_on_stdout(channel, data)
    on_execute_data.changed_and_notify(self, data, nil)
    yield(data, nil) if block_given?
  end

  def execute_on_stderr(channel, type, data)
    case type
    when 1
      on_execute_data.changed_and_notify(self, nil, data)
      yield(nil, data) if block_given?
    else
      raise "Unsupported SSH extended_data type: #{type.inspect}"
    end
  end

  def ssh
    @ssh ||= establish_connection
  end

  RESCUE_EXCEPTIONS = [
    Errno::EACCES,
    Errno::EADDRINUSE,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::ENETUNREACH,
    Errno::EHOSTUNREACH,
    Net::SSH::Disconnect,
  ]

  # Establish a connection session to the remote host.
  #
  # @return [Net::SSH::Connection::Session] the SSH connection session
  # @api private
  def establish_connection
    @retries = options[:ssh_retries] || 2
    begin
      before_connect.changed_and_notify(self)
      ssh = Net::SSH.start(hostname, username, options)
    rescue *RESCUE_EXCEPTIONS => exception
      handle_exception_retry(exception)
      retry
    end
    after_connect.changed_and_notify(self)
    ssh
  end

  def handle_exception_retry(exception)
    if @retries > 0
      on_connect_retry.changed_and_notify(self, exception, @retries)
      sleep options[:ssh_timeout] || 1
      @retries -= 1
    else
      on_connect_fail.changed_and_notify(self, exception)
      # TODO: should we wrap the error in some other common class?
      raise exception
    end
  end

end
