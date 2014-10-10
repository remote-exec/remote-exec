=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.

Partially based on test-kitchen by Fletcher Nichol <fnichol@nichol.ca>
License: https://github.com/test-kitchen/test-kitchen/blob/459238b88c/LICENSE
=end

require 'net/ssh'
require 'ruby/hooks'

class Remote::Exec::Ssh
  attr_reader :host, :user
  attr_accessor :options

  define_hook :after_connect
  define_hook :before_shutdown
  define_hook :before_execute
  define_hook :on_execute_data
  define_hook :after_execute

  def initialize(host, user, options = {})
    @host = host
    @user = user
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
    @ssh ||= Net::SSH.start(host, user, options).tap do |ssh|
      after_connect.changed_and_notify(self, ssh)
    end
  end
end
