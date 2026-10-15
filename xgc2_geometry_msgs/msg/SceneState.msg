std_msgs/Header header
string epoch
uint64 revision
bool playing
float64 scene_time
# Dynamic obstacles only. Static poses are authoritative in SceneSnapshot.
# An empty list remains the source heartbeat for a static scene.
SceneObstacleState[] obstacles
