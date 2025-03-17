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
        ::ActionCable.server.broadcast(config.stream_name, measurment_payload)
      end

      def collect_measurment(payload)
        return if on_cooldown?

        run_unless_already_running do
          self.last_collected_at = Time.now

          measure_connection_count
          measure_pubsub_latency(payload)
        end
      end

      private

        attr_reader :mutex

        def measurment_payload
          {
            sent_at: Time.now.to_f
          }
        end

        def on_cooldown?
          last_collected_at&.after?(config.collection_cooldown_period.ago)
        end

        def run_unless_already_running
          lock_ackquired = mutex.try_lock
          return unless lock_ackquired

          yield
        ensure
          mutex.unlock if lock_ackquired
        end

        def measure_connection_count
          Yabeda.actioncable.connection_count.set({}, ::ActionCable.server.connections.length)
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
