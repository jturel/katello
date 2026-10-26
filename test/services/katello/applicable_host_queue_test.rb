require 'katello_test_helper'

module Katello
  class ApplicableHostQueueTest < ActiveSupport::TestCase
    def setup
      Setting['applicability_batch_size'] = 50
    end

    def test_pop_nothing
      assert_empty ApplicableHostQueue.pop_hosts
    end

    def test_pop_1_host
      ApplicableHostQueue.push_hosts([999])
      popped_hosts = ApplicableHostQueue.pop_hosts

      assert_equal [999], popped_hosts.sort
    end

    def test_pop_5_hosts
      5.times { |i| ApplicableHostQueue.push_hosts([i]) }
      popped_hosts = ApplicableHostQueue.pop_hosts

      assert_equal [0, 1, 2, 3, 4], popped_hosts.sort
    end

    def test_pop_duplicate_hosts
      5.times { |i| ApplicableHostQueue.push_hosts([i]) }
      5.times { |i| ApplicableHostQueue.push_hosts([i]) }
      popped_hosts = ApplicableHostQueue.pop_hosts

      assert_equal [0, 1, 2, 3, 4], popped_hosts.sort
    end
  end
end
