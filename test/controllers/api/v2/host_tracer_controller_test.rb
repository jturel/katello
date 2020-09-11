# encoding: utf-8

require "katello_test_helper"

module Katello
  class Api::V2::HostTracerControllerTest < ActionController::TestCase
    def models
      @host1 = hosts(:one)
    end

    def setup
      setup_foreman_routes
      models
    end

    def test_index
      @host1.host_traces.create!(:id => 1, :host_id => 1, :helper => 'agile', :app_type => 'foo', :application => 'scrumm')

      results = JSON.parse(get(:index, params: { :host_id => @host1.id }).body)

      assert_response :success
      assert_includes results['results'].collect { |item| item['id'] }, @host1.host_traces.first.id
    end

    def test_resolve
      trace_one = Katello::HostTracer.create(host_id: @host1.id, application: 'rsyslog', app_type: 'daemon', helper: 'systemctl restart rsyslog')
      task = ForemanTasks::Task.new.to_json
      result = JSON.parse(task)
      job_invocation = mock(task_id: '12345')
      composer = mock(job_invocation: job_invocation)

      ForemanTasks::Task.stubs(:find).returns(ForemanTasks::Task.new)

      Katello::HostTraceManager.expects(:resolve_traces).with([trace_one]).returns([composer])

      put :resolve, params: { :host_id => @host1.id, :trace_ids => [trace_one.id] }

      assert_response :success

      body = JSON.parse(response.body)

      assert_equal result['task'], body
    end
  end
end
