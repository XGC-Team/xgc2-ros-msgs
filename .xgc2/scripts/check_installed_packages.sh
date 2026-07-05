#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
set +u
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u

dpkg -s ros-noetic-xgc2-state-machine-msgs >/dev/null
test "$(rospack find state_machine_msgs)" = "/opt/ros/${ROS_DISTRO}/share/state_machine_msgs"
test -f "/opt/ros/${ROS_DISTRO}/share/state_machine_msgs/msg/StateMachineTrace.msg"
test -f "/opt/ros/${ROS_DISTRO}/share/state_machine_msgs/msg/StateMachineTraceEvent.msg"
test -f "/opt/ros/${ROS_DISTRO}/include/state_machine_msgs/StateMachineTrace.h"
test -f "/opt/ros/${ROS_DISTRO}/include/state_machine_msgs/StateMachineTraceEvent.h"
test -f "/opt/ros/${ROS_DISTRO}/lib/pkgconfig/state_machine_msgs.pc"
test -f "/opt/ros/${ROS_DISTRO}/lib/python3/dist-packages/state_machine_msgs/msg/_StateMachineTrace.py"
test -f "/opt/ros/${ROS_DISTRO}/lib/python3/dist-packages/state_machine_msgs/msg/_StateMachineTraceEvent.py"
rosmsg show state_machine_msgs/StateMachineTrace | grep -q '^uint64 update_index$'
rosmsg show state_machine_msgs/StateMachineTraceEvent | grep -q '^uint32 event_id$'
python3 - <<'PY'
from state_machine_msgs.msg import StateMachineTrace, StateMachineTraceEvent

trace = StateMachineTrace()
trace.machine_name = "test"
trace.update_index = 1
event = StateMachineTraceEvent()
event.event_id = 42
trace.events.append(event)
assert trace.events[0].event_id == 42
PY

echo "Installed package check passed"
