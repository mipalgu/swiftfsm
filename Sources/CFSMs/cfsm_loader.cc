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

//TODO: handle dynamic loading
//TODO: support loading when ".machine" path is supplied rather than ".so"

/// The vector of loaded machines.
std::vector<CLMachine*> finite_state_machines = std::vector<CLMachine*>();

/// The vector of machine library handles.
std::vector<void*> machine_lib_handles = std::vector<void*>();

/// The last machine ID assigned.
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
    int C_loadAndAddMachine(const char *machine, bool initiallySuspended)
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
    bool C_unloadMachineAtIndex(int index)
    {
        return FSM::unloadMachineAtIndex(index);
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
    int offset = 3; // Length of ".so"

    // If the .so path hasn't been provided, check if the .machine path was provided
    if (end == std::string::npos) 
    {
        std::size_t end = tmp.find_last_of(".machine");
        if (end == std::string::npos) return NULL; //.so or .machine path wasn't provided
        offset = 8; //Length of ".machine"
    }
    
    std::string n = tmp.substr(start + 1, (end - start - offset) );

    // Need to allocate memory for c-string as it only lives as long as the C++ string.
    char* name = (char*) calloc(strlen(n.c_str()) + 1, sizeof(char));
    strcpy(name, n.c_str());
    return name;
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

    // Get handle for machine library
    void* machine_lib_handle = dlopen(machine, RTLD_NOW);
    if (!machine_lib_handle) // Check if ".machine" path was provided rather than ".so" 
    {
        fprintf(stderr, "cfsm_loader(): Error opening machine library: dlerror(): %s\n", dlerror()); return CLError; 
    }

    // Get pointer to machine lib's create CL machine function
    const char* name = getMachineNameFromPath(machine);
    const char cl_create_function_name[] = "CLM_Create_";
    char create_machine_symbol[strlen(cl_create_function_name) + strlen(name) + 1];
    strcpy(create_machine_symbol, "CLM_Create_");
    strcat(create_machine_symbol, name);
    void* create_machine_ptr = dlsym(machine_lib_handle, create_machine_symbol);
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
    finite_state_machines.push_back(machine_ptr);
    int index = finite_state_machines.size() -1;
    set_number_of_machines(number_of_machines() + 1);

    // Suspend the machine if initiallySuspended
    if (initiallySuspended) { FSM::control_machine_at_index(index, CLSuspend); }


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

    // Place machine lib handle in lib handles vector so it can be closed later.
    machine_lib_handles.push_back(machine_lib_handle);

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
    if ( index < 0 || index > number_of_machines() ) return false;
    if ( !finite_state_machines[index] ) return false;
    finite_state_machines.erase(finite_state_machines.begin() + index);
    set_number_of_machines(number_of_machines() - 1);
    
    // Get machine lib handle for this machine and close the lib.
    void* machine_lib_handle = machine_lib_handles.at(index);
    if (dlclose(machine_lib_handle)) 
    { 
        fprintf(stderr, "Error closing machine library - dlerror(): %s\n", dlerror()); return CLError; 
    }

    return true;
}
