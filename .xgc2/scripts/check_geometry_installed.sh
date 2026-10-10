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

unset CMAKE_PREFIX_PATH ROS_PACKAGE_PATH PYTHONPATH
set +u
# shellcheck source=/dev/null
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u
dpkg -s "ros-${ROS_DISTRO}-xgc2-geometry-msgs" >/dev/null
test "$(rospack find xgc2_geometry_msgs)" = "/opt/ros/${ROS_DISTRO}/share/xgc2_geometry_msgs"

if [[ "${standalone}" == true ]]; then
  for package in "ros-${ROS_DISTRO}-scout-msgs" \
    "ros-${ROS_DISTRO}-xgc2-scene-generation" "ros-${ROS_DISTRO}-xgc2-scene-runtime" \
    "ros-${ROS_DISTRO}-xgc2-cluttered-environment" "ros-${ROS_DISTRO}-xgc2-mockamap" \
    "ros-${ROS_DISTRO}-xgc2-world-lidar" \
    "ros-${ROS_DISTRO}-xgc2-camera-msgs" "ros-${ROS_DISTRO}-xgc2-state-machine-msgs" \
    "ros-${ROS_DISTRO}-xgc2-estimator-hover-thrust-msgs" \
    "ros-${ROS_DISTRO}-xgc2-estimator-rigid-state-msgs" \
    "ros-${ROS_DISTRO}-xgc2-multirotor-reference-trajectory-msgs" \
    "ros-${ROS_DISTRO}-xgc2-px4-multirotor-controller-msgs" \
    "ros-${ROS_DISTRO}-xgc2-unicycle-reference-trajectory-msgs" "ros-${ROS_DISTRO}-xgc2-ros-msgs"; do
    if [[ "$(dpkg-query -W -f='${Status}' "${package}" 2>/dev/null || true)" == "install ok installed" ]]; then
      echo "Geometry standalone check unexpectedly has ${package} installed" >&2
      exit 1
    fi
  done
fi

# Baseline: xgc2-scene-generation 869cc7824d021bd21b3b23aceb266e4e71eeb9d7.
for identity in \
  ConvexBodyArray:70206eec4fd6f79cb0a64a7b79934c20 \
  ConvexBodyInstance:77c10de3093d9a40425cbae59670f692 \
  GeometryLibrary:b0a5cce2fdfbff23ce9e67caf2f0f94d \
  GeometryTemplate:e5a61693d0fc452d22496f8644ac52bb \
  SceneConsumerStatus:09fc71fe677388baabf78f095024b507 \
  SceneGeometry:9d4d23feb4e4969d309ed97648929640 \
  SceneObstacle:a4a5a6b21d48fce24f6d577c630a66eb \
  SceneObstacleState:ddf3839cc06dbe27265f5f18a008071e \
  ScenePart:5b292453c4f9c000522c1cd109cb742d \
  SceneSnapshot:5a9442e10bd849d47c40cfadb42b29af \
  SceneState:f307520b78c47e1029c6883e2e22a7cb; do
  test "$(rosmsg md5 "xgc2_geometry_msgs/${identity%%:*}")" = "${identity#*:}"
done

msg_python=python3
if [[ "${ROS_DISTRO}" == melodic ]]; then msg_python=python2; fi
"${msg_python}" - <<'PYTHON'
from io import BytesIO
from xgc2_geometry_msgs.msg import SceneSnapshot, SceneObstacle, ScenePart, SceneConsumerStatus

scene = SceneSnapshot(scene_id="installed-consumer", epoch="baseline", revision=12)
obstacle = SceneObstacle(id="box", name="Box", dynamic=False, motion_type="hold")
obstacle.pose.orientation.w = 1.0
obstacle.parts.append(ScenePart())
scene.obstacles.append(obstacle)
stream = BytesIO()
scene.serialize(stream)
restored = SceneSnapshot().deserialize(stream.getvalue())
assert restored.epoch == "baseline" and restored.revision == 12
assert len(restored.obstacles) == 1 and len(restored.obstacles[0].parts) == 1
status = SceneConsumerStatus(epoch="baseline", revision=12, consumer="installed-check", applied=True, operational=True)
assert status.applied and status.operational
PYTHON

consumer_dir="$(mktemp -d)"
trap 'rm -rf "${consumer_dir}"' EXIT
cat > "${consumer_dir}/consumer.cpp" <<'CPP'
#include <xgc2_geometry_msgs/ConvexBodyArray.h>
#include <xgc2_geometry_msgs/GeometryLibrary.h>
#include <xgc2_geometry_msgs/SceneConsumerStatus.h>
#include <xgc2_geometry_msgs/SceneSnapshot.h>
#include <xgc2_geometry_msgs/SceneState.h>

int main() {
  xgc2_geometry_msgs::SceneSnapshot scene;
  xgc2_geometry_msgs::SceneState state;
  xgc2_geometry_msgs::SceneConsumerStatus status;
  xgc2_geometry_msgs::GeometryLibrary library;
  xgc2_geometry_msgs::ConvexBodyArray bodies;
  scene.epoch = state.epoch = status.epoch = "installed-check";
  scene.revision = state.revision = status.revision = 12;
  return scene.revision == status.revision && library.templates.empty() && bodies.instances.empty() ? 0 : 1;
}
CPP
# shellcheck disable=SC2046
c++ -std=c++11 $(pkg-config --cflags xgc2_geometry_msgs) \
  "${consumer_dir}/consumer.cpp" -o "${consumer_dir}/consumer"
"${consumer_dir}/consumer"
echo "Installed geometry check passed (standalone=${standalone}; C++, Python, eleven MD5 identities)"
