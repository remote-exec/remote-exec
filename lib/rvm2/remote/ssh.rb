require 'net/ssh'

class Rvm2::Shell::Runner::Ssh
  attr_reader :host, :user, :last_status

  def initialize(host, user = nil)
    @host = host
    @user = user
  end

  # TODO: make it run in one session
  def execute(command)
    @last_status = nil
    ssh.open_channel do |channel|
      channel.request_pty
      channel.exec command do |ch, success|
        channel.on_data do |ch, data|
          yield(data, nil)
        end
        channel.on_extended_data do |ch, type, data|
          yield(nil, data)
        end
        channel.on_request("exit-status") do |ch, data|
          @last_status = data.read_long
        end
      end
      channel.wait
    end
    ssh.loop
    @last_status
  end

  def ssh
    @ssh ||= Net::SSH.start(host, user)
  end
end
