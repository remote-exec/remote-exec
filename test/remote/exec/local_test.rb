require 'test_helper'
require 'remote/exec/local'

describe Remote::Exec::Local do
  subject do
    Remote::Exec::Local.new
  end

  it "runs true" do
    test_command = "true"
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
    called = 0
    status =
    subject.execute(test_command) do |out, err|
      assert_equal out.strip, "test"
      assert_equal err, nil
      called+=1
    end
    called.must_equal(1)
    status.must_equal(0)
  end
end
