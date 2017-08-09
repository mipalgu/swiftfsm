#include "cfsm_scheduler.h"
#include "StateMachineVector.h"
#include "CLMachine.h"
#include <stdlib.h>
#include <sys/time.h>
#include <sys/param.h>
#include <time.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wglobal-constructors"
#pragma clang diagnostic ignored "-Wexit-time-destructors"

using namespace FSM;

extern FSM::CLMachine *finite_state_machines[1];
extern unsigned char number_of_fsms;

FSM::StateMachineVector stateMachineVector(finite_state_machines, number_of_fsms);

extern "C"
{
    int main(int argc, char *argv[])
    {
        //setup
        for (unsigned char i = 0; i < number_of_fsms; i++)
        {
            CLMachine *m = finite_state_machines[i];
            m->setCurrentState(m->initialState());
        }

        //no idea what this is
        const struct timespec nanotime =
        {
            0, argc > 1 ? 1000000L * atol(argv[1]) : 10000000L
        };

        do
        { 
            if (!stateMachineVector.executeOnce()) nanosleep(&nanotime, NULL);
        }
        while (!stateMachineVector.accepting());

        return 0;
    }
}
