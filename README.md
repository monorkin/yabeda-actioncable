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

#### pubsub_latency

  | | |
  |-|-|
  | Type | histogram |
  | Tags | - |
  | Description | The time it takes for a message to go through the PubSub backend (e.g. Redis, SolidQueue, Postgres) |

#### broadcast_duration

  | | |
  |-|-|
  | Type | histogram |
  | Tags | - |
  | Description | The time it takes to broadcast a message to the PubSub backend |

#### transmit_duration

  | | |
  |-|-|
  | Type | histogram |
  | Tags | channel |
  | Description | The time it takes to write a message to a WebSocket |

#### action_execution_duration

  | | |
  |-|-|
  | Type | histogram |
  | Tags | channel, action |
  | Description | The time it takes to perform an invoked action |

#### confirmed_subscriptions

  | | |
  |-|-|
  | Type | counter |
  | Tags | channel |
  | Description | Total number of confirmed subscriptions |

#### rejected_subscriptions

  | | |
  |-|-|
  | Type | counter |
  | Tags | channel |
  | Description | Total number of rejected subscriptions |

#### connection_count

  | | |
  |-|-|
  | Type | gauge |
  | Tags | - |
  | Description | Number of open WebSocket connections |

#### allocations_during_action

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
