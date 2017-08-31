#include <CLMacros.h>
#include "CLMachine.h"
#include "CLState.h"

extern FSM::CLMachine **finite_state_machines;

extern int last_unique_id;
extern "C"{
void _C_destroyCFSM();
}
