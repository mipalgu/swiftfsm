#include "cfsm_invoke.h"
#include <stdio.h>
#define DEBUG 


int loadMachine(void* p, const char *machine, bool initiallySuspended)
{
#ifdef DEBUG
   printf("loadMachine() - ptr: %p, machine path: %s, initsuspended: %d\n", p, machine, initiallySuspended);
#endif
   int (*f)(const char*, bool) = (int (*)(const char*, bool)) (p);
   return( f(machine, initiallySuspended) );
}

void destroyCFSM(void* p)
{
#ifdef DEBUG
    printf("destroyCFSM() - ptr: %p\n", p);
#endif
    void (*f)() = (void (*)()) (p);
    f();
}

