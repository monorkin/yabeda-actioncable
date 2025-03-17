# frozen_string_literal: true

require "rails/railtie"
require "yabeda/railtie"

module Yabeda
  module ActionCable
    # :nodoc:
    class Railtie < ::Rails::Railtie
      initializer "yabeda-actioncable.metrics" do
        ::Yabeda::ActionCable.install!
      end
    end
  end
end
