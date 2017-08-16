#include "cfsm_load_and_add_machine.h"
#include "StateMachineVector.h"
#include "cfsm_number_of_machines.h"
#include <dlfcn.h>
#include <CLReflectAPI.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

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
    char* csymbol = (char*) calloc(1, sizeof(symbol.c_str()));
    strcpy(csymbol, symbol.c_str());
    return csymbol;
}

int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
    //init the fsm array if it hasn't been done
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) return CLError;
    }

    //get machine lib handle
    void* machineLibHandle = dlopen(machine, RTLD_LAZY);
    if (!machineLibHandle) return CLError;
   
    //get pointers to create machine and metamachine functions
    const char* createMachineSymbol = getCreateMachineSymbol(machine);
    void* createMachinePtr = dlsym(machineLibHandle, createMachineSymbol);
    if (!createMachinePtr) return CLError;
    CLMachine* (*createMachine)(int, const char*) = (CLMachine* (*)(int, const char*)) (createMachinePtr);
    //CLMachine* m = createMachine(


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
}


