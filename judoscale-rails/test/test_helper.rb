# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-rails"

require "minitest/autorun"
require "minitest/spec"

module Judoscale::Test
end

# Load shared test helpers from judoscale-ruby.
Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

require "rails"
class TestRailsApp < Rails::Application
  config.secret_key_base = "test-secret"
  config.eager_load = false
  config.logger = ::Logger.new(LogHelpers.log_io)
  routes.append do
    root to: proc {
      [200, {"Content-Type" => "text/plain"}, ["Hello World"]]
    }
  end
  initialize!
end

Minitest::Test.include(Judoscale::Test)
