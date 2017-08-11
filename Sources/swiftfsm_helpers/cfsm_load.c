#include "cfsm_load.h"
//#include "CLReflectAPI.h"

   void* testMachineFactory(void* p)
   {
       void* (*f)(int, const char*) = (void* (*)(int, const char*)) (p);
       return( f(0, "PingPongCLFSM") );
   }

   void* testCreateMetaMachine(void* p)
   {
       void* (*f)() = (void*) (p);
       return( f() );
   }

   void* createScheduledMetaMachine(void* p, void* machine)
   {
       void* (*f)(void*) = (void* (*)(void*)) (p);
       return( f(machine) );
    }
