#include "cfsm_invoke.h"
#include <stdio.h>

/**
 * Calls the CFSM machine loader
 *
 * @param p pointer to the CFSM loader function
 * @param machine path of the machine to load
 * @param whether this machine starts suspended
 *
 * @return the ID of the loaded machine
 */
int loadMachine(void* p, const char *machine, bool initiallySuspended)
{
   int (*f)(const char*, bool) = (int (*)(const char*, bool)) (p);
   return( f(machine, initiallySuspended) );
}

/**
 * Calls the CFSM machine unloader.
 *
 * @param p pointer the CFSM unload function
 * @param id the id of the machine to unload 
 *
 * @return whether the machine successfully unloaded
 */
bool unloadMachine(void* p, int id)
{
    bool (*f)(int) = (bool (*)(int)) (p);
    return( f(id) );
}

/**
 * Gets the vector of dynamically loaded machine IDs from CFSM.
 *
 * @param p pointer to the CFSM function.
 *
 * @return array of loaded machine IDs.
 */
int* getLoadedMachines(void* p) 
{
    int* (*f)() = (int* (*)()) (p);
    return( f() );
}

/**
 * Gets the number of dynamically loaded machine IDs from CFSM.
 *
 * @param p pointer to the CFSM function.
 *
 * @return the number of dynamically loaded machines.
 */
int numberOfLoadedMachines(void* p)
{
    int (*f)() = (int (*)()) (p);
    return f();
}


/**
 * Empties the dynamically loaded machine ID vector in CFSM.
 *
 * @param p pointer to the CFSM function.
 */
void emptyLoadedMachines(void* p)
{
    void (*f)() = (void (*)()) (p);
    return f();
}

/**
 * Checks if machine ID belongs to unloaded machine.
 *
 * @param p pointer to the CFSM function.
 * @param id machine ID to check.
 *
 * @return whether this machine ID belonds to unloaded machine.
 */
bool checkUnloadedMachines(void* p, int id)
{
    bool (*f)(int) = (bool (*)(int)) (p);
    return( f(id) );
}

