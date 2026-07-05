uint8 PHASE_TRANSITION=1
uint8 PHASE_TICK=2

uint8 KIND_INTERNAL_EVENT_GENERATED=1
uint8 KIND_OUTPUT_EVENT_GENERATED=2
uint8 KIND_EVENT_CONSUMED=3
uint8 KIND_TRANSITION_COMMITTED=4
uint8 KIND_INTERNAL_EVENT_DEFERRED=5

uint8 CATEGORY_INPUT=1
uint8 CATEGORY_INTERNAL=2
uint8 CATEGORY_OUTPUT=3

uint8 phase
uint8 kind
uint32 event_id
string event_name
uint8 category
string source
uint64 sequence
uint64 correlation_id
uint32 producer_region
uint32 producer_state
uint32 consumer_region
uint32 from_state
uint32 to_state
uint64 transition_id
int32 priority
