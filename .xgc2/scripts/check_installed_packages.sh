#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
set +u
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u

for package in \
  "ros-${ROS_DISTRO}-xgc2-camera-msgs" \
  "ros-${ROS_DISTRO}-xgc2-state-machine-msgs" \
  "ros-${ROS_DISTRO}-xgc2-estimator-hover-thrust-msgs" \
  "ros-${ROS_DISTRO}-xgc2-estimator-rigid-state-msgs" \
  "ros-${ROS_DISTRO}-xgc2-multirotor-reference-trajectory-msgs" \
  "ros-${ROS_DISTRO}-xgc2-px4-multirotor-controller-msgs" \
  "ros-${ROS_DISTRO}-xgc2-unicycle-reference-trajectory-msgs" \
  "ros-${ROS_DISTRO}-xgc2-ros-msgs"; do
  dpkg -s "${package}" >/dev/null
done

test "$(rospack find xgc_camera_msgs)" = "/opt/ros/${ROS_DISTRO}/share/xgc_camera_msgs"
test "$(rospack find state_machine_msgs)" = "/opt/ros/${ROS_DISTRO}/share/state_machine_msgs"
test "$(rospack find hover_thrust_estimator_msgs)" = "/opt/ros/${ROS_DISTRO}/share/hover_thrust_estimator_msgs"
test "$(rospack find rigid_state_estimator_msgs)" = "/opt/ros/${ROS_DISTRO}/share/rigid_state_estimator_msgs"
test "$(rospack find multirotor_reference_trajectory_msgs)" = "/opt/ros/${ROS_DISTRO}/share/multirotor_reference_trajectory_msgs"
test "$(rospack find px4_multirotor_controller_msgs)" = "/opt/ros/${ROS_DISTRO}/share/px4_multirotor_controller_msgs"
test "$(rospack find unicycle_reference_trajectory_msgs)" = "/opt/ros/${ROS_DISTRO}/share/unicycle_reference_trajectory_msgs"

rosmsg show state_machine_msgs/StateMachineTrace | grep -q '^uint64 update_index$'
rosmsg show xgc_camera_msgs/FrameTiming | grep -q '^uint64 epoch$'
rosmsg show xgc_camera_msgs/FrameTiming | grep -q '^uint8 DISCONTINUITY_QUEUE_OVERFLOW=4$'
rosmsg show xgc_camera_msgs/FrameTiming | grep -q '^int64 native_source_time_ns$'
rosmsg show xgc_camera_msgs/FrameTiming | grep -q '^uint64 mapping_uncertainty_ns$'
rosmsg show xgc_camera_msgs/StreamInfo | grep -q '^uint32 publisher_queue_capacity$'
rosmsg show hover_thrust_estimator_msgs/HoverThrustEstimate | grep -q '^float64 hover_thrust$'
rosmsg show rigid_state_estimator_msgs/RigidStateEstimate | grep -q '^geometry_msgs/Vector3 angular_velocity$'
rosmsg show rigid_state_estimator_msgs/PlanarStateEstimate | grep -q '^uint8 estimator_state$'
rosmsg show multirotor_reference_trajectory_msgs/SampledReference | grep -q '^multirotor_reference_trajectory_msgs/FlatReferencePoint\[\] points$'
rosmsg show px4_multirotor_controller_msgs/NmpcDebugSample | grep -q '^float64 hover_thrust$'
rosmsg show unicycle_reference_trajectory_msgs/SampledReference | grep -q '^unicycle_reference_trajectory_msgs/PlanarReferencePoint\[\] points$'

msg_python="python3"
if [[ "${ROS_DISTRO}" == "melodic" ]]; then
  msg_python="python2"
fi
"${msg_python}" - <<'PY'
from hover_thrust_estimator_msgs.msg import HoverThrustEstimate
from multirotor_reference_trajectory_msgs.msg import AnalyticReference as UavAnalytic
from rigid_state_estimator_msgs.msg import PlanarStateEstimate, RigidStateEstimate
from state_machine_msgs.msg import StateMachineTrace
from unicycle_reference_trajectory_msgs.msg import AnalyticReference as UgvAnalytic
from xgc_camera_msgs.msg import FrameTiming, StreamInfo

assert HoverThrustEstimate.STATE_AIRBORNE == 2
assert RigidStateEstimate.STATE_RUNNING == 3
assert PlanarStateEstimate.STATE_RUNNING == 2
assert UavAnalytic.ANALYTIC_TORUS_KNOT == 9
assert UgvAnalytic.ANALYTIC_CIRCLE == 1
assert FrameTiming.DISCONTINUITY_SOURCE_TIME_RESET == 2
assert FrameTiming.TIMESTAMP_REFERENCE_RENDER_COMPLETE == 3
assert StreamInfo.CONTRACT_VERSION_CURRENT == 1
trace = StateMachineTrace()
trace.machine_name = "test"
PY

echo "Installed package check passed"
