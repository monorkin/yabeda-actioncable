# frozen_string_literal: true

module Yabeda
  module ActionCable
    MAJOR_VERSION = 0
    MINOR_VERSION = 2
    PATCH_VERSION = 0
    PRERELEASE_VERSION = nil

    VERSION = [
      MAJOR_VERSION,
      MINOR_VERSION,
      PATCH_VERSION,
      PRERELEASE_VERSION
    ].reject(&:nil?).join(".").freeze
  end
end
