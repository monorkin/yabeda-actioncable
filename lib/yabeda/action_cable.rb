# frozen_string_literal: true

require_relative "action_cable/version"

require "yabeda"
require "action_cable"
require "active_support/notifications"

require "yabeda/action_cable/config"
require "yabeda/action_cable/measurment_collector"
require "yabeda/action_cable/railtie"

module Yabeda
  module ActionCable
    MUTEX = Mutex.new

    extend self

    class Error < StandardError; end

    def install!
      Yabeda.configure do
        group :actioncable do
          histogram :pubsub_latency do
            comment "The time it takes for a message to go through the PubSub backend (e.g. Redis, SolidQueue, Postgres)"
            unit :seconds
            buckets config.buckets_for(:pubsub_latency)
          end

          histogram :broadcast_duration do
            comment "The time it takes to broadcast a message"
            unit :seconds
            buckets config.buckets_for(:broadcast_duration)
          end

          histogram :transmission_duration do
            comment "The time it takes to write a message to a WebSocket"
            unit :seconds
            buckets config.buckets_for(:transmission_duration)
          end

          histogram :action_execution_duration do
            comment "The time it takes to perform an invoked action"
            unit :seconds
            buckets config.buckets_for(:action_execution_duration)
          end

          counter :confirmed_subscription_count,
                  comment: "Number of confirmed ActionCable subscriptions"

          counter :rejected_subscription_count,
                  comment: "Number of confirmed ActionCable subscriptions"

          gauge :connection_count,
                comment: "Number of open WebSocket connections",
                aggregation: :sum
        end
      end

      Yabeda.collect do
        Yabeds.actioncable.connection_count.set({}, ActionCable.server.connections.length)
      end

      ActiveSupport::Notifications.subscribe "perform_action.action_cable" do |event|
        Yabeda.actioncable.action_execution_duration.measure(
          {
            channel: event.payload[:channel_class].name,
            action: event.payload[:action]
          },
          event.duration / 1000.0
        )
      end

      ActiveSupport::Notifications.subscribe "transmit.action_cable" do |event|
        Yabeda.actioncable.transmission_duration.measure(
          {
            channel: event.payload[:channel_class].name
          },
          event.duration / 1000.0
        )
      end

      ActiveSupport::Notifications.subscribe "transmit_subscription_confirmation.action_cable" do |event|
        Yabeda.actioncable.confirmed_subscription_count.increment(
          {
            channel: event.payload[:channel_class].name
          },
          by: 1
        )
      end

      ActiveSupport::Notifications.subscribe "transmit_subscription_rejection.action_cable" do |event|
        Yabeda.actioncable.rejected_subscription_count.increment(
          {
            channel: event.payload[:channel_class].name
          },
          by: 1
        )
      end

      ActiveSupport::Notifications.subscribe "broadcast.action_cable" do |event|
        Yabeda.actioncable.broadcast_duration.measure(
          {},
          event.duration / 1000.0
        )
      end

      config.channel_class_name.constantize.include(ChannelConcern)
    end

    def measure
      measurment_collector.measure
    end

    def collect_measurment(payload)
      measurment_collector.collect_measurment(payload)
    end

    def measurment_collector
      return @measurment_collector if defined?(@measurment_collector)

      MUTEX.synchronize do
        @measurment_collector ||= MeasurmentCollector.new(config: config)
      end
    end

    def configure(&block)
      raise ArgumentError, "Block is required" unless block_given?

      config.tap do |cfg|
        block.call(cfg)
      end
    end

    def config
      @config ||= Config.new
    end
  end
end
