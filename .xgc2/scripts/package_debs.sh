#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-noetic}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROS_PACKAGE="state_machine_msgs"
DEB_PACKAGE="ros-noetic-xgc2-state-machine-msgs"

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

if [[ -z "${VERSION}" ]]; then
  echo "package version is missing" >&2
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
rm -f "${OUTPUT_DIR}/${DEB_PACKAGE}_"*.deb

pkg_root="${BUILD_DIR}/${DEB_PACKAGE}"
mkdir -p "${pkg_root}"

copy_path() {
  local src="$1"
  if [[ -e "${src}" ]]; then
    mkdir -p "${pkg_root}$(dirname "${src#${INSTALL_ROOT}}")"
    cp -a "${src}" "${pkg_root}${src#${INSTALL_ROOT}}"
  fi
}

copy_path "${PREFIX_ROOT}/share/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/include/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/lib/pkgconfig/${ROS_PACKAGE}.pc"
copy_path "${PREFIX_ROOT}/lib/python3/dist-packages/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/share/gennodejs/ros/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/share/common-lisp/ros/${ROS_PACKAGE}"
copy_path "${PREFIX_ROOT}/share/roseus/ros/${ROS_PACKAGE}"

if [[ ! -d "${pkg_root}${PREFIX}/share/${ROS_PACKAGE}" ]]; then
  echo "missing installed ${ROS_PACKAGE} share directory" >&2
  exit 1
fi

mkdir -p "${pkg_root}/DEBIAN" "${pkg_root}/usr/share/doc/${DEB_PACKAGE}"
cat > "${pkg_root}/DEBIAN/control" <<EOF
Package: ${DEB_PACKAGE}
Version: ${VERSION}
Section: misc
Priority: optional
Architecture: ${ARCH}
Maintainer: XGC2 <apt@example.com>
Depends: ros-noetic-message-runtime, ros-noetic-std-msgs
Description: XGC2 generic state-machine trace message interfaces
EOF

printf '%s package\n' "${DEB_PACKAGE}" > "${pkg_root}/usr/share/doc/${DEB_PACKAGE}/README"
find "${pkg_root}" -type d -exec chmod 0755 {} +
find "${pkg_root}" -type f -exec chmod 0644 {} +
chmod 0755 "${pkg_root}/DEBIAN"
fakeroot dpkg-deb --build "${pkg_root}" "${OUTPUT_DIR}/${DEB_PACKAGE}_${VERSION}_${ARCH}.deb" >/dev/null
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "${DEB_PACKAGE}_*.deb" -print | sort
