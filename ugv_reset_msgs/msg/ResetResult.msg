# The one outcome of a Reset session, vehicle -> everyone on <ns>/reset/result (latched).
# Exactly one per session; the vehicle goes to Ready after it (the exact zero command is held).
std_msgs/Header header
uint32 session

uint8 OUTCOME_ARRIVED=1                 # within 5 cm and 5 deg of the target and measured stopped
uint8 OUTCOME_TIMEOUT=2                 # the vehicle's own 90 s deadline
uint8 OUTCOME_STOPPED=3                 # /command stop
uint8 OUTCOME_REJECTED_NO_TARGET=10     # no initialPose cached: held at most 2 s
uint8 OUTCOME_REJECTED_NO_COORDINATOR=11  # no grant or hold within 2 s
uint8 OUTCOME_REJECTED_BY_COORDINATOR=12  # a REJECT grant; reason carries its REASON_*
uint8 OUTCOME_INFEASIBLE=20             # a REJECT the planner proved: reason carries its REASON_*
uint8 OUTCOME_ABORTED_DEVIATION=30      # left the route tube
uint8 OUTCOME_ABORTED_STALLED=31        # no progress for 10 s
uint8 OUTCOME_ABORTED_COORDINATOR_LOST=32  # moving without a heartbeat for 1 s
uint8 OUTCOME_ABORTED_UNHEALTHY=33      # pose lost, outside the fence (the controller goes to SelfCheck)
uint8 outcome

uint8 reason                    # ResetGrant.REASON_* when the coordinator ended the session, else 0
float64 final_planar_error      # [m] at the end
float64 final_yaw_error         # [rad], shortest angle
float64 duration                # [s] from entering Reset
string detail                   # one line: the first cause
