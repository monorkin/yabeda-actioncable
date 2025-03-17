# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCable::ChannelConcernTest < ActionCable::Channel::TestCase
  class TestChannel < ActionCable::Channel::Base
    include Yabeda::ActionCable::ChannelConcern
  end

  def setup
    Yabeda::ActionCable.reset!
  end

  tests TestChannel

  def test_mixin_opens_stream_on_subscribe
    subscribe
    assert subscription.confirmed?
    assert_has_stream Yabeda::ActionCable.config.stream_name
  end
end
