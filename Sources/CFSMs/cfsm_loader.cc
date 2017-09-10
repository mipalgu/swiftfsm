#include "cfsm_loader.h"
#include "cfsm_number_of_machines.h"
#include "cfsm_control.h"
#include "CLMachine.h"
#include <dlfcn.h>
#include <CLReflectAPI.h>
#include <stdlib.h>
#include <string>
#include <string.h>
#include <unistd.h>

#define DEBUG

#ifdef DEBUG
    #include<stdio.h>
#endif

using namespace FSM;

//TODO: handle dynamic loadin
//TODO: REFACTOR

/// The array of loaded machines
std::vector<CLMachine*> finite_state_machines = std::vector<CLMachine*>();

/// The last machine ID assigned
static int last_unique_id = -1;

extern "C"
{
    /**
     * Wrapper around CLMacros loadAndAddMachine that returns the machine ID
     *
     * @param machine path to the CL machine .so
     * @param initiallySuspended whether this machine starts suspended
     * @return the ID of the machine (-1 if an error occurred)
     */
    int _C_loadAndAddMachine(const char *machine, bool initiallySuspended)
    {
        int index = FSM::loadAndAddMachine(machine, initiallySuspended);
        if (index == -1) return index;
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
    char* name = (char*) calloc(strlen(n.c_str()) + 1, sizeof(char));
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
    for (int i = 0; i < number_of_machines(); i++)
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
 * @return the index of the loaded machine, -1 if an error occurred (CLError)
 */
int FSM::loadAndAddMachine(const char *machine, bool initiallySuspended)
{
#ifdef DEBUG
    printf("cfsm_loader() - loading machine: %s\n", machine);
#endif

    // Initialise the CFSM array.
    if (!finite_state_machines)
    {
        finite_state_machines = (CLMachine**) calloc(1, sizeof(CLMachine*));
        if (!finite_state_machines) { fprintf(stderr, "Error allocating memory for finite_state_machines array\n"); return CLError; }
    }

    // Get handle for machine library
    void* machine_lib_handle = dlopen(machine, RTLD_NOW);
    if (!machine_lib_handle) { fprintf(stderr, "Error opening machine lib - dlerror(): %s\n", dlerror()); return CLError; }

    // Get pointer to machine lib's create CL machine function
    const char* name = getMachineNameFromPath(machine);
    char* create_machine_symbol = (char*) calloc(11 + strlen(name) + 1, sizeof(char));
    strcpy(create_machine_symbol, "CLM_Create_");
    strcat(create_machine_symbol, name);
    void* create_machine_ptr = dlsym(machine_lib_handle, create_machine_symbol);
    free(create_machine_symbol); //<- double free when called more than once - is it being clever and reusing the address?
    if (!create_machine_ptr) { fprintf(stderr, "Error getting CL Create Machine symbol - dlerror(): %s\n", dlerror()); return CLError; }
    
    CLMachine* (*createMachine)(int, const char*) = (CLMachine* (*)(int, const char*)) (create_machine_ptr);
    if (!createMachine) { fprintf(stderr, "CL Create Machine function from dlsym is NULL\n"); return CLError; }

    // Call the machine lib's create CL machine function
    int machine_id = last_unique_id + 1;
    CLMachine* machine_ptr = createMachine(machine_id, name);
    printf("name ptr: %p\n", name);
    free((char*)(name));
    printf("finished free\n");

    if (!machine_ptr) { fprintf(stderr, "CL Create Machine return NULL\n"); return CLError; }
    last_unique_id = machine_id;

    // Create internal CL machine context for machine
    Machine *machine_context = createMachineContext(machine_ptr);
    if (!machine_context) { fprintf(stderr, "Error creating internal machine context"); return CLError; }
    machine_ptr->setMachineContext(machine_context);
    
    // Place machine in CFSM array
    int index = smallestUnusedIndex();

    if (index == -1)
    {

        finite_state_machines = (CLMachine**) realloc(finite_state_machines, (number_of_machines() + 1) * sizeof(CLMachine*));
        if (!finite_state_machines) { fprintf(stderr, "Reallocation of finite_state_machines array return NULL\n"); return CLError; }
        finite_state_machines[number_of_machines()] = machine_ptr;
        index = number_of_machines();
    }
    else
    {
        finite_state_machines[index] = machine_ptr; 
    }

    set_number_of_machines(number_of_machines() + 1);

    // Suspend the machine if initiallySuspended
    if (initiallySuspended) { control_machine_at_index(index, CLSuspend); }


#ifdef DEBUG
    printf("cfsm_loader() - CLMachine ptr: %p\n", machine_ptr);
#endif

    // Get pointer to machine lib's create metamachine function
    void* create_meta_machine_ptr = dlsym(machine_lib_handle, "Create_ScheduledMetaMachine");
    if (!create_meta_machine_ptr) { fprintf(stderr, "Error getting Create Meta Machine symbol - dlerror(): %s\n", dlerror());  return CLError; }
    refl_metaMachine (*createMetaMachine)(void*) = (refl_metaMachine (*)(void*)) (create_meta_machine_ptr);
    if (!createMetaMachine) { fprintf(stderr, "Create Meta Machine function pointer from dlsym is NULL\n"); return CLError; }

#ifdef DEBUG
    printf("cfsm_loader() - createMetaMachine ptr: %p\n", createMetaMachine);
#endif

    // Call the machine lib's create metamachine function
    refl_metaMachine meta_machine = createMetaMachine(machine_ptr);
    
    // Initialise CLReflect API and register metamachine
    CLReflectResult *result = (CLReflectResult*) calloc(1, sizeof(CLReflectResult));
    refl_initAPI(result);
    if (!result || *result != REFL_SUCCESS) { fprintf(stderr, "Error initialising CLReflect API\n"); return CLError; }
    refl_registerMetaMachine(meta_machine, machine_id, result);
    if (!result || *result != REFL_SUCCESS) { fprintf(stderr, "Error registering Meta Machine\n"); return CLError; }
    free(result);

#ifdef DEBUG
    printf("cfsm_loader() - meta machine ptr: %p\n", meta_machine);
    printf("cfsm_loader() - machine successfuly loaded, index: %d, ID: %d\n", index, machine_ptr->machineID());
#endif

    //if (dlclose(machine_lib_handle)) { fprintf(stderr, "Error closing machine library - dlerror(): %s\n", dlerror()); return CLError; }

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
#ifdef DEBUG
    printf("cfsm_loader() - unloading machine at index %d\n", index);
#endif
    if ( index > number_of_machines() ) return false;
    if ( !finite_state_machines[index] ) return false;
    finite_state_machines[index] = NULL;
    set_number_of_machines(number_of_machines() - 1);
    if (number_of_machines() < 0) _C_destroyCFSM();
    return true;
}
