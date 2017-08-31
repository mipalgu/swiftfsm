#include "cfsm_loader.h"
#include <unistd.h>
int main()
{
    for (int i = 0; i < 10; i++)
    {
        FSM::loadAndAddMachine("/home/bren/iap_thesis/fsms/clreflect-debug/PingPongCLFSM.machine/Linux-x86_64/PingPongCLFSM.so");
        sleep(1);
    }
    _C_destroyCFSM();
    return 0;
}
