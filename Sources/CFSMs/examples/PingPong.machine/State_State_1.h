//
// State_State_1.h
//
// Automatically created through MiPalCASE -- do not change manually!
//
#ifndef clfsm_PingPong_State_State_1_h
#define clfsm_PingPong_State_State_1_h

#include "CLState.h"
#include "CLAction.h"
#include "CLTransition.h"

namespace FSM
{
    namespace CLM
    {
      namespace FSMPingPong
      {
        namespace State
        {
            class State_1: public CLState
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
                    State_1(const char *name = "State_1");
                    virtual ~State_1();

                    virtual CLTransition * const *transitions() const { return _transitions; }
                    virtual int numberOfTransitions() const { return 1; }

#                   include "State_State_1_Variables.h"
#                   include "State_State_1_Methods.h"
            };
        }
      }
    }
}

#endif
