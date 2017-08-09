//
// PingPong.mm
//
// Automatically created through MiPalCASE -- do not change manually!
//
#include "PingPong_Includes.h"
#include "PingPong.h"

#include "State_Initial.h"
#include "State_Suspend.h"
#include "State_Ping.h"
#include "State_State_1.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	PingPong *CLM_Create_PingPong(int mid, const char *name)
	{
		return new PingPong(mid, name);
	}
}

PingPong::PingPong(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMPingPong::State::Initial;
	_states[1] = new FSMPingPong::State::Suspend;
	_states[2] = new FSMPingPong::State::Ping;
	_states[3] = new FSMPingPong::State::State_1;

	setSuspendState(_states[1]);            // set suspend state
	setInitialState(_states[0]);            // set initial state
}

PingPong::~PingPong()
{
	delete _states[0];
	delete _states[1];
	delete _states[2];
	delete _states[3];
}
