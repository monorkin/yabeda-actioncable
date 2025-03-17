# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCable::RailtieTest < Minitest::Test
  class TestChannel < ActionCable::Channel::Base
  end

  def setup
    super
    Yabeda::ActionCable.config.reset!
  end

  def teardown
    ActiveSupport::Notifications.notifier = ActiveSupport::Notifications::Fanout.new
    super
  end

  def test_that_the_railtie_installs_yabeda_actioncable
    Yabeda::ActionCable.configure do |config|
      config.channel_class_name = TestChannel.name
    end

    refute TestChannel.include?(Yabeda::ActionCable::ChannelConcern)

    Yabeda::ActionCable::Railtie.instance.run_initializers

    assert TestChannel.include?(Yabeda::ActionCable::ChannelConcern)
  end
end
