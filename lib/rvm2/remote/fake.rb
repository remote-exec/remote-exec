class Rvm2::Shell::Runner::Fake
  attr_reader :last_status

  def execute(command)
    @last_status, outputs = @respond.call(command)
    outputs.each do |out, err|
      yield(out, err)
    end
    @last_status
  end

  def respond(&block)
    @respond = block
  end
end
