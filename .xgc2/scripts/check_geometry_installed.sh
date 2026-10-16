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
    "ros-${ROS_DISTRO}-xgc2-unicycle-reference-trajectory-msgs" \
    "ros-${ROS_DISTRO}-xgc2-ugv-reset-msgs" "ros-${ROS_DISTRO}-xgc2-ros-msgs"; do
    if [[ "$(dpkg-query -W -f='${Status}' "${package}" 2>/dev/null || true)" == "install ok installed" ]]; then
      echo "Geometry standalone check unexpectedly has ${package} installed" >&2
      exit 1
    fi
  done
fi

# Ordered numeric geometry table shared by obstacle and explicit ground parts.
for identity in \
  SceneGeometry:95507b56eb79eb50395da8b09ab4282d \
  SceneGround:835e0a81ddfdfeac1b59f193ee01a3ca \
  SceneObstacle:d368ef7f4a4c10dff0b9d2cf7c9234fe \
  SceneObstacleState:ddf3839cc06dbe27265f5f18a008071e \
  ScenePart:f4738b6fb5c7e77fa407ee655b30294c \
  SceneSnapshot:8a9d11d809938be41fbc50634833cee5 \
  SceneState:f307520b78c47e1029c6883e2e22a7cb; do
  test "$(rosmsg md5 "xgc2_geometry_msgs/${identity%%:*}")" = "${identity#*:}"
done

for obsolete in GeometryLibrary GeometryTemplate ConvexBodyArray ConvexBodyInstance; do
  test ! -e "/opt/ros/${ROS_DISTRO}/include/xgc2_geometry_msgs/${obsolete}.h"
  test ! -e "/opt/ros/${ROS_DISTRO}/share/xgc2_geometry_msgs/msg/${obsolete}.msg"
  if rosmsg show "xgc2_geometry_msgs/${obsolete}" >/dev/null 2>&1; then
    echo "Obsolete geometry message still installed: ${obsolete}" >&2
    exit 1
  fi
done

msg_python=python3
if [[ "${ROS_DISTRO}" == melodic ]]; then msg_python=python2; fi
"${msg_python}" - <<'PYTHON'
from io import BytesIO
import pkgutil
import struct
import xgc2_geometry_msgs.msg as messages
from xgc2_geometry_msgs.msg import SceneSnapshot, SceneObstacle, ScenePart, SceneGeometry, SceneGround

for obsolete in ("GeometryLibrary", "GeometryTemplate", "ConvexBodyArray", "ConvexBodyInstance"):
    assert not hasattr(messages, obsolete)
    assert pkgutil.find_loader("xgc2_geometry_msgs.msg._" + obsolete) is None
assert SceneGeometry.__slots__ == ["type", "parameters"]
assert SceneGeometry._slot_types == ["uint32", "uint8[]"]
assert ScenePart.__slots__ == ["id", "pose", "geometry_index", "color"]
assert ScenePart._slot_types[2:] == ["uint32", "std_msgs/ColorRGBA"]
assert SceneGround.__slots__ == ["mode", "z", "pose", "parts"]
assert (SceneGround.MODE_DEFAULT_PLANE, SceneGround.MODE_MODEL, SceneGround.MODE_NONE) == ("default_plane", "model", "none")
payload = struct.pack("<3d", 3.0, 1.0, 0.8)

scene = SceneSnapshot(scene_id="installed-consumer", epoch="baseline", revision=12,
                      ground=SceneGround(mode=SceneGround.MODE_MODEL))
scene.ground.pose.position.z, scene.ground.pose.orientation.w = -1.0, 1.0
obstacle = SceneObstacle(id="ring", name="Ring", dynamic=False, motion_type="hold")
obstacle.pose.position.x, obstacle.pose.position.y, obstacle.pose.position.z = 3.0, -2.0, 4.0
obstacle.pose.orientation.x = obstacle.pose.orientation.y = 0.5
obstacle.pose.orientation.z = obstacle.pose.orientation.w = 0.5
part = ScenePart(id="tube")
part.pose.position.x, part.pose.position.y, part.pose.position.z = 1.0, 2.0, 3.0
part.pose.orientation.x, part.pose.orientation.y = 0.5, -0.5
part.pose.orientation.z = part.pose.orientation.w = 0.5
part.geometry_index = 0
scene.geometries.append(SceneGeometry(type=6, parameters=payload))
scene.ground.parts.append(part)
obstacle.parts.append(part)
scene.obstacles.append(obstacle)
stream = BytesIO()
scene.serialize(stream)
restored = SceneSnapshot().deserialize(stream.getvalue())
assert restored.epoch == "baseline" and restored.revision == 12
assert len(restored.obstacles) == 1 and len(restored.obstacles[0].parts) == 1
assert restored.obstacles[0].pose == obstacle.pose
assert restored.obstacles[0].parts[0].pose == part.pose
assert len(restored.geometries) == 1
assert restored.ground.mode == SceneGround.MODE_MODEL
assert restored.ground.pose == scene.ground.pose
assert len(restored.ground.parts) == 1
assert restored.ground.parts[0].pose == part.pose
assert restored.ground.parts[0].geometry_index == restored.obstacles[0].parts[0].geometry_index == 0
assert restored.geometries[0].type == 6
assert bytes(bytearray(restored.geometries[0].parameters)) == payload
PYTHON

consumer_dir="$(mktemp -d)"
trap 'rm -rf "${consumer_dir}"' EXIT
cat > "${consumer_dir}/consumer.cpp" <<'CPP'
#include <xgc2_geometry_msgs/SceneSnapshot.h>
#include <xgc2_geometry_msgs/SceneState.h>
#include <xgc2_geometry_msgs/SceneGround.h>

int main() {
  xgc2_geometry_msgs::SceneSnapshot scene;
  xgc2_geometry_msgs::SceneState state;
  scene.epoch = state.epoch = "installed-check";
  scene.revision = state.revision = 12;
  scene.ground.mode = xgc2_geometry_msgs::SceneGround::MODE_MODEL;
  scene.ground.pose.orientation.w = 1;
  xgc2_geometry_msgs::SceneObstacle obstacle;
  xgc2_geometry_msgs::ScenePart part;
  xgc2_geometry_msgs::SceneGeometry geometry;
  geometry.type = 6;
  geometry.parameters = {0,0,0,0,0,0,8,64, 0,0,0,0,0,0,240,63,
                         154,153,153,153,153,153,233,63};
  scene.geometries.push_back(geometry);
  part.geometry_index = 0;
  scene.ground.parts.push_back(part);
  obstacle.parts.push_back(part);
  scene.obstacles.push_back(obstacle);
  if (scene.geometries.size() != 1 || scene.ground.parts.size() != 1 ||
      scene.ground.mode != xgc2_geometry_msgs::SceneGround::MODE_MODEL ||
      scene.obstacles[0].parts[0].geometry_index != 0 || scene.ground.parts[0].geometry_index != 0 ||
      scene.geometries[0].type != 6 || scene.geometries[0].parameters != geometry.parameters) return 1;
  return scene.revision == state.revision ? 0 : 1;
}
CPP
# shellcheck disable=SC2046
c++ -std=c++11 $(pkg-config --cflags xgc2_geometry_msgs) \
  "${consumer_dir}/consumer.cpp" -o "${consumer_dir}/consumer"
"${consumer_dir}/consumer"
echo "Installed geometry check passed (standalone=${standalone}; C++, Python, seven MD5 identities; obsolete types absent)"
