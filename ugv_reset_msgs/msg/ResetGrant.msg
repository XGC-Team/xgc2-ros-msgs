# The coordinator's permission to move, coordinator -> vehicle on <ns>/reset/grant.
# A grant is a frozen route plus the prefix of it the vehicle may drive. The prefix only grows while
# the vehicle follows the route (a new grant_id with the same route), and the vehicle stops at its
# end. ttl is a heartbeat: the vehicle brakes when it passes without a refresh. The coordinator
# repeats an unchanged grant at >= 2 Hz.
std_msgs/Header header
uint32 session                  # the vehicle session this answers; anything else is ignored

uint8 STATE_HOLD=0              # do not move (waiting; reason says why)
uint8 STATE_GO=1                # follow the route up to s_limit
uint8 STATE_BRAKE=2             # stop now, keep the session (route revoked, re-plan follows)
uint8 STATE_REJECT=3            # the session ends with reason as its outcome
uint8 state

uint32 grant_id                 # increases with every message of one route; 0 for a HOLD
geometry_msgs/Pose2D start      # pose the route was planned from
geometry_msgs/Pose2D goal       # where the route ends: the target for a final move, a parking pose otherwise
bool final_move                 # true: the route ends at the target and the arrival gate applies
float64 ell_plan                # rotation-centre offset the route was planned for
geometry_msgs/Point[] via       # interior vertices of the rotation-centre polyline (z = 0)
float64 s_limit                 # arc length of the route the vehicle may reach (>= route length: all)
float64 ttl                     # seconds the grant holds after it is received (wall clock of the vehicle)

# Why the vehicle is held, braked or rejected. A REJECT ends the session; ResetResult.reason repeats this code.
uint8 REASON_NONE=0
uint8 REASON_WAITING_FOR_PEER=1         # a mover's reservation is in the way, it will clear
uint8 REASON_PRECEDENCE=2               # another waiting vehicle passes this one's goal first
uint8 REASON_REPLAN=3                   # revoked: the rest of the route is blocked by a parked body
uint8 REASON_SCENE_UNAVAILABLE=4        # a Scene is authored but its snapshot or heartbeat is missing
uint8 REASON_NON_PARTICIPANT_MOVING=5   # a body outside any Reset session is moving
uint8 REASON_GOAL_OCCUPIED=20           # the target is blocked by a static or a non-participant body
uint8 REASON_NO_ROUTE=21                # no route clear of the statics and the fence
uint8 REASON_DEADLOCK=22                # nobody can move and no parking move helps; blockers lists them
uint8 REASON_TOO_SLOW=23                # predicted duration exceeds 1.5 x the Reset limit
uint8 REASON_BAD_SESSION=24             # non-finite pose or target, target outside the fence
uint8 REASON_STALLED=25                 # movers exist but nobody advanced for 10 s
uint8 REASON_SCENE_CHANGED=26           # the Scene changed under this session
uint8 reason
string detail                   # one line for the log and the HUD
string[] blockers               # namespaces (or scene obstacle ids) that cause the hold or the rejection
