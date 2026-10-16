# Complete scene definition. Ground is independent of business obstacles.
std_msgs/Header header
string scene_id
string epoch
uint64 revision
SceneGeometry[] geometries
SceneGround ground
SceneObstacle[] obstacles
