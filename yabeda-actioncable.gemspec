# frozen_string_literal: true

require_relative "lib/yabeda/action_cable/version"

Gem::Specification.new do |spec|
  spec.name = "yabeda-actioncable"
  spec.version = Yabeda::ActionCable::VERSION
  spec.authors = ["Stanko K.R."]
  spec.email = ["stanko@stanko.io"]

  spec.summary = "Yabeda plugin for collecting ActionCable metrics"
  spec.description = <<~DESC
  DESC
  spec.homepage = "https://github.com/monorkin/yabeda-actioncable"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(
          *%w[
            bin/
            test/
            spec/
            features/
            .git
            .github
            .rubocop
            Gemfile
            CHANGELOG
            README
          ]
        )
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actioncable", ">= 7.2"
  spec.add_dependency "activesupport"
  spec.add_dependency "railties"
  spec.add_dependency "yabeda", "~> 0.8"

  spec.add_development_dependency "warning"
end
