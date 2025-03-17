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
  end

  def assert_yabeda_histogram_measured(name, value, **options, &block)
    _before, after = _fetch_yabeda_test_measurments(:histograms, name, options[:tagged], &block)

    if options[:delta]
      assert_in_delta value, after, options[:delta],
                      "Expected gauge #{name} to be updated to #{value.inspect} with a delta " \
                      "of #{options[:delta]}, but it was #{after.inspect}"
    else
      assert_equal value, after, "Expected histogram #{name} to measure #{value.inspect}, but measured #{after.inspect}"
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
