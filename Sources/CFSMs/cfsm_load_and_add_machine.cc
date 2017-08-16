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
#include <iostream>

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
    std::string n = tmp.substr(start + 1, (end - start - 3) );
    char* name = (char*) calloc(1, sizeof(char*));
    strcpy(name, n.c_str());
    return name;
}

//TODO: print dlerror() on dlopen/dlsym failure
int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
    printf("one\n");
    //init the fsm array if it hasn't been done
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) return CLError;
    }
    printf("two\n");
    //get new amount of machines/machine ID
    int number_of_fsms = number_of_machines() + 1;
    
    //get machine lib handle
    void* machine_lib_handle = dlopen(machine, RTLD_LAZY);
    if (!machine_lib_handle) { printf("dlerror(): %s\n", dlerror()); return CLError; }
    printf("three\n");

    //get create CL machine function
    const char* name = getMachineNameFromPath(machine);
    char* create_machine_symbol = (char*) calloc(1, sizeof(char*));
    strcpy(create_machine_symbol, "CLM_Create_");
    strcat(create_machine_symbol, name);
    printf("symbol: %s\n", create_machine_symbol);
    void* create_machine_ptr = dlsym(machine_lib_handle, create_machine_symbol);
    if (!create_machine_ptr) return CLError;
    //free(&create_machine_symbol);
    printf("four\n");

    CLMachine* (*createMachine)(int, const char*) = (CLMachine* (*)(int, const char*)) (create_machine_ptr);
    if (!createMachine) return CLError;
    printf("five\n");

    //get CL machine pointer
    CLMachine* machine_ptr = createMachine(number_of_fsms, name);
    if (!machine_ptr) return CLError;
    printf("six\n");

    printf("number of fsms: %d\n", number_of_fsms);

    //realloc array and place machine pointer at index number_of_machines + 1
    finite_state_machines = (CLMachine**) realloc(finite_state_machines, (number_of_fsms + 1) * sizeof(CLMachine*));
    if (!finite_state_machines) return CLError;
    printf("seven\n");

    finite_state_machines[number_of_fsms] = machine_ptr;
    printf("machine ptr at [0]: %p\n", finite_state_machines[0]);
    CLMachine *test = finite_state_machines[0];
    std::cout << "test name: " << test->machineID() << std::endl;
    set_number_of_machines(number_of_fsms);
    
    //get create meta machine function
    void* create_meta_machine_ptr = dlsym(machine_lib_handle, "Create_ScheduledMetaMachine");
    if (!create_meta_machine_ptr) return CLError;
    printf("eight\n");

    refl_metaMachine (*createMetaMachine)(void*) = (refl_metaMachine (*)(void*)) (create_meta_machine_ptr);
    if (!createMetaMachine) return CLError;
    printf("nine\n");

    //get meta machine
    refl_metaMachine meta_machine = createMetaMachine(machine_ptr); //TODO: change create func so it gets machine from fsm array rather than passing pointer
    printf("nine and a half\n");

    //init CLReflect API and register metamachine
    //CLReflectResult* result;
    refl_initAPI(NULL);
    //if (!result || *result != REFL_SUCCESS) return CLError;
    printf("ten\n");

    refl_registerMetaMachine(meta_machine, number_of_fsms, NULL);
    //if (!result || *result != REFL_SUCCESS) return CLError;
    printf("eleven\n");

    printf("machine name: %s\n", name_of_machine_at_index(0));

    return number_of_fsms;
}


