# frozen_string_literal: true

module Yabeda
  module ActionCable
    module ChannelConcern
      extend ActiveSupport::Concern

      included do
        after_subscribe do
          stream_from(
            Yameda::ActionCable.config.stream_name,
            proc do |json|
              payload = ActiveSupport::JSON.decode(json)
              Yabeda::ActionCable.collect_measurment(payload)
            end
          )
        end
      end
    end
  end
end
