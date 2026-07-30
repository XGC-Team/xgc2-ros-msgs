# Latched metadata for an encoded camera stream.
#
# stream_id remains stable across epochs. epoch has the same opaque token
# semantics as FrameTiming. Producers MUST republish this message whenever the
# epoch or any encoded-stream configuration changes.
#
# transport_mask is a bit mask. Fields that do not apply to a selected
# transport (for example RTP payload type for a ROS-only source) are zero.
# timestamp_reference states what physical/render event the per-frame source
# timestamp represents. CLOCK_DOMAIN_SYSTEM_REALTIME means POSIX/Unix realtime;
# CLOCK_DOMAIN_MONOTONIC has an arbitrary boot-local origin.

uint8 CONTRACT_VERSION_CURRENT=1

uint8 CODEC_UNKNOWN=0
uint8 CODEC_H264=1
uint8 CODEC_MJPEG=2

uint8 BITSTREAM_FORMAT_UNKNOWN=0
uint8 BITSTREAM_FORMAT_ANNEX_B=1
uint8 BITSTREAM_FORMAT_JPEG=2

uint8 CLOCK_DOMAIN_UNKNOWN=0
uint8 CLOCK_DOMAIN_SIMULATION=1
uint8 CLOCK_DOMAIN_SYSTEM_REALTIME=2
uint8 CLOCK_DOMAIN_MONOTONIC=3
uint8 CLOCK_DOMAIN_DEVICE=4

uint8 TIMESTAMP_SOURCE_UNKNOWN=0
uint8 TIMESTAMP_SOURCE_SENSOR=1
uint8 TIMESTAMP_SOURCE_DRIVER=2

uint8 TIMESTAMP_REFERENCE_UNKNOWN=0
uint8 TIMESTAMP_REFERENCE_START_OF_EXPOSURE=1
uint8 TIMESTAMP_REFERENCE_END_OF_FRAME=2
uint8 TIMESTAMP_REFERENCE_RENDER_COMPLETE=3

uint32 TRANSPORT_ROS_COMPRESSED_VIDEO=1
uint32 TRANSPORT_RTP=2
uint32 TRANSPORT_ROS_COMPRESSED_IMAGE=4

uint8 contract_version
string stream_id
string frame_id
uint64 epoch
uint8 codec
uint8 bitstream_format
uint8 clock_domain
uint8 timestamp_source
uint8 timestamp_reference
uint32 transport_mask
uint32 width
uint32 height
float64 nominal_frame_rate
uint32 rtp_clock_rate
uint8 rtp_payload_type
uint32 target_bitrate_bps
uint32 maximum_bitrate_bps
uint32 keyframe_interval_frames
uint32 publisher_queue_capacity
