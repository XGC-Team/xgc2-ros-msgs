# One vehicle's side of a Reset session, vehicle -> coordinator on <ns>/reset/session.
# Sent at 5 Hz for as long as the vehicle runs (phase IDLE when it is not resetting, so the
# coordinator knows every body and its declared footprint without a roster file) and at once on
# every change of phase or session. The vehicle declares everything the planner needs about itself.
std_msgs/Header header          # stamp: the vehicle's clock when the message was made
uint32 session                  # vehicle counter; a new Reset click is a new session, never reused
time pose_stamp                 # stamp of the pose below
geometry_msgs/Pose2D pose       # measured body-origin pose in the world frame
geometry_msgs/Pose2D target     # the frozen target of this session (valid when phase != IDLE)

uint8 PHASE_IDLE=0              # not resetting
uint8 PHASE_REQUESTING=1        # entered Reset, waiting for the first grant
uint8 PHASE_WAITING=2           # holding at a hold point, or between moves
uint8 PHASE_MOVING=3
uint8 PHASE_SETTLING=4          # at the end of the route, closing the arrival gate
uint8 PHASE_DONE=5              # session ended; see the latched ResetResult
uint8 phase
float64 progress                # arc length travelled on the granted route [m]
float64 cross_track             # signed distance from the route tube centre [m]

uint8 MODEL_UNICYCLE=0          # skid-steer / differential: vy = 0, rotation centre offset ell
uint8 MODEL_OMNI=1              # omnidirectional (mecanum)
uint8 model
# Reset footprint: the chassis plus the project margin, as a rectangle about the body origin.
float64 half_length
float64 half_width
float64 offset_x
float64 offset_y
# Limits the tracker obeys.
float64 max_v
float64 max_vy
float64 max_w
float64 acc_v
float64 acc_w
# Rotation-centre offset of a unicycle (uncommanded body-lateral velocity = -ell * omega).
float64 ell_hat                 # the vehicle's windowed estimate
float64 ell_spread              # |ell - ell_hat| the planner must still cover; ell_bound when unknown
float64 ell_bound               # declared bound on |ell|
bool healthy                    # pose fresh, inside the fence, estimator ok
