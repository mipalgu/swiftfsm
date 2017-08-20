#include "cfsm_loader.h"
#include "cfsm_number_of_machines.h"
#include <dlfcn.h>
#include <CLReflectAPI.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <stdio.h>
#include <unistd.h>

#define DEBUG

using namespace FSM;

//TODO: handle dynamic loadin

/// The array of loaded machines
CLMachine **finite_state_machines = NULL;

/// The last machine ID assigned
int last_unique_id = -1;

extern "C"
{
    /**
     * Wrapper around CLMacros loadAndAddMachine that returns the machine ID
     *
     * @param machine path to the CL machine .so
     * @param initiallySuspended whether this machine starts suspended
     * @return the ID of the machine
     */
    int _C_loadAndAddMachine(const char *machine, bool initiallySuspended)
    {
        int index = FSM::loadAndAddMachine(machine, initiallySuspended);
        CLMachine *m = machine_at_index(index);
        return m->machineID();
    }
    
    /**
     * Wrapper around CLMacros unloadMachineAtIndex
     *
     * @param index index of machine to unload
     * @return whether the machine successfully unloaded
     */
    bool _C_unloadMachineAtIndex(int index)
    {
        return FSM::unloadMachineAtIndex(index);
    }

    /*
     * Destroys the finite state machine array and CLReflect API
     */
    void _C_destroyCFSM()
    {
        free(finite_state_machines);
        refl_destroyAPI(NULL);
    }
}

/**
 * Creates the internal Machine context of a CL Machine
 *
 * @param machine the CL Machine to create the context for
 * @return the internal machine context
 */
Machine *createMachineContext(CLMachine *machine)
{
    CLState *initial_state = machine->initialState();
    CLState *suspend_state = machine->suspendState();
    return new Machine(initial_state, suspend_state, false);
}

/**
 * Gets the machine name from the supplied path
 *
 * @param path the path of the CLMachine .so
 * @return the machine name
 */
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

/**
 * Gets the smallest unused index from the finite_state_machines array
 *
 * @return the smallest unused index, -1 if there is not enough room in the array
 */
int smallestUnusedIndex()
{
    int no_index = -1;
    for (int i = 0; i < number_of_machines() + 1; i++)
    {
        if (finite_state_machines[i] == 0 || finite_state_machines[i] == NULL) return i;
    }
    return no_index;
}

/**
 * Load a CLMachine and associated Meta Machine
 *
 * @param machine the path to the CLMachine .so
 * @param initiallySuspended whether this machine starts suspended
 * @return the index of the loaded machine
 */
int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) return CLError;
    }
    
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
    if (!create_machine_ptr) return CLError;
    
    CLMachine* (*createMachine)(int, const char*) = (CLMachine* (*)(int, const char*)) (create_machine_ptr);
    if (!createMachine) return CLError;

    //get CL machine pointer
    int machine_id = last_unique_id + 1;
    CLMachine* machine_ptr = createMachine(machine_id, name);
    free((char*)(name));
    if (!machine_ptr) return CLError;
    last_unique_id = machine_id;

    //create internal machine (CL machine context)
    Machine *machine_context = createMachineContext(machine_ptr);
    if (!machine_context) return CLError;
    machine_ptr->setMachineContext(machine_context);

    int index = smallestUnusedIndex();
    if (index == -1)
    {
        //realloc array and place machine pointer at index number_of_machines + 1
        finite_state_machines = (CLMachine**) realloc(finite_state_machines, (number_of_machines() + 1) * sizeof(CLMachine*));
        finite_state_machines[number_of_machines()] = machine_ptr;
        if (!finite_state_machines) return CLError;
        index = number_of_machines();
    }
    else
    {
        finite_state_machines[index] = machine_ptr; 
    }

    set_number_of_machines(number_of_machines() + 1);
    
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
    refl_registerMetaMachine(meta_machine, machine_id, result);
    if (!result || *result != REFL_SUCCESS) return CLError;
    free(result);

    #ifdef DEBUG
    printf("cfsm_load_and_add_machine() - machine successfuly loaded, index: %d, ID: %d\n", index, machine_ptr->machineID());
    #endif

    return index;
}

/**
 * Unloads the machine at the given index
 *
 * @param index index of the machine to unload
 * @return true on success, false on failure
 */
bool FSM::unloadMachineAtIndex(int index)
{
    if ( index > number_of_machines() ) return false;
    if ( !finite_state_machines[index] ) return false;
    finite_state_machines[index] = NULL;
    set_number_of_machines(number_of_machines() - 1);
    if (number_of_machines() < 0) _C_destroyCFSM();
    return true;
}
