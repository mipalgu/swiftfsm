//
// PingPongCLFSM.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "PingPongCLFSM_Includes.h"
#include "PingPongCLFSM.h"

#include "State_Ping.h"
#include "State_Pong.h"

using namespace FSM;
using namespace CLM;

extern "C"
{
	PingPongCLFSM *CLM_Create_PingPongCLFSM(int mid, const char *name)
	{
		return new PingPongCLFSM(mid, name);
	}
}

PingPongCLFSM::PingPongCLFSM(int mid, const char *name): CLMachine(mid, name)
{
	_states[0] = new FSMPingPongCLFSM::State::Ping;
	_states[1] = new FSMPingPongCLFSM::State::Pong;

	setInitialState(_states[0]);            // set initial state
}

PingPongCLFSM::~PingPongCLFSM()
{
	delete _states[0];
	delete _states[1];
}
