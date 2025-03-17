# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCable::MeasurmentCollectorTest < Minitest::Test
  include Yabeda::TestHelpers
  include ActionCable::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  class TestChannel < ActionCable::Channel::Base
  end

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

    @measurment_collector = Yabeda::ActionCable::MeasurmentCollector.new(
      config: Yabeda::ActionCable.config
    )
  end

  def test_that_measure_broadcasts_a_message
    assert_broadcasts Yabeda::ActionCable.config.stream_name, 1 do
      @measurment_collector.measure
    end
  end

  def test_that_collect_measurment_reports_to_yabeda
    travel_to Time.new(2025, 3, 17, 12, 0, 0) do
      latency = 0.13

      payload = {
        "sent_at" => Time.now.to_f - latency
      }

      ActionCable.server.connections << Object.new
      ActionCable.server.connections << Object.new
      ActionCable.server.connections << Object.new

      assert_yabeda_gauge_updated "actioncable.connection_count", 3 do
        assert_yabeda_histogram_measured "actioncable.pubsub_latency", latency, delta: 0.01 do
          @measurment_collector.collect_measurment(payload)
        end
      end
    end
  end

  # Needed for ActionCable::TestHelper to work
  def _assert_nothing_raised_or_warn(_assertion)
    yield
  end
end
