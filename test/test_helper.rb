# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "yabeda/actioncable"
require "action_cable/channel/test_case"

ActionCable.server.config.cable = { adapter: "test" }

require "minitest/autorun"
