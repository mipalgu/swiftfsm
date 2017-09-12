#include "cfsm_invoke.h"
#include <stdio.h>
#define DEBUG 

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
#ifdef DEBUG
    printf("unloadMachine() - ptr: %p, id: %d\n", p, id);
#endif
    bool (*f)(int) = (bool (*)(int)) (p);
    return( f(id) );
}

/**
 * Gets the vector of dynamically loaded machine IDs from CFSM.
 *
 * @param p pointer to the CFSM function.
 *
 * @return 
 */
int* getLoadedMachines(void* p) 
{
    int* (*f)() = (int* (*)()) (p);
    return( f() );
}

/**
 * Gets the vector of dynamically unloaded machine IDs from CFSM.
 *
 * @param p pointer to the CFSM function.
 *
 * @return
 */
int* getUnloadedMachines(void* p)
{
    int* (*f)() = (int* (*)()) (p);
    return ( f() );
}

/**
 * Gets the number of dynamically loaded machine IDs from CFSM.
 *
 * @param p pointer to the CFSM function.
 *
 * @return
 */
int numberOfLoadedMachines(void* p)
{
    int (*f)() = (int (*)()) (p);
    return f();
}

/**
 * Gets the number of dynamically unloaded machine IDs from CFSM.
 *
 * @param p pointer to the CFSM function.
 *
 * @return
 */
int numberOfUnloadedMachines(void* p)
{
    int (*f)() = (int (*)()) (p);
    return f();
}
