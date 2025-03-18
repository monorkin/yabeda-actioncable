# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCable::RailtieTest < Minitest::Test
  class TestChannel < ActionCable::Channel::Base
  end

  def setup
    super
    Yabeda::ActionCable.reset!
  end

  def test_that_the_railtie_installs_yabeda_actioncable
    Yabeda::ActionCable.configure do |config|
      config.channel_class_name = TestChannel.name
    end

    refute Yabeda::ActionCable.installed?

    Yabeda::ActionCable::Railtie.instance.run_initializers

    assert Yabeda::ActionCable.installed?
  end
end
