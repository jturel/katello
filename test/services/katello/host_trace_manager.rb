require 'katello_test_helper'

unless Katello.with_remote_execution?
  class JobInvocationComposer
  end
end

module Katello
  class HostTraceManagerTest < ActiveSupport::TestCase
    def setup
      @host1 = FactoryBot.create(:host)
      @host2 = FactoryBot.create(:host)
    end

    def test_resolve_group_by_helper_one_invocation
      trace_one = Katello::HostTracer.create(host_id: @host1.id, application: 'rsyslog', app_type: 'daemon', helper: 'systemctl restart rsyslog')
      trace_two = Katello::HostTracer.create(host_id: @host2.id, application: 'rsyslog', app_type: 'daemon', helper: 'systemctl restart rsyslog')
      helper = {:helper => trace_two.helper}

      traces = Katello::HostTracer.where(id: [trace_one.id, trace_two.id])

      job_invocation = mock

      JobInvocationComposer.expects(:for_feature).with(:katello_service_restart, [@host1.id, @host2.id], helper).returns(mock(trigger: true, job_invocation: job_invocation))

      result = Katello::HostTraceManager.resolve_traces(traces)

      assert_equal [job_invocation], result
    end

    def test_resolve_reboot_service
      trace = Katello::HostTracer.create(host_id: @host1.id, application: 'kernel', app_type: 'static', helper: 'reboot the system')
      helper = {:helper => 'reboot'}
      job_invocation = {"description" => "Restart Services", "id" => 1, "job_category" => "Katello"}

      JobInvocationComposer.expects(:for_feature).with(:katello_service_restart, [@host1.id], helper).returns(mock(trigger: true, job_invocation: job_invocation))

      result = Katello::HostTraceManager.resolve_traces(Katello::HostTracer.where(id: trace.id))

      assert_equal 1, result.size
    end

    def test_group_by_host_ids
      trace_one = Katello::HostTracer.create(host_id: @host1.id, application: 'rsyslog', app_type: 'daemon', helper: 'systemctl restart rsyslog')
      trace_two = Katello::HostTracer.create(host_id: @host2.id, application: 'tuned', app_type: 'daemon', helper: 'systemctl restart tuned')
      trace_three = Katello::HostTracer.create(host_id: @host2.id, application: 'firewalld', app_type: 'daemon', helper: 'systemctl restart firewalld')
      traces = [trace_one.id, trace_two.id, trace_three.id]
      trace_ids = Katello::HostTracer.resolvable.where(id: traces)
      job_invocation = {"description" => "Restart Services", "id" => 1, "job_category" => "Katello"}
      helpers = [trace_two.helper, trace_three.helper].join(',')

      JobInvocationComposer.expects(:for_feature).with(:katello_service_restart, [@host1.id], {:helper => trace_one.helper}).returns(mock(trigger: true, job_invocation: job_invocation))
      JobInvocationComposer.expects(:for_feature).with(:katello_service_restart, [@host2.id], {:helper => helpers}).returns(mock(trigger: true, job_invocation: job_invocation))

      result = Katello::HostTraceManager.resolve_traces(trace_ids)

      assert_equal 2, result.size
    end
  end
end
