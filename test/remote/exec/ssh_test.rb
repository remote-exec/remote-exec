require 'test_helper'
require 'remote/exec/ssh'
require 'net/ssh/test'

module Net
  module SSH
    module Test
      class Channel

        def sends_request_pty
          pty_data = ["xterm", 80, 24, 640, 480, "\0"]
          script.events << Class.new(Net::SSH::Test::LocalPacket) do
            def types
              if
                @type == 98 && @data[1] == "pty-req"
              then
                @types ||= [
                  :long, :string, :bool, :string,
                  :long, :long, :long, :long, :string
                ]
              else
                super
              end
            end
          end.new(:channel_request, remote_id, "pty-req", false, *pty_data)
        end

      end
    end
  end
end

describe Remote::Exec::Ssh do
  include Net::SSH::Test

  subject do
    Remote::Exec::Ssh.allocate.tap{|ssh| ssh.instance_variable_set(:@ssh, connection)}
  end

  it "executes true" do
    story do |session|
      channel = session.opens_channel
      channel.sends_request_pty
      channel.sends_exec "true"
      channel.gets_exit_status(0)
      channel.gets_close
      channel.sends_close
    end

    assert_scripted do
      test_command = "true"
      called = 0
      status =
      subject.execute(test_command) do |out, err|
        called+=1
      end
      assert_equal 0, called
      assert_equal 0, status
    end
  end

  it "executes false" do
    story do |session|
      channel = session.opens_channel
      channel.sends_request_pty
      channel.sends_exec "false"
      channel.gets_exit_status(1)
      channel.gets_close
      channel.sends_close
    end

    assert_scripted do
      test_command = "false"
      called = 0
      status =
      subject.execute(test_command) do |out, err|
        called+=1
      end
      assert_equal 0, called
      assert_equal 1, status
    end
  end

  it "executes echo test" do
    story do |session|
      channel = session.opens_channel
      channel.sends_request_pty
      channel.sends_exec "echo test me"
      channel.gets_data("test me")
      channel.gets_exit_status(0)
      channel.gets_close
      channel.sends_close
    end

    assert_scripted do
      test_command = "echo test me"
      called = 0
      status =
      subject.execute(test_command) do |out, err|
        assert_equal out.strip, "test me"
        assert_equal err, nil
        called+=1
      end
      assert_equal 1, called
      assert_equal 0, status
    end
  end
end
