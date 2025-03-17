# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCable::MeasurmentCollectorTest < Minitest::Test
  include ActionCable::TestHelper

  def setup
    super

    Yabeda::ActionCable.config.reset!

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
    Yabeda::ActionCable.configure do |config|
      config.collection_cooldown_period = 60.second
    end
  end

  # Needed for ActionCable::TestHelper to work
  def _assert_nothing_raised_or_warn(_assertion)
    yield
  end
end
