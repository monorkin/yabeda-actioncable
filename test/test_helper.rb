# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "yabeda/actioncable"
require "action_cable/channel/test_case"

ActionCable.server.config.tap do |config|
  config.cable = { adapter: "test" }
  config.logger = Logger.new(IO::NULL)
end

require "minitest/autorun"
