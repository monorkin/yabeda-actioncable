# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCableTest < ActionCable::Channel::TestCase
  include Yabeda::TestHelpers
  include ActionCable::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  class TestChannel < ActionCable::Channel::Base
    def subscribed
      reject if params[:reject]
    end

    def sleep_test(data)
      sleep data.fetch("duration")
    end

    def allocate_test(data)
      data.fetch("count").times.map { Object.new }
    end

    def transmit_test(data)
      transmit({ message: data.fetch("message") })
    end
  end

  tests TestChannel

  def setup
    super

    Yabeda.reset!
    Yabeda::TestAdapter.instance.reset!
    Yabeda.register_adapter(:test, Yabeda::TestAdapter.instance)

    Yabeda::ActionCable.reset!
    Yabeda::ActionCable.configure do |config|
      config.channel_class_name = TestChannel.name
    end

    Yabeda::ActionCable.install!
    Yabeda.configure!
  end

  def test_that_it_has_a_version_number
    refute_nil ::Yabeda::ActionCable::VERSION
  end

  def test_that_broadcasts_get_measured
    assert_yabeda_histogram_measured "actioncable.broadcast_duration", 0.01, delta: 0.1 do
      ::ActionCable.server.broadcast("test", { message: "Hello, Wolrd!" })
    end
  end

  def test_that_transmissios_get_measured
    message = "Hello, Wolrd!"
    tags = { channel: "Yabeda::ActionCableTest::TestChannel" }

    subscribe

    assert_yabeda_histogram_measured "actioncable.transmission_duration", 0.01, delta: 0.1, tagged: tags do
      perform :transmit_test, message: message
    end
  end

  def test_that_confirmed_subscribes_get_counted
    tags = { channel: "Yabeda::ActionCableTest::TestChannel" }

    assert_yabeda_counter_incremented "actioncable.confirmed_subscriptions", by: 1, tagged: tags do
      subscribe
    end
  end

  def test_that_rejected_subscribes_get_counted
    tags = { channel: "Yabeda::ActionCableTest::TestChannel" }

    assert_yabeda_counter_incremented "actioncable.rejected_subscriptions", by: 1, tagged: tags do
      subscribe(reject: true)
    end
  end

  def test_that_action_execution_time_gets_measured
    duration = 0.15
    tags = { channel: "Yabeda::ActionCableTest::TestChannel", action: :sleep_test }

    subscribe

    assert_yabeda_histogram_measured "actioncable.action_execution_duration", duration, delta: 0.05, tagged: tags do
      perform :sleep_test, duration: duration
    end
  end

  def test_that_allocations_during_action_get_counted
    count = 1000
    tags = { channel: "Yabeda::ActionCableTest::TestChannel", action: :allocate_test }

    subscribe

    assert_yabeda_counter_incremented "actioncable.allocations_during_action", by: count, delta: 100, tagged: tags do
      perform :allocate_test, count: count
    end
  end

  # Needed for ActionCable::TestHelper to work
  def _assert_nothing_raised_or_warn(_assertion)
    yield
  end
end
