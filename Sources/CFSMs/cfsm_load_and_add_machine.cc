#include "cfsm_load_and_add_machine.h"
#include "StateMachineVector.h"
#include "CLMachine.h"
#include "cfsm_number_of_machines.h"
#include <stdlib.h>

using namespace FSM;

extern CLMachine **finite_state_machines;
CLMachine **finite_state_machines = NULL;


//TODO: delegate this to swiftfsm/CLFSMMachineLoader to dynamically load machines
//TODO: findIndexForNewMachine - assign smallest unused index first, currently it increments and grows
int loadAndAddMachine(const char *machine, bool initiallySuspended = false)
{
    //init the fsm array if it hasn't been done
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) return CLError;
    }

    //in swiftfsm, call dlopen on path and get CLMachine pointer
    CLMachine *machinePtr = NULL;
    
    //if we can't get pointer, return CLError

    //get the new amount of machines
    int number_of_fsms = number_of_machines() + 1;

    //realloc array and place machine pointer at index number_of_machines + 1
    finite_state_machines = (CLMachine**) realloc(finite_state_machines, (number_of_fsms) * sizeof(CLMachine*));
    if (!finite_state_machines) return CLError;
    finite_state_machines[number_of_fsms] = machinePtr;

    set_number_of_machines(number_of_fsms);

    //get metamachine pointer and register meta machine

    return number_of_fsms;
}




    
