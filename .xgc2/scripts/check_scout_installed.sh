#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
standalone=false
if [[ "${1:-}" == "--standalone" && $# -eq 1 ]]; then
  standalone=true
elif [[ $# -ne 0 ]]; then
  echo "usage: $0 [--standalone]" >&2
  exit 2
fi

# Resolve only installed interfaces, even when called from a catkin build.
unset CMAKE_PREFIX_PATH ROS_PACKAGE_PATH PYTHONPATH
set +u
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u
dpkg -s "ros-${ROS_DISTRO}-scout-msgs" >/dev/null
test "$(rospack find scout_msgs)" = "/opt/ros/${ROS_DISTRO}/share/scout_msgs"

if [[ "${standalone}" == true ]]; then
  for family in camera state-machine estimator-hover-thrust estimator-rigid-state \
    multirotor-reference-trajectory px4-multirotor-controller \
    unicycle-reference-trajectory ros; do
    package="ros-${ROS_DISTRO}-xgc2-${family}-msgs"
    if [[ "$(dpkg-query -W -f='${Status}' "${package}" 2>/dev/null || true)" == "install ok installed" ]]; then
      echo "Scout standalone check unexpectedly has ${package} installed" >&2
      exit 1
    fi
  done
fi

# Baseline: xgc2-scout-msgs 92f61f26fe493ebefff0a212860bcd6d60f33fc3.
for identity in \
  ScoutStatus:7a49e199fd32bf5d7341d653c6b3ba6e \
  ScoutMotorState:9380628b50ebdc90ce46d4147360680d \
  ScoutLightState:51866248399dda20e62f6b250914288e \
  ScoutLightCmd:4efcbd363caf677fd8138923f982df13; do
  test "$(rosmsg md5 "scout_msgs/${identity%%:*}")" = "${identity#*:}"
done

msg_python=python3
if [[ "${ROS_DISTRO}" == melodic ]]; then
  msg_python=python2
fi
"${msg_python}" - <<'PY'
from io import BytesIO
from scout_msgs.msg import ScoutLightCmd, ScoutLightState, ScoutMotorState, ScoutStatus

assert ScoutStatus.MOTOR_ID_FRONT_RIGHT == 0
assert ScoutLightCmd.LIGHT_CUSTOM == 3
status = ScoutStatus()
status.battery_voltage = 24.5
status.motor_states[0] = ScoutMotorState(current=2.0, rpm=30.0, temperature=40.0)
status.front_light_state = ScoutLightState(mode=1, custom_value=0)
stream = BytesIO()
status.serialize(stream)
restored = ScoutStatus().deserialize(stream.getvalue())
assert restored.battery_voltage == 24.5
assert restored.motor_states[0].rpm == 30.0
PY

consumer_dir="$(mktemp -d)"
trap 'rm -rf "${consumer_dir}"' EXIT
cat > "${consumer_dir}/consumer.cpp" <<'CPP'
#include <scout_msgs/ScoutLightCmd.h>
#include <scout_msgs/ScoutLightState.h>
#include <scout_msgs/ScoutMotorState.h>
#include <scout_msgs/ScoutStatus.h>

int main() {
  scout_msgs::ScoutStatus status;
  scout_msgs::ScoutMotorState motor;
  scout_msgs::ScoutLightState light;
  scout_msgs::ScoutLightCmd command;
  status.motor_states[scout_msgs::ScoutStatus::MOTOR_ID_FRONT_RIGHT] = motor;
  status.front_light_state = light;
  command.front_mode = scout_msgs::ScoutLightCmd::LIGHT_CUSTOM;
  return status.motor_states.size() == 4 && command.front_mode == 3 ? 0 : 1;
}
CPP
# shellcheck disable=SC2046
c++ -std=c++11 $(pkg-config --cflags scout_msgs) \
  "${consumer_dir}/consumer.cpp" -o "${consumer_dir}/consumer"
"${consumer_dir}/consumer"
echo "Installed Scout check passed (standalone=${standalone}; C++, Python, four MD5 identities)"
