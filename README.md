# XGC2 ROS1 Messages

Shared ROS1 message interfaces for XGC2 Melodic packages.

This repository owns interface-only packages. Implementation packages should
depend on these packages when they only need a topic contract.

## Packages

- `state_machine_msgs`
- `hover_thrust_estimator_msgs`
- `rigid_state_estimator_msgs`
- `multirotor_reference_trajectory_msgs`
- `px4_multirotor_controller_msgs`
- `unicycle_reference_trajectory_msgs`

## Debian Packages

The release workflow publishes one Debian package per ROS package, plus an
aggregate package:

- `ros-melodic-xgc2-state-machine-msgs`
- `ros-melodic-xgc2-estimator-hover-thrust-msgs`
- `ros-melodic-xgc2-estimator-rigid-state-msgs`
- `ros-melodic-xgc2-multirotor-reference-trajectory-msgs`
- `ros-melodic-xgc2-px4-multirotor-controller-msgs`
- `ros-melodic-xgc2-unicycle-reference-trajectory-msgs`
- `ros-melodic-xgc2-ros-msgs`

Use the smallest specific package when a consumer only needs one interface
family. Use `ros-melodic-xgc2-ros-msgs` when a workspace wants all shared XGC2
ROS1 interfaces.

## Build

```bash
source /opt/ros/melodic/setup.bash
mkdir -p /tmp/xgc2-ros-msgs-ws/src
rsync -a . /tmp/xgc2-ros-msgs-ws/src/xgc2-ros-msgs
cd /tmp/xgc2-ros-msgs-ws
catkin_make
```

## Package

```bash
.xgc2/scripts/build_debs_in_docker.sh --work-dir /tmp/xgc2-ros-msgs --output-dir ./debs
```
