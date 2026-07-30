# One record per encoded frame.
#
# source_time and frame_id MUST exactly equal the corresponding
# foxglove_msgs/CompressedVideo timestamp/frame_id or the corresponding
# sensor_msgs/CompressedImage header stamp/frame_id. The tuple (stream_id,
# epoch, frame_sequence) is the source-local frame identity.
#
# epoch is an opaque, non-zero token. Compare it only for equality. A producer
# MUST change it whenever decoder-reference continuity or source-time
# continuity is broken. frame_sequence starts at zero in every epoch.
#
# rtp_timestamp is the source RTP timestamp before any downstream continuity
# rewriting. It is zero when the source has no RTP representation.
#
# source_time is usable only when source_time_valid is true. native_source_time_ns
# preserves the source clock without conversion. source_to_ros_offset_ns and
# mapping_uncertainty_ns describe the mapping used to produce source_time:
#   source_time ~= native_source_time_ns + source_to_ros_offset_ns
# Gazebo simulation time is already ROS simulation time, so its offset and
# uncertainty are both zero. A producer with an unknown mapping MUST set
# source_time_valid false instead of substituting its publication time.
#
# source_sequence preserves the native device/simulator ordering when one is
# available; it does not reset merely because the publication epoch changes.
# host_dequeue_monotonic_ns is zero when the source has no dequeue event.
# host_publish_realtime_ns is POSIX realtime sampled immediately before
# publication, and is never a replacement for source_time.

uint8 DISCONTINUITY_NONE=0
uint8 DISCONTINUITY_STREAM_START=1
uint8 DISCONTINUITY_SOURCE_TIME_RESET=2
uint8 DISCONTINUITY_ENCODER_RESET=3
uint8 DISCONTINUITY_QUEUE_OVERFLOW=4

uint8 TIMESTAMP_REFERENCE_UNKNOWN=0
uint8 TIMESTAMP_REFERENCE_START_OF_EXPOSURE=1
uint8 TIMESTAMP_REFERENCE_END_OF_FRAME=2
uint8 TIMESTAMP_REFERENCE_RENDER_COMPLETE=3

time source_time
bool source_time_valid
uint8 timestamp_reference
string frame_id
string stream_id
uint64 epoch
uint64 frame_sequence
uint64 source_sequence
uint32 rtp_timestamp
bool keyframe
uint8 discontinuity
uint32 dropped_frames_before
uint32 encoded_size_bytes
int64 native_source_time_ns
int64 host_dequeue_monotonic_ns
int64 host_publish_realtime_ns
int64 source_to_ros_offset_ns
uint64 mapping_uncertainty_ns
