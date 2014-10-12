=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.

Partially based on test-kitchen by Fletcher Nichol <fnichol@nichol.ca>
License: https://github.com/test-kitchen/test-kitchen/blob/459238b88c/LICENSE
=end

require 'test_helper'
require 'remote_exec/ssh'
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

class ErrorCounter
  attr_reader :errors
  def on_error(method, *args)
    @errors ||= {}
    @errors[method] ||= 0
    @errors[method] += 1
  end
  def on_connect_retry(*args)
    on_error(:on_connect_retry, *args)
  end
  def on_connect_fail(*args)
    on_error(:on_connect_fail, *args)
  end
end

class ExecutaDataHook < Struct.new(:object, :stdout, :stderr)
  attr_reader :results
  def initialize(*args)
    @results = []
    super
  end
  def update(*args)
    @results << self.class.new(*args)
  end
end

describe RemoteExec::Ssh do
  include Net::SSH::Test

  subject do
    RemoteExec::Ssh.allocate.tap do |ssh|
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
    let(:hook) { ExecutaDataHook.new }

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
        subject.on_execute_data.add_observer(hook, :update)
        subject.execute("echo test me") do |out, err|
          out.must_equal "test me\n"
          err.must_be_nil
        end.must_equal 0
        hook.results.must_equal([ExecutaDataHook.new(subject, "test me\n", nil)])
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
        subject.on_execute_data.add_observer(hook, :update)
        subject.execute("echo test me>&2") do |out, err|
          out.must_be_nil
          err.must_equal "test me\n"
        end.must_equal 0
        hook.results.must_equal([ExecutaDataHook.new(subject, nil, "test me\n")])
      end
    end

  end #execute

  describe "#execute methods" do
    let(:hook) { ExecutaDataHook.new }

    it "handles stdout" do
      subject.on_execute_data.add_observer(hook, :update)
      subject.send(:execute_on_stdout, :channel, "some text") do |stdout, stderr|
        stdout.must_equal("some text")
        stderr.must_be_nil
      end
      hook.results.must_equal([ExecutaDataHook.new(subject, "some text", nil)])
    end

    it "handles stderr" do
      subject.on_execute_data.add_observer(hook, :update)
      subject.send(:execute_on_stderr, :channel, 1, "some text") do |stdout, stderr|
        stdout.must_be_nil
        stderr.must_equal("some text")
      end
      hook.results.must_equal([ExecutaDataHook.new(subject, nil, "some text")])
    end

    it "does not handle extended data other then stderr" do
      subject.on_execute_data.add_observer(hook, :update)
      lambda {
        subject.send(:execute_on_stderr, :channel, 666, "some text")
      }.must_raise(RuntimeError, "Unsupported SSH extended_data type: 666")
      hook.results.must_be_empty
    end

  end #execute methods

  describe "#establish_connection" do
    it "does connect" do
      Net::SSH.unstub(:start)
      Net::SSH.stubs(:start).returns(connection)
      subject.send(:establish_connection).must_equal(connection)
    end
  end

  describe "exception in establishing connection" do

    [
      Errno::EACCES, Errno::EADDRINUSE, Errno::ECONNREFUSED,
      Errno::ECONNRESET, Errno::ENETUNREACH, Errno::EHOSTUNREACH,
      Net::SSH::Disconnect
    ].each do |klass|
      describe "raising #{klass}" do

        before do
          @error_counter = ErrorCounter.new
          Net::SSH.unstub(:start)
          Net::SSH.stubs(:start).raises(klass)
          subject.instance_variable_set(:@ssh, nil)
          subject.options[:ssh_retries] = 2
        end

        it "reraises the #{klass} exception" do
          subject.stubs(:sleep)
          proc { subject.send(:establish_connection) }.must_raise klass
        end

        it "sleeps for 1 second between retries" do
          subject.expects(:sleep).with(1).twice
          begin
            subject.send(:establish_connection)
          rescue
          end
        end

        it "calls hooks on retry/fail ':ssh_retries' times" do
          subject.stubs(:sleep)
          subject.on_connect_retry.add_observer(@error_counter, :on_connect_retry)
          subject.on_connect_fail.add_observer(@error_counter, :on_connect_fail)
          begin
            subject.send(:establish_connection)
          rescue
          end
          @error_counter.errors.must_equal({:on_connect_retry=>2, :on_connect_fail=>1})
        end

      end
    end

  end #"exception in establishing connection"

  describe "#handle_exception_retry" do
    it "does decrease reties count" do
      subject.instance_variable_set(:@retries, 2)
      subject.send(:handle_exception_retry, "exception_test")
      subject.instance_variable_get(:@retries).must_equal(1)
      subject.send(:handle_exception_retry, "exception_test")
      subject.instance_variable_get(:@retries).must_equal(0)
      lambda {
        subject.send(:handle_exception_retry, "exception_test")
      }.must_raise(RuntimeError, "exception_test")
      subject.instance_variable_get(:@retries).must_equal(0)
    end
  end

end
