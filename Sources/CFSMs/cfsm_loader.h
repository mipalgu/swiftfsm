#include "CLMacros.h"
#include "CLMachine.h"
#include "CLState.h"

extern FSM::CLMachine **finite_state_machines;

extern "C"{
void _C_destroyCFSM();
}
