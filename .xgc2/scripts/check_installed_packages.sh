#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-noetic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dpkg -s "ros-${ROS_DISTRO}-xgc2-ros-msgs" >/dev/null

for family in camera state-machine estimator-hover-thrust estimator-rigid-state \
  multirotor-reference-trajectory px4-multirotor-controller \
  unicycle-reference-trajectory ugv-reset; do
  "${SCRIPT_DIR}/check_family_installed.sh" "${family}"
done
"${SCRIPT_DIR}/check_scout_installed.sh"
"${SCRIPT_DIR}/check_geometry_installed.sh"

echo "Installed package check passed"
