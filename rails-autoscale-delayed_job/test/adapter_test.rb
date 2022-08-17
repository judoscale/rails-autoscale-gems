# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/report"

module RailsAutoscale
  describe DelayedJob do
    it "adds itself as an adapter with information to be reported to the Rails Autoscale API" do
      adapter = RailsAutoscale.adapters.detect { |adapter| adapter.identifier == :"rails-autoscale-delayed_job" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal RailsAutoscale::DelayedJob::MetricsCollector

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"rails-autoscale-delayed_job")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.delayed_job.enabled).must_equal true
      _(config.delayed_job.max_queues).must_equal 20
      _(config.delayed_job.queues).must_equal []
      _(config.delayed_job.track_busy_jobs).must_equal false

      RailsAutoscale.configure do |config|
        config.delayed_job.queues = %w[test drive]
        config.delayed_job.track_busy_jobs = true
      end

      _(config.delayed_job.queues).must_equal %w[test drive]
      _(config.delayed_job.track_busy_jobs).must_equal true

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:delayed_job)
    end
  end
end