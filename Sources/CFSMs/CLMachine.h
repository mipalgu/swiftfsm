/*
 *  CLMachine.h
 *  ucfsm
 *
 *  Created by Rene Hexel on 24/08/2014.
 *  Copyright (c) 2012, 2013, 2014, 2015 Rene Hexel. All rights reserved.
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
#ifndef ucfsm_CLMachine_h
#define ucfsm_CLMachine_h

#ifdef bool
#undef bool
#endif

#ifdef true
#undef true
#undef false
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
#pragma clang diagnostic ignored "-Wweak-vtables"
#pragma clang diagnostic ignored "-Wignored-qualifiers"

namespace FSM
{
    class CLState;

    /**
     *  Simple CFSM base class
     */
    class Machine
    {
        CLState                 *_currentState;         ///< current state
        CLState                 *_previousState;        ///< previous state
        CLState                 *_suspendState;         ///< suspend state
        CLState                 *_resumeState;          ///< resume state
        bool                    _deleteSuspendState;    ///< should delete in destructor?
        unsigned long           _state_time;            ///< state start time
    public:
        /// Designated constructor
        Machine(CLState *initialState, CLState *s = 0, bool del = false): _currentState(initialState), _previousState(0), _suspendState(s), _resumeState(0),  _state_time(0UL), _deleteSuspendState(del) {}
    
        /// Destructor
        virtual ~Machine();

        CLState *suspendState() const { return _suspendState; }

        /**
         *  Current state getter
         *
         *  @return the current state of the machine
         */
        CLState *currentState() { return _currentState; }

        /**
         *  Current state const getter
         *
         *  @return the current state of the machine
         */
        CLState * const currentState() const { return _currentState; }

        /**
         * Suspend state setter
         *
         * @param s the new suspend state
         * @param del whether suspend state should be deleted in destructor
         */
        void setSuspendState(CLState *s, bool del = false);

        /**
         * Whether this machine is suspended
         *
         * @return suspend status
         */
        bool isSuspended() const { return _suspendState && currentState() == _suspendState; }

        /**
         * Suspend this machine
         */
        virtual void suspend();

        /** 
         * Resume this machine 
         */
        virtual void resume();

        /**
         *  Current state setter
         *
         *  @param s the new state to make current
         */
        void setCurrentState(CLState *s) { _currentState = s; }

        /**
         *  Previous state getter
         *
         *  @return the previous state of the machine
         */
        CLState *previousState() { return _previousState; }

        /**
         *  Current state const getter
         *
         *  @return the previous state of the machine
         */
        CLState * const previousState() const { return _previousState; }

        /**
         *  Previous state setter
         *
         *  @param s the new state to make the previous state
         */
        void setPreviousState(CLState *s) { _previousState = s; }

        /**
         *  Get the time stamp for when the machine executed onEntry
         *  of the current state
         *
         *  @return onEntry time stamp of the current machine
         */
        const unsigned long stateTime() const { return _state_time; }

        /**
         *  Set the onEntry time stamp of the machine for the current state
         *
         *  @param t time to set state time stamp to
         */
        void setStateTime(const unsigned long t) { _state_time = t; }
    };
    
    /**
     *  This is the machine as seen from within an FSM
     */
    class CLMachine
    {
        Machine                 *_machineContext;       ///< fsm context 
        CLState                 *_initialState;         ///< initial state
        CLState                 *_suspendState;         ///< suspend state
        const char              *_machineName;          ///< name of this machine
        int                      _machineID;            ///< number of this machine
    public:
        /** default constructor */
        CLMachine(int mid = 0, const char *name = ""): _machineContext(), _initialState(0), _suspendState(0), _machineName(name), _machineID(mid) {}

        /** default destructor (subclass responsibility) */
        virtual ~CLMachine() {}

        /** access method for the current state the machine is in */
        CLState *initialState() const { return _initialState; }

        /** access method for the suspend state of the machine */
        CLState *suspendState() const { return _suspendState; }

        /** access method for the FSM context of this machine */
        Machine *machineContext() const { return _machineContext; }

        /** return the name of this machine */
        const char *machineName() const { return _machineName; }

        /** return the ID number of this machine */
        int machineID() const { return _machineID; }

        /** set the current state of this machine */
        void setInitialState(CLState *state) { _initialState = state; }

        /** set the suspend state of this machine */
        void setSuspendState(CLState *state) { _suspendState = state; }

        /** set the name of this machine (name needs to be retained externally!) */
        void setMachineName(const char *name) { _machineName = name; }

        /** set the ID number of this machine */
        void setMachineID(int mid) { _machineID = mid; }

        /** set the machine context of this machine */
        void setMachineContext(Machine *m) { _machineContext = m; }

        /** return the ith state of this machine */
        CLState *state(int i) const { return states()[i]; }

        /** return the array of states this machine contains */
        virtual CLState * const *states() const = 0;

        /** return the number of states this machine has */
        virtual int numberOfStates() const = 0;
    };
}

#pragma clang diagnostic pop
#endif
