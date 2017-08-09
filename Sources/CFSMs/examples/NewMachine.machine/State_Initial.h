//
// State_Initial.h
//
// Automatically created through MiPalCASE -- do not change manually!
//
#ifndef clfsm_NewMachine_State_Initial_h
#define clfsm_NewMachine_State_Initial_h

#include "CLState.h"
#include "CLAction.h"
#include "CLTransition.h"

namespace FSM
{
    namespace CLM
    {
      namespace FSMNewMachine
      {
        namespace State
        {
            class Initial: public CLState
            {
                class OnEntry: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class OnExit: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Internal: public CLAction
                {
                    virtual void perform(CLMachine *, CLState *) const;
                };

                class Transition_0: public CLTransition
                {
                public:
                    Transition_0(int toState = 2): CLTransition(toState) {}

                    virtual bool check(CLMachine *, CLState *) const;
                };

                CLTransition *_transitions[1];

                public:
                    Initial(const char *name = "Initial");
                    virtual ~Initial();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_Initial_Variables.h"
#                   include "State_Initial_Methods.h"
            };
        }
      }
    }
}

#endif
