# Yabeda::ActionCable

A [Yabeda](https://github.com/yabeda-rb/yabeda) plugin for collecting metrics from [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html).

## Installation

### Add the gem

Add this gem to your application's Gemfile by executing:

```bash
bundle add yabeda-actioncable
```

or by adding the following line to your Gemfile:

```ruby
gem "yabeda-actioncable"
```

### Periodically collect metrics

Periodically run `Yabeda::ActionCable.measure` via some mechanism

Cron example:

```crontab
# The maximum resolution you can achive with cron is 1 minute
* * * * * bin/rails runner "Yabeda::ActionCable.measure"
```

[SolidQueue](https://github.com/rails/solid_queue) example:

```yaml
# config/recurring.yml

yabeda_actioncable:
  command: "Yabeda::ActionCable.measure"
  schedule: every 60 seconds
```


## Configuration

```ruby
Yabeda::ActionCable.configure do |config|
  # The default buckets value for histograms
  # This determines the resolution of your measurements
  config.default_buckets = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]

  # The default buckets value can be overridden for each metric
  # This allows you to capture measurements with more or less resolution if needed
  config.buckets[:pubsub_latency] = [1, 2, 3]

  # How often to collect metrics
  # Set this to whatever you configured in Cron or SolidQueue
  config.collection_period = 60.seconds

  # For how long to ignore incoming measurements after a measurement was collected
  # This defaults to 0.5 * collection_period, but can be overridden
  # The purpose of this cool down is to debounce measurements - it prevents the 
  # same measurement from being collected multiple times
  config.collection_cooldown_period = 30.seconds

  # On which channel class to collect metrics
  # It's recommended to set this to a class that all your other channels inherit from
  config.channel_class_name = "ApplicationCable::Channel"

  # Name of the stream used to broadcast measurements to and collect them from
  config.stream_name = "yabeda.action_cable.metrics"
end
```

## Metrics

### pubsub_latency

| | |
|-|-|
| Type | histogram |
| Tags | - |
| Description | The time it takes for a message to go through the PubSub backend (e.g. Redis, SolidQueue, Postgres) |

*This is a very good health indicator for your PubSub backend (e.g. Redis, SolidQueue, Postgres)*

The larger the latency the longer it takes the backend to deliver messages to ActionCable.
A sudden spike may indicate resource contention of some kind (CPU, Memory, Network, ...).

![plot_of_the_pubsub_latency](https://github.com/user-attachments/assets/d7c0a3b7-ce98-424d-8954-7f645d60f0e9)

### broadcast_duration

| | |
|-|-|
| Type | histogram |
| Tags | - |
| Description | The time it takes to broadcast a message to the PubSub backend |

![plot_of_the_broadcast_duration](https://github.com/user-attachments/assets/0fdd9f3c-0704-4d63-a269-c48ea1d63b1a)

![plot_of_the_number_of_broadcasts](https://github.com/user-attachments/assets/6792a457-c133-4cbc-a4ac-1ecc3250a7dc)

### transmit_duration

| | |
|-|-|
| Type | histogram |
| Tags | channel |
| Description | The time it takes to write a message to a WebSocket |

![plot_of_the_transmit_duration](https://github.com/user-attachments/assets/9eba9326-a74f-4e58-b422-fb943a15e0e9)

![plot_of_the_number_of_transmissions](https://github.com/user-attachments/assets/1b04da8a-9b9b-4e62-a89c-ed301f9cb606)

### action_execution_duration

| | |
|-|-|
| Type | histogram |
| Tags | channel, action |
| Description | The time it takes to perform an invoked action |

This metric directly detirmines your throughput and how much you'll have to scale to accomodate traffic.
The longer the duration the fewer messages your app can process before they start queueing up.

The overall average duration is the most important metric for scaling. 
You can use it in [Little's law](https://en.wikipedia.org/wiki/Little%27s_law) 
to figure out how many instances you need to handle the current amount of traffic without messages queuing up.

![plot_of_the_overall_action_execution_duration_metrics](https://github.com/user-attachments/assets/d42d022f-6957-4b80-8045-78452451fb00)

The number of actions executed can also be used for scaling - depending on your infrastructure and code 
you may know approximately how many instances you need to perform a given number of actions.

![plot_of_the_number_of_invoked_actions](https://github.com/user-attachments/assets/18384f1d-364b-47e0-8100-b26fea433ade)

The duration can also be broken down by channel and action which can help you pinpoint problems
in the application logic of certain actions.

![plot_of_the_action_execution_duration_broken_down_by_channel_action](https://github.com/user-attachments/assets/623752f4-b1f3-4ca9-8de9-0ad454b90ef5)

### confirmed_subscriptions

| | |
|-|-|
| Type | counter |
| Tags | channel |
| Description | Total number of confirmed subscriptions |

### rejected_subscriptions

| | |
|-|-|
| Type | counter |
| Tags | channel |
| Description | Total number of rejected subscriptions |

### connection_count

| | |
|-|-|
| Type | gauge |
| Tags | - |
| Description | Number of open WebSocket connections |

*This is as a very good service health indicator*

Large sudden drops may indicate a problem that directly impacts users.
While large sudden spikes coupled with performance problems may help you pinpoint the Connection object as the source of the problem.

It can also be used for preemptive scaling - depending on your infrastructure and code you may know approximately how many instances
you need to serve a given amount of users.

![different_plots_of_the_number_of_connections](https://github.com/user-attachments/assets/87804bcb-42dc-4adc-be66-adbaacb1d3c4)

In addition to plotting just the count you can also plot the number of connections per instance which is useful if you are experiancing 
problems just on one instance.

### allocations_during_action

| | |
|-|-|
| Type | counter |
| Tags | channel, action |
| Description | Number of allocated objects during the invoication of an action |

This can be helpful while investigating memory related problems, but the metric is imprecise
and requires some deduction to be useful.

The data can be displayed as a heat map that plots actions vs time vs number of allocations.
In other words, deep red segments represent when an action allocated a lot of objects.

![heat_map_of_object_allocations](https://github.com/user-attachments/assets/845d12e2-1452-4e3e-9d6a-cf967fe8a647)

Due to how [ActiveSupport::Notification::Event](https://api.rubyonrails.org/classes/ActiveSupport/Notifications/Event.html#method-i-allocations) captures the number of allocations you may experience some "radiated heat" in your heat map.

If you have a short-running action that doesn't allocate a lot of object and a long-running
one that does, both running at the same time in the same process, you'll see that the short-running 
action also become "hot" in the heat map.

![heat_map_of_object_allocations_with_radiated_heat_highlighted](https://github.com/user-attachments/assets/3e8f4d85-2559-4f6a-ab0a-b0ffe895d7e9)

In the example above only one action allocated a lot of objects, but most actions running at the
same time also appear "hot" in the graph.

This happens because the short-running actions measure the number of allocations before and 
after they execute and report the difference. If another action is allocating a lot of 
objects at the same time then the measurement of the short-running action will include those 
objects which artificially inflates the number of allocations it reports.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/monorkin/yabeda-actioncable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
