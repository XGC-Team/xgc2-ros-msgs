# XGC2 State Machine Messages

Generic ROS1 message interfaces for publishing state-machine runtime traces.

This repository owns the `state_machine_msgs` ROS package on the `noetic`
branch. It is intentionally independent from any product-specific state machine
implementation. Runtime packages should publish their own business status on
their own topics and use these messages only for state-machine observability.

## Messages

`state_machine_msgs/StateMachineTrace` describes one state-machine update
snapshot:

- `header`: ROS timestamp of the trace publication.
- `machine_name`: logical state-machine name.
- `update_index`: monotonically increasing state-machine update index.
- `active_region_ids` and `active_state_ids`: active leaf-state snapshot.
- `events`: event-generation, event-consumption, transition, or deferred-event
  records from that update.

`state_machine_msgs/StateMachineTraceEvent` describes one trace record:

- `phase`: caller-defined update phase, such as transition pass or tick pass.
- `kind`: generated event, consumed event, committed transition, or deferred
  internal event.
- `event_id`, `event_name`, `category`, `source`, `sequence`,
  `correlation_id`: event identity and provenance.
- `producer_region`, `producer_state`: state that generated the event, when
  applicable.
- `consumer_region`, `from_state`, `to_state`, `transition_id`, `priority`:
  transition or consumption context, when applicable.

## Build

```bash
source /opt/ros/noetic/setup.bash
mkdir -p /tmp/state-machine-msgs-ws/src
rsync -a . /tmp/state-machine-msgs-ws/src/state-machine-msgs
cd /tmp/state-machine-msgs-ws
catkin_make
```

## Package

```bash
.xgc2/scripts/build_debs_in_docker.sh --work-dir /tmp/xgc2-state-machine-msgs --output-dir ./debs
```
