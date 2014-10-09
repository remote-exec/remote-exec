require 'test_helper'
require 'remote/exec/fake'

class Remote::Exec::TestFake < MiniTest::Unit::TestCase
  def setup
    @test = Remote::Exec::Fake
  end

  def test_true
    test_command = "true"
    fake = @test.new
    fake.respond do |command|
      assert_equal command, test_command
      [0,[]]
    end
    called = 0
    status =
    fake.execute(test_command) do |out, err|
      called+=1
    end
    assert_equal 0, called
    assert_equal 0, status
  end

  def test_false
    test_command = "false"
    fake = @test.new
    fake.respond do |command|
      assert_equal command, test_command
      [1,[]]
    end
    called = 0
    status =
    fake.execute(test_command) do |out, err|
      called+=1
    end
    assert_equal 0, called
    assert_equal 1, status
  end

  def test_echo_test
    test_command = "echo test"
    fake = @test.new
    fake.respond do |command|
      assert_equal command, test_command
      [0,[["test\n",nil]]]
    end
    called = 0
    status =
    fake.execute(test_command) do |out, err|
      assert_equal out, "test\n"
      assert_equal err, nil
      called+=1
    end
    assert_equal 1, called
    assert_equal 0, status
  end
end
