# frozen_string_literal: true

require_relative "action_cable/version"

require "yabeda"
require "action_cable"
require "active_support/notifications"

require "yabeda/action_cable/config"
require "yabeda/action_cable/measurment_collector"
require "yabeda/action_cable/channel_concern"
require "yabeda/action_cable/railtie"

module Yabeda
  module ActionCable
    class Error < StandardError; end

    class << self
      MUTEX = Mutex.new

      def installed?
        yabeda_configured? && subscirbed? && channel_concern_included?
      end

      def install!
        configure_yabeda!
        subscribe!
        include_channel_concern!
      end

      def stream_name
        config.stream_name
      end

      def measure
        measurment_collector.measure
      end

      def collect_measurment(payload)
        measurment_collector.collect_measurment(payload)
      end

      def configure(&block)
        raise ArgumentError, "Block is required" unless block_given?

        config.tap do |cfg|
          block.call(cfg)
        end
      end

      def config
        return @config if defined?(@config)

        MUTEX.synchronize do
          @config ||= Config.new
        end
      end

      def reset!
        unsubscribe!
        config.reset!
      end

      private

        attr_accessor :subscribers

        def configure_yabeda!
          Yabeda.group :actioncable do
            Yabeda.configure do
              histogram :pubsub_latency do
                comment "The time it takes for a message to go through the " \
                        "PubSub backend (e.g. Redis, SolidQueue, Postgres)"
                unit :seconds
                buckets Yabeda::ActionCable.config.buckets_for(:pubsub_latency)
              end

              histogram :broadcast_duration do
                comment "The time it takes to broadcast a message"
                unit :seconds
                buckets Yabeda::ActionCable.config.buckets_for(:broadcast_duration)
              end

              histogram :transmission_duration do
                comment "The time it takes to write a message to a WebSocket"
                unit :seconds
                buckets Yabeda::ActionCable.config.buckets_for(:transmission_duration)
              end

              histogram :action_execution_duration do
                comment "The time it takes to perform an invoked action"
                unit :seconds
                buckets Yabeda::ActionCable.config.buckets_for(:action_execution_duration)
              end

              counter :confirmed_subscriptions,
                      comment: "Number of confirmed ActionCable subscriptions"

              counter :rejected_subscriptions,
                      comment: "Number of confirmed ActionCable subscriptions"

              gauge :connection_count,
                    comment: "Number of open WebSocket connections",
                    aggregation: :sum

              counter :allocations_during_action,
                      comment: "Number of allocated objects during the invoication of an action"
            end
          end
        end

        def yabeda_configured?
          Yabeda.groups.include?(:actioncable)
        end

        def subscribe!
          unsubscribe!

          subscribers.push(
            ActiveSupport::Notifications.monotonic_subscribe("perform_action.action_cable") do |event|
              Yabeda.actioncable.action_execution_duration.measure(
                config.tags_for(:action_execution_duration).merge(
                  channel: event.payload[:channel_class].name,
                  action: event.payload[:action]
                ),
                event.duration / 1000.0
              )

              Yabeda.actioncable.allocations_during_action.increment(
                config.tags_for(:allocations_during_action).merge(
                  channel: event.payload[:channel_class].name,
                  action: event.payload[:action]
                ),
                by: event.allocations
              )
            end
          )

          subscribers.push(
            ActiveSupport::Notifications.monotonic_subscribe("transmit.action_cable") do |event|
              Yabeda.actioncable.transmission_duration.measure(
                config.tags_for(:transmission_duration).merge(
                  channel: event.payload[:channel_class].name
                ),
                event.duration / 1000.0
              )
            end
          )

          subscribers.push(
            ActiveSupport::Notifications.monotonic_subscribe("transmit_subscription_confirmation.action_cable") do |event|
              Yabeda.actioncable.confirmed_subscriptions.increment(
                config.tags_for(:confirmed_subscriptions).merge(
                  channel: event.payload[:channel_class].name
                ),
                by: 1
              )
            end
          )

          subscribers.push(
            ActiveSupport::Notifications.monotonic_subscribe("transmit_subscription_rejection.action_cable") do |event|
              Yabeda.actioncable.rejected_subscriptions.increment(
                config.tags_for(:rejected_subscriptions).merge(
                  channel: event.payload[:channel_class].name
                ),
                by: 1
              )
            end
          )

          subscribers.push(
            ActiveSupport::Notifications.monotonic_subscribe("broadcast.action_cable") do |event|
              Yabeda.actioncable.broadcast_duration.measure(
                config.tags_for(:broadcast_duration),
                event.duration / 1000.0
              )
            end
          )
        end

        def unsubscribe!
          subscribers&.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) }
          self.subscribers = []
        end

        def subscirbed?
          subscribers.present?
        end

        def include_channel_concern!
          config.channel_class_name.constantize.include(ChannelConcern)
        end

        def channel_concern_included?
          config.channel_class_name.constantize.include?(ChannelConcern)
        end

        def measurment_collector
          return @measurment_collector if defined?(@measurment_collector)

          MUTEX.synchronize do
            @measurment_collector ||= MeasurmentCollector.new(config: config)
          end
        end
    end
  end
end
