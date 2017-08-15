#include "cfsm_number_of_machines.h"

int number_of_clmachines = 0;

extern "C" {
    void increment_number_of_machines(int n)
    {   
        number_of_clmachines++;
    }

    void decrement_number_of_machines(int n)
    {
        number_of_clmachines--;
    }
}

int FSM::number_of_machines(void)
{
    return number_of_clmachines;
}

