# One vehicle as the coordinator sees it (element of ResetFleet).
string vehicle                  # namespace, e.g. ugv1
uint32 session
uint8 phase                     # ResetSession.PHASE_*
uint8 grant_state               # ResetGrant.STATE_* of the last message sent
uint8 reason                    # ResetGrant.REASON_*
float64 progress                # arc length travelled [m]
float64 remaining               # arc length left on the route [m]
bool lost                       # no session message for 3 s: kept as a parked body at its last pose
string[] blockers
