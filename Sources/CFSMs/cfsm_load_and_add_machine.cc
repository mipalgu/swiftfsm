#include "cfsm_load_and_add_machine.h"
#include "StateMachineVector.h"
#include "cfsm_number_of_machines.h"
#include <dlfcn.h>
#include <CLReflectAPI.h>
#include <stdlib.h>
#include <string>
#include <stdio.h>

using namespace FSM;

CLMachine **finite_state_machines = NULL;

//TODO: findIndexForNewMachine - assign smallest unused index first, currently it increments and grows
//TODO: create StateMachineVector from fsm array

extern "C"
{
    int _C_loadAndAddMachine(const char *machine, bool initiallySuspended)
    {
        return FSM::loadAndAddMachine(machine, initiallySuspended);
    }
}

const char* getMachineNameFromPath(const char* path)
{
    std::string tmp = std::string(path);
    std::size_t start = tmp.find_last_of("/");
    std::size_t end = tmp.find_last_of(".so");
    std::string name = tmp.substr(start + 1, (end - start - 3) );
    return name.c_str();
}

int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
    const char* name = getMachineNameFromPath(machine);
    printf("name: %s, ptr: %p\n", name, name);
    /*
    //init the fsm array if it hasn't been done
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) return CLError;
    }

    //call dlopen on path and get CLMachine pointer and metamachine pointer
    void* machineLibHandle = dlopen(machine, RTLD_LAZY);
    if (!machineLibHandle) return CLError;
    
    CLMachine *machinePtr = NULL; //(CLMachine*) dlsym(machineLibHandle);
    refl_metaMachine metaMachine = NULL;

    //if we can't get pointer, return CLError

    //get the new amount of machines
    int number_of_fsms = number_of_machines() + 1;

    //realloc array and place machine pointer at index number_of_machines + 1
    finite_state_machines = (CLMachine**) realloc(finite_state_machines, (number_of_fsms) * sizeof(CLMachine*));
    if (!finite_state_machines) return CLError;

    finite_state_machines[number_of_fsms] = machinePtr;

    //init CLReflect API and register metamachine
    CLReflectResult* result;
    refl_initAPI(result);
    if (!result || *result != REFL_SUCCESS) return CLError;

    refl_registerMetaMachine(metaMachine, number_of_fsms, result);
    if (!result || *result != REFL_SUCCESS) return CLError;


    set_number_of_machines(number_of_fsms);

    //get metamachine pointer and register meta machine

    return number_of_fsms;
    */
    return 0;
}


