# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "yabeda/actioncable"
require "yabeda/test_adapter"
require "action_cable/channel/test_case"
require "active_support/testing/time_helpers"
require "warning"

require_relative "yabeda_test_helpers"

ActionCable.server.config.tap do |config|
  config.cable = { adapter: "test" }
  config.logger = Logger.new(IO::NULL)
end

Yabeda.register_adapter(:test, Yabeda::TestAdapter.instance)

Warning.ignore(/method redefined/)

require "minitest/focus"
require "minitest/autorun"
