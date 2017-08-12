#include "cfsm_load.h"
#include <CLReflectAPI.h>
#include <stdio.h>
   
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

  void set_number_of_machines(void* p, int n)
  {
      void* (*f)(int*) = (void* (*)(int*)) (p);
      f(n);
  }


   void registerMetaMachine(void* metaMachine, unsigned int machineID)
   {
       
       CLReflectResult* result;

       refl_initAPI(result);
       if (*result == REFL_SUCCESS) printf ("CLReflect API successfully initialised\n");

       refl_metaMachine machine = (refl_metaMachine) (metaMachine);
       refl_registerMetaMachine(machine, machineID, result);
       if (*result == REFL_INVALID_ARGS) 
       { 
           printf("registerMetaMachine: REFL_INVALID_ARGS\n");
       }
       else if (*result == REFL_SUCCESS)
       {
           printf("registerMetaMachine: REFL_SUCCESS\n");
        }
       else
        {
            printf("registerMetaMachine: WHAT HAPPEN\n");
        }

        refl_invokeOnEntry(machine,0 , result);
        if (*result == REFL_SUCCESS) printf ("invokeOnEntry: REFL_SUCCESS\n");
       
    }

