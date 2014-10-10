=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.

Partially based on test-kitchen by Fletcher Nichol <fnichol@nichol.ca>
License: https://github.com/test-kitchen/test-kitchen/blob/459238b88c/LICENSE
=end

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

  it "sets default variables" do
    subject.send(:initialize, 1, 2, 3)
    subject.host.must_equal 1
    subject.user.must_equal 2
    subject.options.must_equal 3
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
      subject.execute("true").must_equal 0
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
      subject.execute("false").must_equal 1
    end
  end

  it "executes echo test" do
    story do |session|
      channel = session.opens_channel
      channel.sends_request_pty
      channel.sends_exec "echo test me"
      channel.gets_data("test me\n")
      channel.gets_exit_status(0)
      channel.gets_close
      channel.sends_close
    end

    assert_scripted do
      subject.execute("echo test me") do |out, err|
        out.must_equal "test me\n"
        err.must_be_nil
      end.must_equal 0
    end
  end

  it "executes echo test>&2" do
    story do |session|
      channel = session.opens_channel
      channel.sends_request_pty
      channel.sends_exec "echo test me>&2"
      channel.gets_extended_data("test me\n")
      channel.gets_exit_status(0)
      channel.gets_close
      channel.sends_close
    end

    assert_scripted do
      subject.execute("echo test me>&2") do |out, err|
        out.must_be_nil
        err.must_equal "test me\n"
      end.must_equal 0
    end
  end

end
