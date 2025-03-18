# frozen_string_literal: true

require "test_helper"

class Yabeda::ActionCableTest < Minitest::Test
  include Yabeda::TestHelpers
  include ActionCable::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  def test_that_it_has_a_version_number
    refute_nil ::Yabeda::ActionCable::VERSION
  end

  # Needed for ActionCable::TestHelper to work
  def _assert_nothing_raised_or_warn(_assertion)
    yield
  end
end
