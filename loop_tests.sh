#!/bin/bash

for (( x=1; x<=500; x++ ))
do
  echo $x
  ktest test/lib/event_daemon/runner_test.rb test/lib/event_daemon/monitor_test.rb ./test/lib/event_daemon/services/agent_event_receiver_test.rb ./test/services/katello/candlepin_event_listener_test.rb ./test/services/katello/event_monitor/poller_thread_test.rb
  if [[ $? -ne 0 ]]
  then
    break
  fi
done
