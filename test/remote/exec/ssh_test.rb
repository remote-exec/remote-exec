require 'test_helper'
require 'remote/exec/ssh'
require 'etc'

class Remote::Exec::TestSsh < MiniTest::Unit::TestCase
  def setup
    @test = Remote::Exec::Ssh
  end

  def test_true
    test_command = "true"
    local = @test.new("localhost", Etc.getlogin)
    called = 0
    status =
    local.execute(test_command) do |out, err|
      called+=1
    end
    assert_equal 0, called
    assert_equal 0, status
  end

  def test_false
    test_command = "false"
    local = @test.new("localhost", Etc.getlogin)
    called = 0
    status =
    local.execute(test_command) do |out, err|
      called+=1
    end
    assert_equal 0, called
    assert_equal 1, status
  end

  def test_echo_test
    test_command = "echo test"
    local = @test.new("localhost", Etc.getlogin)
    called = 0
    status =
    local.execute(test_command) do |out, err|
      assert_equal out.strip, "test"
      assert_equal err, nil
      called+=1
    end
    assert_equal 1, called
    assert_equal 0, status
  end
end
