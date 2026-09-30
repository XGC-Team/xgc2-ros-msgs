# Fixed-time seventh-order boundary interpolation; interior velocities use
# finite differences. Limits are checked after interpolation, not optimized.
uint8 OBJECTIVE_SEPTIC_INTERPOLATION = 1


std_msgs/Header header
uint32 request_id
uint32 trajectory_id
uint32 revision
uint32 flags
geometry_msgs/Pose[] waypoints
float64[] segment_times
geometry_msgs/Vector3 start_velocity
geometry_msgs/Vector3 start_acceleration
geometry_msgs/Vector3 end_velocity
geometry_msgs/Vector3 end_acceleration
float64 desired_speed
float64 max_velocity
float64 max_acceleration
float64 max_yaw_rate
float64 max_linear_acceleration
uint8 objective
