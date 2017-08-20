#include "cfsm_current_state_of_machine.h"
#include "CLMachine.h"
#include "CLState.h"

/**
 * Returns the current state of a CLMachine
 *
 * @param machine the CLMachine to get the current state of
 * @return the machine's current state as a CLState
 */
FSM::CLState *current_state_of_machine(FSM::CLMachine *machine)
{
    FSM::Machine *context = machine->machineContext();
    return context->currentState();
}
