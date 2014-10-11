require 'session'
require "remote/exec/base"

class Remote::Exec::Local < Remote::Exec::Base
  attr_reader :shell

  def initialize(shell = "sh")
    @shell = shell
    yield self if block_given?
  end

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

  def shell_session
    @shell_session ||= Session::Sh.new(:prog => shell).tap do |shell|
      after_connect.changed_and_notify(self)
    end
  end
end
