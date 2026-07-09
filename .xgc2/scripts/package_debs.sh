#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-melodic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ROS_PACKAGES=(
  state_machine_msgs
  hover_thrust_estimator_msgs
  rigid_state_estimator_msgs
  multirotor_reference_trajectory_msgs
  px4_multirotor_controller_msgs
  unicycle_reference_trajectory_msgs
)

deb_package_for_ros_package() {
  case "$1" in
    state_machine_msgs) echo "ros-${ROS_DISTRO}-xgc2-state-machine-msgs" ;;
    hover_thrust_estimator_msgs) echo "ros-${ROS_DISTRO}-xgc2-estimator-hover-thrust-msgs" ;;
    rigid_state_estimator_msgs) echo "ros-${ROS_DISTRO}-xgc2-estimator-rigid-state-msgs" ;;
    multirotor_reference_trajectory_msgs) echo "ros-${ROS_DISTRO}-xgc2-multirotor-reference-trajectory-msgs" ;;
    px4_multirotor_controller_msgs) echo "ros-${ROS_DISTRO}-xgc2-px4-multirotor-controller-msgs" ;;
    unicycle_reference_trajectory_msgs) echo "ros-${ROS_DISTRO}-xgc2-unicycle-reference-trajectory-msgs" ;;
    *) echo "unknown ROS package: $1" >&2; exit 2 ;;
  esac
}

deb_description_for_ros_package() {
  case "$1" in
    state_machine_msgs) echo "XGC2 generic state-machine trace message interfaces" ;;
    hover_thrust_estimator_msgs) echo "XGC2 hover thrust estimator message interfaces" ;;
    rigid_state_estimator_msgs) echo "XGC2 rigid state estimator message interfaces" ;;
    multirotor_reference_trajectory_msgs) echo "XGC2 multirotor reference trajectory message interfaces" ;;
    px4_multirotor_controller_msgs) echo "XGC2 PX4 multirotor controller message interfaces" ;;
    unicycle_reference_trajectory_msgs) echo "XGC2 unicycle reference trajectory message interfaces" ;;
    *) echo "XGC2 ROS message interfaces" ;;
  esac
}

deb_depends_for_ros_package() {
  case "$1" in
    state_machine_msgs|hover_thrust_estimator_msgs)
      echo "ros-${ROS_DISTRO}-message-runtime, ros-${ROS_DISTRO}-std-msgs"
      ;;
    *)
      echo "ros-${ROS_DISTRO}-message-runtime, ros-${ROS_DISTRO}-std-msgs, ros-${ROS_DISTRO}-geometry-msgs"
      ;;
  esac
}

product_version() {
  awk -F': *' '/^version:[[:space:]]*/ {print $2; exit}' "${REPO_ROOT}/.xgc2/product.yml"
}

VERSION="${PACKAGE_VERSION:-$(product_version)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${INSTALL_ROOT}" || -z "${OUTPUT_DIR}" ]]; then
  echo "--install-root and --output-dir are required" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
PREFIX="/opt/ros/${ROS_DISTRO}"
PREFIX_ROOT="${INSTALL_ROOT}${PREFIX}"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${BUILD_DIR}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}"/*.deb

copy_path() {
  local src="$1"
  local dst_root="$2"
  if [[ -e "${src}" ]]; then
    mkdir -p "${dst_root}$(dirname "${src#${INSTALL_ROOT}}")"
    cp -a "${src}" "${dst_root}${src#${INSTALL_ROOT}}"
  fi
}

copy_ros_package() {
  local ros_package="$1"
  local pkg_root="$2"
  copy_path "${PREFIX_ROOT}/share/${ros_package}" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/include/${ros_package}" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/lib/pkgconfig/${ros_package}.pc" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/lib/python2.7/dist-packages/${ros_package}" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/lib/python3/dist-packages/${ros_package}" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/share/gennodejs/ros/${ros_package}" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/share/common-lisp/ros/${ros_package}" "${pkg_root}"
  copy_path "${PREFIX_ROOT}/share/roseus/ros/${ros_package}" "${pkg_root}"
}

INDIVIDUAL_DEBS=()
for ros_package in "${ROS_PACKAGES[@]}"; do
  deb_package="$(deb_package_for_ros_package "${ros_package}")"
  pkg_root="${BUILD_DIR}/${deb_package}"
  mkdir -p "${pkg_root}"
  copy_ros_package "${ros_package}" "${pkg_root}"

  if [[ ! -d "${pkg_root}${PREFIX}/share/${ros_package}" ]]; then
    echo "missing installed ${ros_package} share directory" >&2
    exit 1
  fi

  mkdir -p "${pkg_root}/DEBIAN" "${pkg_root}/usr/share/doc/${deb_package}"
  cat > "${pkg_root}/DEBIAN/control" <<EOF
Package: ${deb_package}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: $(deb_depends_for_ros_package "${ros_package}")
Description: $(deb_description_for_ros_package "${ros_package}")
EOF

  printf '%s package\n' "${deb_package}" > "${pkg_root}/usr/share/doc/${deb_package}/README"
  find "${pkg_root}" -type d -exec chmod 0755 {} +
  find "${pkg_root}" -type f -exec chmod 0644 {} +
  chmod 0755 "${pkg_root}/DEBIAN"
  deb_path="${OUTPUT_DIR}/${deb_package}_${VERSION}_${ARCH}.deb"
  fakeroot dpkg-deb --build "${pkg_root}" "${deb_path}" >/dev/null
  INDIVIDUAL_DEBS+=("${deb_package} (= ${VERSION})")
done

aggregate_package="ros-${ROS_DISTRO}-xgc2-ros-msgs"
aggregate_root="${BUILD_DIR}/${aggregate_package}"
mkdir -p "${aggregate_root}/DEBIAN" "${aggregate_root}/usr/share/doc/${aggregate_package}"
aggregate_depends=""
for deb in "${INDIVIDUAL_DEBS[@]}"; do
  if [[ -n "${aggregate_depends}" ]]; then
    aggregate_depends+=", "
  fi
  aggregate_depends+="${deb}"
done
cat > "${aggregate_root}/DEBIAN/control" <<EOF
Package: ${aggregate_package}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: ${aggregate_depends}
Description: XGC2 aggregate ROS1 message interface package
EOF
printf '%s package\n' "${aggregate_package}" > "${aggregate_root}/usr/share/doc/${aggregate_package}/README"
find "${aggregate_root}" -type d -exec chmod 0755 {} +
find "${aggregate_root}" -type f -exec chmod 0644 {} +
chmod 0755 "${aggregate_root}/DEBIAN"
fakeroot dpkg-deb --build "${aggregate_root}" \
  "${OUTPUT_DIR}/${aggregate_package}_${VERSION}_${ARCH}.deb" >/dev/null

find "${OUTPUT_DIR}" -maxdepth 1 -type f -name '*.deb' -print | sort
