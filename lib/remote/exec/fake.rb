require "remote/exec/base"

class Remote::Exec::Fake < Remote::Exec::Base

  def initialize
    after_connect.changed_and_notify(self)
    super
  end

  def execute(command)
    before_execute.changed_and_notify(self, command)
    last_status, outputs = @story.call(command)
    outputs.each do |out, err|
      on_execute_data.changed_and_notify(self, out, err)
      yield(out, err) if block_given?
    end
    after_execute.changed_and_notify(self, command, last_status)
    last_status
  end

  def story(&block)
    @story = block
  end

end
