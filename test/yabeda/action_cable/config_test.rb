# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCable::ConfigTest < Minitest::Test
  def test_that_collection_cooldown_period_is_automatically_detirmined_unless_manually_set
    config = Yabeda::ActionCable::Config.new

    config.collection_period = 60.seconds
    config.collection_cooldown_period = nil
    assert_equal 30.seconds, config.collection_cooldown_period

    config.collection_cooldown_period = 50.seconds
    assert_equal 50.seconds, config.collection_cooldown_period
  end

  def test_that_buckets_for_metric_returns_default_buckets_if_no_custom_buckets_defined
    config = Yabeda::ActionCable::Config.new

    assert_equal(
      config.default_buckets,
      config.buckets_for(:some_metric)
    )

    config.buckets[:some_metric] = [1, 2, 3]

    assert_equal(
      [1, 2, 3],
      config.buckets_for(:some_metric)
    )
  end
end
