# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/job_metrics_collector/active_record_helper"
require "judoscale/metric"

module Judoscale
  module GoodJob
    class MetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_config
        Judoscale::Config.instance.good_job
      end

      def collect
        metrics = []
        t = Time.now.utc

        # TODO: silence query logs for this
        at = ::GoodJob::Job.arel_table
        run_at_by_queue = ::GoodJob::JobsFilter.new(state: "queued").filtered_query.order(
          :queue_name, at.coalesce(at[:scheduled_at], at[:created_at])
        ).pluck(
          Arel.sql("distinct on (queue_name) queue_name, #{at.coalesce(at[:scheduled_at], at[:created_at]).to_sql}")
        ).to_h

        self.queues |= run_at_by_queue.keys

        # if track_busy_jobs?
        #   busy_count_by_queue = select_rows_silently(BUSY_METRICS_SQL).to_h
        #   self.queues |= busy_count_by_queue.keys
        # end

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
          # DateTime.parse assumes a UTC string
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at) * 1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          metrics.push Metric.new(:qt, latency_ms, t, queue)

          # if track_busy_jobs?
          #   busy_count = busy_count_by_queue[queue] || 0
          #   metrics.push Metric.new(:busy, busy_count, Time.now, queue)
          # end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
