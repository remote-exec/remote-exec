require 'test_helper'
require 'remote/exec/fake'

describe Remote::Exec::Fake do
  subject do
    Remote::Exec::Fake.new
  end

  it "runs true" do
    test_command = "true"
    subject.respond do |command|
      command.must_equal test_command
      [0,[]]
    end
    called = 0
    status =
    subject.execute(test_command) do |out, err|
      called+=1
    end
    called.must_equal(0)
    status.must_equal(0)
  end

  it "runs false" do
    test_command = "false"
    subject.respond do |command|
      command.must_equal test_command
      [1,[]]
    end
    called = 0
    status =
    subject.execute(test_command) do |out, err|
      called+=1
    end
    called.must_equal(0)
    status.must_equal(1)
  end

  it "runs echo test" do
    test_command = "echo test"
    subject.respond do |command|
      command.must_equal test_command
      [0,[["test\n",nil]]]
    end
    called = 0
    status =
    subject.execute(test_command) do |out, err|
      out.must_equal "test\n"
      err.must_be_nil
      called+=1
    end
    called.must_equal(1)
    status.must_equal(0)
  end
end
