#include "cfsm_test.h"

   void* testMachineFactory(void* p)
   {
       void* (*f)(int, const char*) = (void* (*)(int, const char*)) (p);
       return( f(0, "PingPongCLFSM") );
   }
