# The coordinator's view of every vehicle, 5 Hz on /ugv/reset/fleet (latched). For HUDs and tests;
# nothing in the protocol depends on it.
std_msgs/Header header
bool scene_available            # a Scene is authored and its snapshot and heartbeat are live
ResetFleetMember[] members
