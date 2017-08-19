#include "cfsm_load_and_add_machine.h"
#include "cfsm_number_of_machines.h"
#include <dlfcn.h>
#include <CLReflectAPI.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <iostream>

using namespace FSM;

CLMachine **finite_state_machines = NULL;

//TODO: findIndexForNewMachine - assign smallest unused index first, currently it increments and grows (however maintain unique ID)
//TODO: create StateMachineVector from fsm array

extern "C"
{
    int _C_loadAndAddMachine(const char *machine, bool initiallySuspended)
    {
        return FSM::loadAndAddMachine(machine, initiallySuspended);
    }
}

Machine *createMachineContext(CLMachine *machine)
{
    CLState *initial_state = machine->initialState();
    CLState *suspend_state = machine->suspendState();
    return new Machine(initial_state, suspend_state, false);
}

const char* getMachineNameFromPath(const char* path)
{
    std::string tmp = std::string(path);
    std::size_t start = tmp.find_last_of("/");
    std::size_t end = tmp.find_last_of(".so");
    std::string n = tmp.substr(start + 1, (end - start - 3) );
    char* name = (char*) calloc(1, sizeof(char*));
    strcpy(name, n.c_str());
    return name;
}

//TODO: refactor
//TODO: print dlerror() on dlopen/dlsym failure
int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
    //init the fsm array if it hasn't been done
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) return CLError;
    }
    
    //get new amount of machines/machine ID
    int number_of_fsms = number_of_machines() + 1;
    
    //get machine lib handle
    void* machine_lib_handle = dlopen(machine, RTLD_LAZY);
    if (!machine_lib_handle) { printf("dlerror(): %s\n", dlerror()); return CLError; }

    //get create CL machine function
    const char* name = getMachineNameFromPath(machine);
    char* create_machine_symbol = (char*) calloc(1, sizeof(char*));
    strcpy(create_machine_symbol, "CLM_Create_");
    strcat(create_machine_symbol, name);
    void* create_machine_ptr = dlsym(machine_lib_handle, create_machine_symbol);
    free(create_machine_symbol);
    free((char*)(name));
    if (!create_machine_ptr) return CLError;
    
    CLMachine* (*createMachine)(int, const char*) = (CLMachine* (*)(int, const char*)) (create_machine_ptr);
    if (!createMachine) return CLError;

    //get CL machine pointer
    CLMachine* machine_ptr = createMachine(number_of_fsms, name);
    if (!machine_ptr) return CLError;

    //create internal machine (CL machine context)
    Machine *machine_context = createMachineContext(machine_ptr);
    if (!machine_context) return CLError;
    machine_ptr->setMachineContext(machine_context);

    //realloc array and place machine pointer at index number_of_machines + 1
    finite_state_machines = (CLMachine**) realloc(finite_state_machines, (number_of_fsms + 1) * sizeof(CLMachine*));
    if (!finite_state_machines) return CLError;

    finite_state_machines[number_of_fsms] = machine_ptr;
    set_number_of_machines(number_of_fsms);
    
    //get create meta machine function
    void* create_meta_machine_ptr = dlsym(machine_lib_handle, "Create_ScheduledMetaMachine");
    if (!create_meta_machine_ptr) return CLError;
    refl_metaMachine (*createMetaMachine)(void*) = (refl_metaMachine (*)(void*)) (create_meta_machine_ptr);
    if (!createMetaMachine) return CLError;

    //get meta machine
    refl_metaMachine meta_machine = createMetaMachine(machine_ptr);

    //init CLReflect API and register metamachine
    CLReflectResult *result = (CLReflectResult*) calloc(1, sizeof(CLReflectResult));
    refl_initAPI(result);
    if (!result || *result != REFL_SUCCESS) return CLError;
    refl_registerMetaMachine(meta_machine, number_of_fsms, result);
    if (!result || *result != REFL_SUCCESS) return CLError;
    free(result);

    return number_of_fsms;
}


