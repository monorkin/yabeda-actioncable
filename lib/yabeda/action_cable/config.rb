# frozen_string_literal: true

require "active_support/core_ext/numeric/time"

module Yabeda
  module ActionCable
    class Config
      DEFAULT_BUCKETS = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10].freeze
      DEFAULT_STREAM_NAME = "yabeda.action_cable.metrics"
      DEFAULT_COLLECTION_PERIOD = 60.seconds.freeze
      DEFAULT_CHANNEL_CLASS_NAME = "ApplicationCable::Channel"

      attr_accessor :default_buckets,
                    :buckets,
                    :stream_name,
                    :collection_period,
                    :channel_class_name
      attr_writer :collection_cooldown_period

      def initialize
        reset!
      end

      def reset!
        @default_buckets = DEFAULT_BUCKETS.dup
        @buckets = {}
        @stream_name = DEFAULT_STREAM_NAME
        @collection_period = DEFAULT_COLLECTION_PERIOD.dup
        @collection_cooldown_period = nil
        @channel_class_name = DEFAULT_CHANNEL_CLASS_NAME
      end

      def collection_cooldown_period
        if @collection_cooldown_period.nil?
          collection_period / 2.0
        else
          @collection_cooldown_period
        end
      end

      def buckets_for(metric)
        buckets[metric] || default_buckets
      end
    end
  end
end
