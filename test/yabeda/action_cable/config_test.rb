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

    config.buckets[:some_metric] = [ 1, 2, 3 ]

    assert_equal(
      [ 1, 2, 3 ],
      config.buckets_for(:some_metric)
    )
  end

  def test_that_tags_for_metric_returns_default_tags_if_no_custom_tags_defined
    config = Yabeda::ActionCable::Config.new

    config.default_tags = { some: "tag" }

    assert_equal(
      config.default_tags,
      config.tags_for(:some_metric)
    )

    config.tags[:some_metric] = { another: "tag" }

    assert_equal(
      config.tags[:some_metric],
      config.tags_for(:some_metric)
    )
  end

  def test_enable_experimental_metrics_utilities
    config = Yabeda::ActionCable::Config.new

    refute config.experimental_metric_enabled?(:some_metric)

    config.enable_experimental_metric(:some_metric)

    assert config.experimental_metric_enabled?(:some_metric)

    config.disable_experimental_metric(:some_metric)

    refute config.experimental_metric_enabled?(:some_metric)
  end

  def test_that_reset_resets_all_values_to_their_defaults
    config = Yabeda::ActionCable::Config.new

    config.default_buckets = [ 1, 2, 3 ]
    config.buckets[:some_metric] = [ 4, 5, 6 ]
    config.default_tags = { some: "tag" }
    config.tags[:some_metric] = { another: "tag" }
    config.stream_name = "some_stream_name"
    config.collection_period = 100.seconds
    config.collection_cooldown_period = 80.seconds
    config.channel_class_name = "SomeChannel"
    config.enabled_experimental_metrics << :some_metric

    assert_equal([ 1, 2, 3 ], config.default_buckets)
    assert_equal([ 4, 5, 6 ], config.buckets[:some_metric])
    assert_equal({ some: "tag" }, config.default_tags)
    assert_equal({ another: "tag" }, config.tags[:some_metric])
    assert_equal("some_stream_name", config.stream_name)
    assert_equal(100.seconds, config.collection_period)
    assert_equal(80.seconds, config.collection_cooldown_period)
    assert_equal("SomeChannel", config.channel_class_name)
    assert_equal(Set[:some_metric], config.enabled_experimental_metrics)

    config.reset!

    assert_equal(Yabeda::ActionCable::Config::DEFAULT_BUCKETS, config.default_buckets)
    assert_nil(config.buckets[:some_metric])
    assert_equal({}, config.default_tags)
    assert_nil(config.tags[:some_metric])
    assert_equal(Yabeda::ActionCable::Config::DEFAULT_STREAM_NAME, config.stream_name)
    assert_equal(Yabeda::ActionCable::Config::DEFAULT_COLLECTION_PERIOD, config.collection_period)
    assert_equal(Yabeda::ActionCable::Config::DEFAULT_COLLECTION_PERIOD / 2, config.collection_cooldown_period)
    assert_equal(Yabeda::ActionCable::Config::DEFAULT_CHANNEL_CLASS_NAME, config.channel_class_name)
    assert_equal(Set.new, config.enabled_experimental_metrics)
  end
end
