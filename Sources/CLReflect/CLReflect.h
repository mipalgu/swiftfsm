/*
 * CLReflect.h
 * swiftfsm
 *
 * Created by Callum McColl on 17/10/20.
 * Copyright © 2020 Callum McColl. All rights reserved.
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
 *        This product includes software developed by Callum McColl.
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

#ifndef CFSMS_CLReflect_h
#define CFSMS_CLReflect_h

#ifdef __cplusplus
extern "C" {
#endif

int REFL_UNKNOWN_ERROR;
int REFL_BUFFER_OVERFLOW;
int REFL_INVALID_ARGS;
int REFL_INVALID_CALL;
int REFL_SUCCESS;

typedef int CLReflectResult;
typedef void* refl_metaMachine;
typedef void* refl_metaState;
typedef void* refl_metaTransition;
typedef unsigned char refl_bool;

void refl_initAPI(CLReflectResult *result);
void refl_destroyAPI(CLReflectResult *result);

void refl_registerMetaMachine(refl_metaMachine metaMachine, unsigned int machineID, CLReflectResult *result);
refl_metaMachine refl_getMetaMachine(unsigned int machineID, CLReflectResult *result);
const char * refl_getMetaMachineName(refl_metaMachine machine, CLReflectResult* result);

void refl_invokeOnEntry(refl_metaMachine metaMachine, unsigned int stateNum, CLReflectResult* result);
void refl_invokeInternal(refl_metaMachine metaMachine, unsigned int stateNum, CLReflectResult* result);
void refl_invokeOnExit(refl_metaMachine metaMachine, unsigned int stateNum, CLReflectResult* result);
refl_bool refl_evaluateTransition(refl_metaMachine metaMachine, unsigned int stateNum, unsigned int transitionNum, CLReflectResult *result);

int refl_getSuspendState(refl_metaMachine metaMachine, CLReflectResult *result);

refl_metaState * refl_getMetaStates(refl_metaMachine metaMachine, CLReflectResult *result);
unsigned int refl_getNumberOfStates(refl_metaMachine machine, CLReflectResult* result);
const char* refl_getMetaStateName(refl_metaState metaState, CLReflectResult *result);
unsigned int refl_getNumberOfTransitions(refl_metaState metaState, CLReflectResult* result);
refl_metaTransition const * refl_getMetaTransitions(refl_metaState metaState, CLReflectResult* result);
int refl_getMetaTransitionTarget(refl_metaTransition trans, CLReflectResult* result);

#ifdef __cplusplus
}
#endif

#endif /* CFSMS_CLReflect_h */
