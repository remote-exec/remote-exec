require 'session'

class Rvm2::Shell::Runner::Local
  attr_reader :shell, :last_status

  def initialize(shell = "sh")
    @shell = shell
  end

  def execute(command)
    @last_status = nil
    shell_session.execute(command) do |out, err|
      yield(out, err)
    end
    @last_status = shell_session.status
  end

  def shell_session
    @shell_session ||= Session::Sh.new(:prog => shell)
  end
end
