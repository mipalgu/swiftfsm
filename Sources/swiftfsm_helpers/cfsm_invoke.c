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
#ifdef DEBUG
   printf("loadMachine() - ptr: %p, machine path: %s, initsuspended: %d\n", p, machine, initiallySuspended);
#endif
   int (*f)(const char*, bool) = (int (*)(const char*, bool)) (p);
#ifdef DEBUG
   printf("loadMachine() - casted function pointer successfully\n");
#endif
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
 * Destroys CFSM
 *
 * @param p pointer to the destroy CFSM function
 */
void destroyCFSM(void* p)
{
#ifdef DEBUG
    printf("destroyCFSM() - ptr: %p\n", p);
#endif
    void (*f)() = (void (*)()) (p);
    f();
}

int* getLoadedMachines(void* p) 
{
    int* (*f)() = (int* (*)()) (p);
    return( f() );
}

int* getUnloadedMachines(void* p)
{
    int* (*f)() = (int* (*)()) (p);
    return ( f() );
}

int numberOfLoadedMachines(void* p)
{
    int (*f)() = (int (*)()) (p);
    return f();
}

int numberOfUnloadedMachines(void* p)
{
    int (*f)() = (int (*)()) (p);
    return f();
}
