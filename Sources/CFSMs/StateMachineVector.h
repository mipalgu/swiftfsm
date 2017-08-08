/*
 *  CFSMVector.h
 *  cfsm
 *
 *  Created by Rene Hexel on 24/08/2014.
 *  Copyright (c) 2014, 2015 Rene Hexel. All rights reserved.
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
#ifndef cfsm_StateMachineVector
#define cfsm_StateMachineVector

namespace FSM
{
    class CLMachine;

    typedef bool (*visitor_f)(void *context, CLMachine *machine, int machine_number);

    class StateMachineVector
    {
        FSM::CLMachine **_machines; ///< vector of machines to execute
        bool _accepting;            ///< accepting state for all machines?
        unsigned char _n;           ///< number of machines in the vector

    public:
        /**
         *  Designated constructor for an FSM Vector
         *
         *  @param machines array of pointers of CLMachines to execute
         *  @param n        number of machines in the array
         */
        StateMachineVector(FSM::CLMachine **machines, unsigned char n);

        /**
         * FSM Vector destructor
         */
        virtual ~StateMachineVector() {}

        /**
         *  Machine vector getter
         *
         *  @return current machine vector
         */
        FSM::CLMachine **machines() { return _machines; }

        /**
         *  Machine vector const getter
         *
         *  @return current machine vector const pointer
         */
        FSM::CLMachine * const * machines() const { return _machines; }

        /**
         *  Getter for the number of machines
         *
         *  @return number of machines in the vector
         */
        unsigned char numberOfMachines() const { return _n; }

        /**
         *  Accepting state getter
         *
         *  @return whether all machines are in an accepting state
         */
        bool accepting() const { return _accepting; }

        /**
         *  Execute one iteration of the current machine vector
         *
         *  @param visitor pointer to function that returns true if machine should execute
         *  @param context pointer to context to use for visitor function
         *
         *  @return true if any transition fired on any machine
         */
        virtual bool executeOnce(FSM::visitor_f visitor = 0, void *context = 0);

        /**
         *  Execute the given machine once
         *
         *  @param machine         Machine to execute
         *  @param transitionFired true if a transition fired during the execution
         *
         *  @return true if the machine has reached an accepting state
         */
        virtual bool executeMachineOnce(FSM::CLMachine *machine, bool *transitionFired);
    };
}
#endif /* defined cfsm_StateMachineVector) */
