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
    Remote::Exec::Ssh.allocate.tap do |ssh|
      ssh.instance_variable_set(:@ssh, connection)
      ssh.instance_variable_set(:@options, {})
    end
  end

  describe "#initialize" do

    it "sets default variables" do
      subject.send(:initialize, 1, 2, 3)
      subject.hostname.must_equal 1
      subject.username.must_equal 2
      subject.options.must_equal 3
    end

    it "executes initialize block once" do
      calls = 0
      subject.send(:initialize, 1, 2, 3) { calls+=1 }
      calls.must_equal 1
    end

  end #initialize

  describe "#execute" do

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

  end #execute

  describe "#establish_connection" do
    it "does connection" do
      Net::SSH.unstub(:start)
      Net::SSH.stubs(:start).returns(connection)
      subject.establish_connection.must_equal(connection)
    end
  end

  describe "establishing a connection" do

    [
      Errno::EACCES, Errno::EADDRINUSE, Errno::ECONNREFUSED,
      Errno::ECONNRESET, Errno::ENETUNREACH, Errno::EHOSTUNREACH,
      Net::SSH::Disconnect
    ].each do |klass|
      describe "raising #{klass}" do

        before do
          Net::SSH.unstub(:start)
          Net::SSH.stubs(:start).raises(klass)
          subject.instance_variable_set(:@ssh, nil)
          subject.options[:ssh_retries] = 3
          subject.stubs(:sleep)
        end

        it "reraises the #{klass} exception" do
          proc { subject.execute("nope") }.must_raise klass
        end

        it "attempts to connect ':ssh_retries' times" do
          begin
            subject.establish_connection
          rescue
          end

#          logged_output.string.lines.select { |l|
#            l =~ debug_line("[SSH] opening connection to me@foo:22<{:ssh_retries=>3}>")
#          }.size.must_equal subject.options[:ssh_retries]
        end

        it "sleeps for 1 second between retries" do
          subject.unstub(:sleep)
          subject.expects(:sleep).with(1).twice

          begin
            subject.establish_connection
          rescue
          end
        end

        it "logs the first 2 retry failures on info" do
          begin
            subject.establish_connection
          rescue
          end

#          logged_output.string.lines.select { |l|
#            l =~ info_line_with("[SSH] connection failed, retrying ")
#          }.size.must_equal 2
        end

        it "logs the last retry failures on warn" do
          begin
            subject.establish_connection
          rescue
          end

#          logged_output.string.lines.select { |l|
#            l =~ warn_line_with("[SSH] connection failed, terminating ")
#          }.size.must_equal 1
        end
      end
    end

  end #"establishing a connection"

end
