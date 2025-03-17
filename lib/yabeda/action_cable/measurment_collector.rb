# frozen_string_literal: true

require "active_support/core_ext/numeric/time"

module Yabeda
  module ActionCable
    class MeasurmentCollector
      attr_reader :config
      attr_accessor :last_collected_at

      def initialize(config:)
        @config = config
        @mutex = Mutex.new
      end

      def measure
        ::ActionCable.server.broadcast(stream_name, measurment_payload)
      end

      def stream_name
        config.stream_name
      end

      def measurment_payload
        {
          sent_at: Time.now.to_f
        }
      end

      def collect_measurment(payload)
        return if on_cooldown?

        run_unless_already_running do
          self.last_collected_at = Time.now

          measure_pubsub_latency(payload)
        end
      end

      def on_cooldown?
        last_collected_at&.after?(cooldown_period.ago)
      end

      def cooldown_period
        config.collection_cooldown_period
      end

      private

        attr_reader :mutex

        def run_unless_already_running
          lock_ackquired = mutex.try_lock
          return unless lock_ackquired

          yield
        ensure
          mutex.unlock if lock_ackquired
        end

        def measure_pubsub_latency(payload)
          sent_at = payload["sent_at"] || raise(ArgumentError, "Payload must contain 'sent_at' key")
          pubsub_latency = Time.now.to_f - sent_at
          return unless pubsub_latency.positive? || pubsub_latency.zero?

          Yabeda.actioncable.pubsub_latency.measure({}, pubsub_latency)
        end
    end
  end
end
