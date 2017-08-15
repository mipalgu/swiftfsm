/*
 *  CLMacros.h
 *
 *  Created by René Hexel on 23/03/13.
 *  Copyright (c) 2013, 2015, 2016, 2017 Rene Hexel.
 *  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgement:
 *
 *        This product includes software developed by Rene Hexel.
 *
 * 4. Neither the name of the author nor the names of contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * -----------------------------------------------------------------------
 * This program is free software; you can redistribute it and/or
 * modify it under the above terms or under the terms of the GNU
 * General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/
 * or write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */
#ifndef CLMacros_h_
#define CLMacros_h_

#ifdef bool
#undef bool
#endif

#ifdef true
#undef true
#undef false
#endif

#pragma GCC diagnostic push
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wc++98-compat-pedantic"

#include <string>

#define CLRunning CLStatus      ///< running machine

namespace FSM
{
        class Machine;
        class CLMachine;
        class CLState;

        enum CLControlStatus
        {
                CLError = -1,   ///< error indicator
                CLStatus,       ///< check status only
                CLSuspend,      ///< suspend the corresponding state machines
                CLResume,       ///< resume the corresponding state machines
                CLRestart       ///< restart the corresponding state machine
        };

        CLMachine *machine_at_index(unsigned index);
        CLState *current_state_of_machine(CLMachine *);
        long long start_time_for_current_state(const class Machine *machine);
        long long current_time_in_microseconds(void);
        int number_of_machines(void);
        const char *name_of_machine_at_index(int index = 0);
        int index_of_machine_named(const char *machine_name);
        enum CLControlStatus control_machine_at_index(int index, enum CLControlStatus command);

        /**
         Load and add a machine

         @param machine name of the machine to load
         @param initiallySuspended `true` to initially suspend the loaded machine
         @return index of the loaded machine, CLError on error
         */
        int loadAndAddMachine(const char *machine, bool initiallySuspended = false);
        bool unloadMachineAtIndex(int index);

/*
 * Macros for making state machines more readable
 */
#ifndef NO_CL_READABILITY_MACROS

#define timeout(t)      (current_time_in_microseconds() > start_time_for_current_state((_m)->machineContext()) + (t))
#define after(t)        (timeout((t) * 1000000.0))
#define after_ms(t)     (timeout((t) * 1000.0))

#define machine_id()    ((_m)->machineID())
#define machine_name()  ((_m)->machineName())
#define state_name()    ((_s)->name())
#define machine_index() index_of_machine_named(machine_name())
#define cs_machine_named(m,c)      control_machine_at_index(index_of_machine_named(m), (c))

static inline enum CLControlStatus suspend(const char *m) { return cs_machine_named(m, CLSuspend); }
static inline enum CLControlStatus resume(const char *m)  { return cs_machine_named(m, CLResume); }
static inline enum CLControlStatus restart(const char *m) { return cs_machine_named(m, CLRestart); }
static inline enum CLControlStatus status(const char *m)  { return cs_machine_named(m, CLStatus); }
#define suspend_all()   \
    do { \
        int _n = number_of_machines(); \
        for (int _i = 0; _i < _n; _i++) { \
            const CLMachine * const _m_ = machine_at_index(unsigned(_i)); \
            if (_m != _m_) control_machine_at_index(_i, CLSuspend); \
        } \
    } while(0)

#define suspend_self()  control_machine_at_index(machine_index(), CLSuspend)
#define suspend_at(i)   control_machine_at_index((i), CLSuspend)
#define resume_at(i)    control_machine_at_index((i), CLResume)
#define restart_at(i)   control_machine_at_index((i), CLRestart)
#define status_at(i)    control_machine_at_index((i), CLStatus)
#define is_suspended_at(i)  (status_at(i) == CLSuspend)
#define is_running_at(i)    (status_at(i) != CLSuspend)
    
#define is_suspended(m) (status(m) == CLSuspend)
#define is_running(m)   (status(m) != CLSuspend)

#define state_of(m)     (machine_at_index(unsigned(index_of_machine_named(m)))->machineContext()->currentState())
#define state_name_of(m)        (state_of(m)->name())

#define loadMachine(m)   (loadAndAddMachine(m))
#define loadSuspended(m) (loadAndAddMachine(m, true))
#define unloadMachine(i) (unloadMachineAtIndex(i))

#endif // NO_CL_READABILITY_MACROS
}

#pragma clang diagnostic pop
#pragma GCC diagnostic pop

#ifndef NO_CL_UNHYGIENIC_HEADERS
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wheader-hygiene"
#endif

#endif // CLMacros_h_
