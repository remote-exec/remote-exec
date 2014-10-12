require 'test_helper'
require 'remote_exec/local'

describe RemoteExec::Local do
  subject do
    RemoteExec::Local.new
  end

  it "runs true" do
    subject.execute("true").must_equal(0)
  end

  it "runs false" do
    subject.execute("false").must_equal(1)
  end

  it "runs echo test" do
    test_command = "echo test"
    @called = 0
    status =
    subject.execute(test_command) do |out, err|
      assert_equal out.strip, "test"
      assert_equal err, nil
      @called+=1
    end
    @called.must_equal(1)
    status.must_equal(0)
  end
end
