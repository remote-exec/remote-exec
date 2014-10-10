=begin
Copyright 2014 Michal Papis <mpapis@gmail.com>

See the file LICENSE for copying permission.
=end

require 'ruby/hooks'
require "remote/exec/base"

class Remote::Exec::Base
  extend Ruby::Hooks::InstanceHooks

  define_hook :before_connect
  define_hook :on_connect_retry
  define_hook :on_connect_fail
  define_hook :after_connect
  define_hook :before_shutdown
  define_hook :before_execute
  define_hook :on_execute_data
  define_hook :after_execute
end
