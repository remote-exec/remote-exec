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
    ssh.shutdown!
  ensure
    @ssh = nil
  end

  # TODO: make it run in one session
  def execute(command)
    last_status = nil
    ssh.open_channel do |channel|
      channel.request_pty
      channel.exec command do |ch, success|
        channel.on_data do |ch, data|
          yield(data, nil) if block_given?
        end
        channel.on_extended_data do |ch, type, data|
          yield(nil, data) if block_given?
        end
        channel.on_request("exit-status") do |ch, data|
          last_status = data.read_long
        end
      end
      channel.wait
    end
    ssh.loop
    last_status
  end

  def ssh
    @ssh ||= Net::SSH.start(host, user, options)
  end
end
