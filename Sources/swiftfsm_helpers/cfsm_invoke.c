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

