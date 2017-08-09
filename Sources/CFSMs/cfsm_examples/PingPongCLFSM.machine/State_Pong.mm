//
// State_Pong.mm
//
// Automatically created through MiCASE -- do not change manually!
//
#include "PingPongCLFSM_Includes.h"
#include "PingPongCLFSM.h"
#include "State_Pong.h"

#include "State_Pong_Includes.h"

using namespace FSM;
using namespace CLM;
using namespace FSMPingPongCLFSM;
using namespace State;

Pong::Pong(const char *name): CLState(name, *new Pong::OnEntry, *new Pong::OnExit, *new Pong::Internal)
{
	_transitions[0] = new Transition_0();
}

Pong::~Pong()
{
	delete &onEntryAction();
	delete &onExitAction();
	delete &internalAction();

	delete _transitions[0];
}

void Pong::OnEntry::perform(CLMachine *_machine, CLState *_state) const
{
#	include "PingPongCLFSM_VarRefs.mm"
#	include "State_Pong_VarRefs.mm"
#	include "State_Pong_OnEntry.mm"
}

void Pong::OnExit::perform(CLMachine *_machine, CLState *_state) const
{
#	include "PingPongCLFSM_VarRefs.mm"
#	include "State_Pong_VarRefs.mm"
#	include "State_Pong_OnExit.mm"
}

void Pong::Internal::perform(CLMachine *_machine, CLState *_state) const
{
#	include "PingPongCLFSM_VarRefs.mm"
#	include "State_Pong_VarRefs.mm"
#	include "State_Pong_Internal.mm"
}

bool Pong::Transition_0::check(CLMachine *_machine, CLState *_state) const
{
#	include "PingPongCLFSM_VarRefs.mm"
#	include "State_Pong_VarRefs.mm"

	return
	(
#		include "State_Pong_Transition_0.expr"
	);
}
