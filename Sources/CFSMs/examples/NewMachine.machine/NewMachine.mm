//
// NewMachine.mm
//
// Automatically created through MiPalCASE -- do not change manually!
//
#include "NewMachine_Includes.h"
#include "NewMachine.h"

#include "State_Initial.h"
#include "State_Suspend.h"
#include "State_Ping.h"
#include "State_State_1.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	NewMachine *CLM_Create_NewMachine(int mid, const char *name)
	{
		return new NewMachine(mid, name);
	}
}

NewMachine::NewMachine(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMNewMachine::State::Initial;
	_states[1] = new FSMNewMachine::State::Suspend;
	_states[2] = new FSMNewMachine::State::Ping;
	_states[3] = new FSMNewMachine::State::State_1;

	setSuspendState(_states[1]);            // set suspend state
	setInitialState(_states[0]);            // set initial state
}

NewMachine::~NewMachine()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
}
