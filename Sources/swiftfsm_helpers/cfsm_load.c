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

void printResult(CLReflectResult* result)
{
    switch(*result)
    {
        case REFL_SUCCESS:
            printf("REFL_SUCCESS\n");
            break;

        case REFL_INVALID_CALL:
            printf("REFL_INVALID_CALL\n");
            break;

        case REFL_INVALID_ARGS:
            printf("REFL_INVALID_ARGS\n");
            break;

        case REFL_BUFFER_OVERFLOW:
            printf("REFL_BUFFER_OVERFLOW\n");
            break;

        case REFL_UNKNOWN_ERROR:
            printf("REFL_UNKNOWN_ERROR\n");
            break;

        default:
            printf("Could not get CLReflectResult\n");
            break;
    }
}

void initCLReflectAPI()
{
    CLReflectResult* result;
    refl_initAPI(result);
#ifdef DEBUG
    printf("initCLReflectAPI: ");
    printResult(result);
#endif
}

void registerMetaMachine(refl_metaMachine metaMachine, unsigned int mid)
{
    CLReflectResult* result;
    refl_registerMetaMachine(metaMachine, 0, result);
#ifdef DEBUG
    printf("registerMetaMachine: ");
    printResult(result);
#endif
}

//test function, to be removed
void invokeOnEntry(void* m, unsigned int statenum)
{
    CLReflectResult* result;
    refl_metaMachine machine = (refl_metaMachine) (m);
    refl_invokeOnEntry(machine, statenum, result);
#ifdef DEBUG
    printf("invokeOnEntry: ");
    printResult(result);
#endif
}

void loadMachine(void* createMachineP, void* createMetaMachineP, unsigned int mid)
{
    void* machinePointer = createMachine(createMachineP);
    refl_metaMachine metaMachine = (refl_metaMachine) (createMetaMachine(createMetaMachineP, machinePointer));
    //incrementNumberOfMachines    
    //initCLReflectAPI(); //<--segfault
    //CLReflectResult* result;
    //refl_initAPI(result);
    //printResult(result);
    //registerMetaMachine(metaMachine, mid); //<--segfault
    //refl_registerMetaMachine(metaMachine, mid, result);
    //printResult(result);
}

