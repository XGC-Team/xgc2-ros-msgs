#!/usr/bin/env bash
# shellcheck disable=SC1004,SC2016
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

DOCKER_IMAGE="${DOCKER_IMAGE:-ghcr.io/xgc-team/xgc2-images/xgc2-build-focal-ros-noetic:1.0.0}"
WORK_DIR="${WORK_DIR:-${REPO_ROOT}/.work/docker}"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/debs}"
INSTALL_CHECK="${INSTALL_CHECK:-true}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image) DOCKER_IMAGE="$2"; shift 2 ;;
    --work-dir) WORK_DIR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --skip-install-check) INSTALL_CHECK=false; shift ;;
    --network) shift 2 ;;
    --platform)
      DOCKER_PLATFORM="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

mkdir -p "${WORK_DIR}" "${OUTPUT_DIR}"

docker_platform_args=()
if [[ -n "${DOCKER_PLATFORM:-}" ]]; then
  docker_platform_args=(--platform "${DOCKER_PLATFORM}")
fi

docker pull "${docker_platform_args[@]}" "${DOCKER_IMAGE}"
docker run --rm --network none \
  "${docker_platform_args[@]}" \
  -e XGC2_BUILD_GID="$(id -g)" \
  -e XGC2_BUILD_UID="$(id -u)" \
  -e DEBIAN_FRONTEND=noninteractive \
  -e INSTALL_CHECK="${INSTALL_CHECK}" \
  -v "${REPO_ROOT}:/workspace/ros1-msgs:ro" \
  -v "${WORK_DIR}:/workspace/work" \
  -v "${OUTPUT_DIR}:/workspace/out" \
  "${DOCKER_IMAGE}" \
  bash -lc '
    set -euo pipefail
    trap '\''build_status=$?; chown -R "${XGC2_BUILD_UID}:${XGC2_BUILD_GID}" /workspace/work /workspace/out; exit "${build_status}"'\'' EXIT

    export DEBIAN_FRONTEND=noninteractive
    : "${ROS_DISTRO:?ROS_DISTRO must be set in the image}"
    for pkg in \
      cmake fakeroot dpkg-dev \
      "ros-${ROS_DISTRO}-geometry-msgs" \
      "ros-${ROS_DISTRO}-message-generation" \
      "ros-${ROS_DISTRO}-roslaunch" \
      "ros-${ROS_DISTRO}-rosmsg" \
      "ros-${ROS_DISTRO}-rospack" \
      "ros-${ROS_DISTRO}-std-msgs"
    do
      if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        echo "image is missing ${pkg}" >&2
        exit 1
      fi
    done

    rm -rf /workspace/work/src /workspace/work/build /workspace/work/devel /workspace/work/install-root
    mkdir -p /workspace/work/src/ros1-msgs
    rsync -a --delete \
      --exclude .git --exclude .work --exclude debs \
      /workspace/ros1-msgs/ /workspace/work/src/ros1-msgs/

    cd /workspace/work
    set +u
    source /opt/ros/${ROS_DISTRO}/setup.bash
    set -u
    DESTDIR=/workspace/work/install-root catkin_make install \
      -DCMAKE_INSTALL_PREFIX=/opt/ros/${ROS_DISTRO} \
      -DCMAKE_BUILD_TYPE=Release

    /workspace/ros1-msgs/.xgc2/scripts/package_debs.sh \
      --install-root /workspace/work/install-root \
      --output-dir /workspace/out

    if [[ "${INSTALL_CHECK}" == "true" ]]; then
      mapfile -t package_debs < <(
        find /workspace/out -maxdepth 1 -type f -name "*.deb" -print | sort
      )
      if [[ "${#package_debs[@]}" -lt 1 ]]; then
        echo "expected ros-msgs debs, found none" >&2
        exit 1
      fi
      dpkg -i "${package_debs[@]}"
      /workspace/ros1-msgs/.xgc2/scripts/check_installed_packages.sh
    fi
  '

echo "Debian package output:"
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "*.deb" -print | sort
