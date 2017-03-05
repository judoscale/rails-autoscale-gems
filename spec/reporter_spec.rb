require 'spec_helper'
require 'rails_autoscale_agent/reporter'
require 'rails_autoscale_agent/config'
require 'rails_autoscale_agent/store'
require 'webmock/rspec'

module RailsAutoscaleAgent
  describe Reporter do

    describe "#report!" do
      let(:config) { Config.new('RAILS_AUTOSCALE_URL' => 'http://example.com/api') }
      let(:store) { Store.instance }
      let!(:stub) { stub_request(:post, "http://example.com/api/reports") }

      before { store.instance_variable_set '@measurements', [] }

      it "reports stored metrics to the API" do
        store.push 123, Time.now - 60

        Reporter.instance.report!(config, store)

        expect(stub).to have_been_requested.once
      end

      it "does not report if there are only stored requests for the current minute" do
        store.push 123, Time.now

        Reporter.instance.report!(config, store)

        expect(stub).to_not have_been_requested
      end

      it "reports for each minute up to the current" do
        store.push 123, Time.now - 600
        store.push 456, Time.now - 60

        Reporter.instance.report!(config, store)

        expect(stub).to have_been_requested.twice
      end
    end

    describe "#register!" do
      let(:config) { Config.new('RAILS_AUTOSCALE_URL' => 'http://example.com/api') }
      let!(:stub) { stub_request(:post, "http://example.com/api/registrations") }

      it "registers the reporter with contextual info" do
        Reporter.instance.register!(config)

        expected_payload = {
          registration: {
            pid: Process.pid,
            ruby_version: '2.3.1',
            rails_version: '5.0.fake',
            gem_version: '0.1.0',
          }
        }

        expect(stub.with(body: expected_payload)).to have_been_requested.once
      end
    end

  end
end
