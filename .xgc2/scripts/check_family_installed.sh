#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
family="${1:-}"
standalone=false
if [[ $# -eq 2 && "$2" == "--standalone" ]]; then
  standalone=true
elif [[ $# -ne 1 ]]; then
  echo "usage: $0 FAMILY [--standalone]" >&2
  exit 2
fi

# Baselines from the message definitions at ros1-msgs 1d64dd8.
case "${family}" in
  camera)
    ros_package=xgc_camera_msgs
    identities=(
      FrameTiming:f8e09de92dcf04d9ff1592a990615324
      StreamInfo:21f5bcac2dc5eb5f9306481541586cca
    )
    ;;
  state-machine)
    ros_package=state_machine_msgs
    identities=(
      StateMachineTrace:029439adcf9d13a75901859b70ca5c84
      StateMachineTraceEvent:b7fd2f2b166cef297044d172d161072a
    )
    ;;
  estimator-hover-thrust)
    ros_package=hover_thrust_estimator_msgs
    identities=(HoverThrustEstimate:cd5b040632e2e0d1d54d939f351e048e)
    ;;
  estimator-rigid-state)
    ros_package=rigid_state_estimator_msgs
    identities=(RigidStateEstimate:7424c514b9ac1ad1576e5e21d46362a3)
    ;;
  multirotor-reference-trajectory)
    ros_package=multirotor_reference_trajectory_msgs
    identities=(
      AnalyticReference:92386fcc671bb194b199fef42a15d0af
      FlatReferencePoint:82f9794f6704773d69da84892e81149b
      ReferenceStatus:9e2c74fe168950b0e94149350644003c
      SampledReference:22b5fcd2fd799c3da016394cf84a39e8
    )
    ;;
  px4-multirotor-controller)
    ros_package=px4_multirotor_controller_msgs
    identities=(NmpcDebugSample:de4524cd511e45f1dd8941a130a6c815)
    ;;
  unicycle-reference-trajectory)
    ros_package=unicycle_reference_trajectory_msgs
    identities=(
      ActivePolynomialReference:832a4d4da7a218383c3b42c01417e791
      AnalyticReference:c840ee781fe219ec5d9cb86f1a2ff1dd
      PlanarPvaReference:921d5cecfa0b467e1de2cae007faafb2
      PlanarReferencePoint:cd1a14aa0adb8440cb27ae5dc6f3bd4e
      ReferenceStatus:f12f34799eb5dda8b268e89e9a5e9e79
      SampledReference:9044160f74bc8bb11c42775e53f64e8c
      WaypointReferenceRequest:52c351ce747add594dfc7134ad3b9241
    )
    ;;
  ugv-reset)
    ros_package=ugv_reset_msgs
    # The session, grant, result and fleet protocol (2.0.0 removed the lease pair ResetRequest and
    # ResetResponse; they are asserted absent by the consumer's installed-package check).
    identities=(
      ResetFleet:e0732d75627163db9f601e44a4eec2c8
      ResetFleetMember:5138864d3985b2451a5660184c5fafdc
      ResetGrant:7fbd3a118b9f158d62c1359da486102d
      ResetResult:1c6e3a8ef67342fea98c7d38c3c7defb
      ResetSession:866c909dd62d4badc9cc52a0fa71b236
    )
    ;;
  *)
    echo "unknown message family: ${family}" >&2
    exit 2
    ;;
esac

# Resolve only installed interfaces, even when called from a catkin build.
unset CMAKE_PREFIX_PATH ROS_PACKAGE_PATH PYTHONPATH
set +u
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u
dpkg -s "ros-${ROS_DISTRO}-xgc2-${family}-msgs" >/dev/null
test "$(rospack find "${ros_package}")" = "/opt/ros/${ROS_DISTRO}/share/${ros_package}"

if [[ "${standalone}" == true ]]; then
  other_packages=("ros-${ROS_DISTRO}-scout-msgs")
  for other_family in camera state-machine estimator-hover-thrust estimator-rigid-state \
    multirotor-reference-trajectory px4-multirotor-controller \
    unicycle-reference-trajectory geometry ugv-reset ros; do
    if [[ "${other_family}" != "${family}" ]]; then
      other_packages+=("ros-${ROS_DISTRO}-xgc2-${other_family}-msgs")
    fi
  done
  for package in "${other_packages[@]}"; do
    if [[ "$(dpkg-query -W -f='${Status}' "${package}" 2>/dev/null || true)" == "install ok installed" ]]; then
      echo "${family} standalone check unexpectedly has ${package} installed" >&2
      exit 1
    fi
  done
fi

for identity in "${identities[@]}"; do
  test "$(rosmsg md5 "${ros_package}/${identity%%:*}")" = "${identity#*:}"
done

msg_python=python3
if [[ "${ROS_DISTRO}" == melodic ]]; then msg_python=python2; fi
"${msg_python}" - "${ros_package}" "${identities[0]%%:*}" <<'PYTHON'
from importlib import import_module
from io import BytesIO
import sys

ros_package, message_name = sys.argv[1:]
message_class = getattr(import_module(ros_package + ".msg"), message_name)
message = message_class()
if ros_package == "xgc_camera_msgs":
    message.frame_id = "installed-check"
    message.source_time.secs = 12
    message.epoch = 17
else:
    message.header.seq = 17
    message.header.frame_id = "installed-check"
    message.header.stamp.secs = 12
stream = BytesIO()
message.serialize(stream)
restored = message_class().deserialize(stream.getvalue())
assert restored == message
PYTHON

echo "Installed ${family} check passed (standalone=${standalone}; Python, ${#identities[@]} MD5 identities)"
