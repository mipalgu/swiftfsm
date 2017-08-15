#include "cfsm_current_state_of_machine.h"
#include "CLMachine.h"
#include "CLState.h"

FSM::CLState *current_state_of_machine(FSM::CLMachine *machine)
{
    return machine->currentState();
}
