#include "cfsm_load.h"
#include <CLReflectAPI.h>
#include <stdio.h>
#define DEBUG 

   void* createMachine(void* p)
   {
       void* (*f)(int, const char*) = (void* (*)(int, const char*)) (p);
       return( f(0, "PingPongCLFSM") );
   }

   void* createMetaMachine(void* p, void* machine)
   {
       void* (*f)(void*) = (void* (*)(void*)) (p);
       return( f(machine) );
    }

  void incrementNumberOfMachines(void* p)
  {
      void* (*f)() = (void*) (p);
      f();
#ifdef DEBUG      
      printf("Incremented machine count\n");
#endif
  }


   //Keep for testing but needs to be removed once CLRelfect is called from swiftfsm
   void registerMetaMachine(void* metaMachine, unsigned int machineID)
   {
       
       CLReflectResult* result;
       
       refl_initAPI(result);
       if (*result == REFL_SUCCESS) printf ("CLReflect API successfully initialised\n");

       refl_metaMachine machine = (refl_metaMachine) (metaMachine);
       refl_registerMetaMachine(machine, machineID, result);
       
#ifdef DEBUG
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
#endif
        
        refl_invokeOnEntry(machine,0 , result);
#ifdef DEBUG
        if (*result == REFL_SUCCESS) printf ("invokeOnEntry: REFL_SUCCESS\n");
#endif
    }

