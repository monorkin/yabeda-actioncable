# frozen_string_literal: true

module Yabeda::TestHelpers
  def assert_yabeda_gauge_updated(name, value, **options, &block)
    _before, after = _fetch_yabeda_test_measurments(:gauges, name, options[:tagged], &block)

    if options[:delta]
      assert_in_delta value, after, options[:delta],
                      "Expected gauge #{name} to be updated to #{value.inspect} with a delta " \
                      "of #{options[:delta]}, but it was #{after.inspect}"
    else
      assert_equal value, after, "Expected gauge #{name} to be updated to #{value.inspect}, but it was #{after.inspect}"
    end
  end

  def assert_yabeda_counter_incremented(name, **options, &block)
    before, after = _fetch_yabeda_test_measurments(:counters, name, options[:tagged], &block)

    case options
    in { by: value }
      delta = (after || 0) - (before || 0)
      if options[:delta]
        assert_in_delta value, delta, options[:delta],
          "Expected gauge #{name} to be incremented by #{delta.inspect} with a delta of #{options[:delta]}, but it was #{delta.inspect}"
      else
        assert_equal value, delta,
          "Expected counter #{name} to be incremented by #{value.inspect}, but it was incremented by #{delta.inspect}"
      end
    in { to: value}
      if options[:delta]
        assert_in_delta value, after, options[:delta],
          "Expected counter #{name} to be incremented to #{value.inspect} with a delta of #{options[:delta]}, but it was incremented to #{after.inspect}"
      else
        assert_equal value, after,
          "Expected counter #{name} to be incremented to #{value.inspect}, but it was incremented to #{after.inspect}"
      end
    end
  end

  def assert_yabeda_histogram_measured(name, value, **options, &block)
    _before, after = _fetch_yabeda_test_measurments(:histograms, name, options[:tagged], &block)

    if options[:delta]
      refute_nil after, "Expected histogram #{name} to measure #{value.inspect} with a delta " \
                        "#{options[:delta]}, but no measurement occured"
      assert_in_delta value, after, options[:delta],
                      "Expected histogram #{name} to measure #{value.inspect} with a delta " \
                      "of #{options[:delta]}, but it measured #{after.inspect}"
    else
      assert_equal value, after, "Expected histogram #{name} to measure #{value.inspect}, but it measured #{after.inspect}"
    end
  end

  def _fetch_yabeda_test_measurments(type, name, tags, &block)
    metric = Yabeda.metrics.fetch(name.gsub(".", "_"))
    measurements = Yabeda::TestAdapter.instance.public_send(type)[metric]
    tags ||= {}
    before = measurements[tags]

    block.call

    after = measurements[tags]

    [ before, after ]
  end
end
