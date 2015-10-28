/*
 * SingleThread.swift
 * swiftfsm
 *
 * Created by Callum McColl on 25/10/2015.
 * Copyright © 2015 Callum McColl. All rights reserved.
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

public class SingleThread: Thread, ExecutingThread {
    
    public private(set) var currentlyRunning: Bool
    
    private var failures: Bool {
        return false == threadCreated
            || SEM_FAILED == self.sem_guard
            || SEM_FAILED == self.f_sem
            || SEM_FAILED == self.run_sem
    }
    
    private let id: UInt
    
    private var thread: UnsafeMutablePointer<pthread_t>
    
    private var threadCreated: Bool
    
    private var f: () -> Void = {}
    
    private var sem_guard: UnsafeMutablePointer<sem_t>
    
    private var f_sem: UnsafeMutablePointer<sem_t>!
    
    private var run_sem: UnsafeMutablePointer<sem_t>!
    
    public init(id: UInt = 0) {
        self.currentlyRunning = false
        self.f = {return}
        self.id = id
        self.thread = UnsafeMutablePointer<pthread_t>.alloc(1)
        self.threadCreated = false
        self.sem_guard = sem_open(
            "ST_sem_guard_\(id)",
            O_CREAT,
            0777,
            1
        )
        self.reset()
    }
    
    private func createThread() -> Bool {
        // Convert f to args void pointer.
        let p: UnsafeMutablePointer<() -> Void> =
        UnsafeMutablePointer<() -> Void>.alloc(1)
        p.initialize({
            while(true) {
                sem_wait(self.run_sem)
                self.f()
                self.currentlyRunning = false
                sem_post(self.f_sem)
            }
        })
        let args: UnsafeMutablePointer<Void> = UnsafeMutablePointer<Void>(p)
        // Create the thread.
        return 0 == pthread_create(
            self.thread,
            nil,
            {(args: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> in
                // Convert args back to function f.
                let p: UnsafeMutablePointer<() -> Void> =
                    UnsafeMutablePointer<() -> Void>(args)
                let f: () -> Void = p.memory
                // Call the function.
                f()
                p.dealloc(1)
                return nil
            },
            args
        )
    }
    
    public func execute(f: () -> Void) -> (Bool, ExecutingThread?) {
        if (true == self.failures) {
            print("Failures present")
            return (false, nil)
        }
        sem_wait(self.f_sem)
        self.f = f
        self.currentlyRunning = true
        sem_post(self.run_sem)
        return (true, self)
    }
    
    public func executeAndWait(f: () -> Void) -> Bool {
        let result: (Bool, ExecutingThread?) = self.execute(f)
        if (true == result.0) {
            pthread_join(self.thread.memory, nil)
        }
        return result.0
    }
    
    private func reset() {
        self.currentlyRunning = false
        self.resetSemaphores()
        self.threadCreated = self.createThread()
    }
    
    private func resetSemaphores() {
        sem_wait(self.sem_guard)
        sem_unlink("ST_f_\(self.id)")
        sem_unlink("ST_run_\(self.id)")
        self.f_sem = sem_open(
            "ST_f_" + String(id),
            O_CREAT,
            0777,
            1
        )
        self.run_sem = sem_open(
            "ST_run_" + String(id),
            O_CREAT,
            0777,
            0
        )
        sem_post(self.sem_guard)
    }
    
    public func stop() {
        pthread_cancel(self.thread.memory)
        self.reset()
    }
    
    deinit {
        sem_close(self.run_sem)
        sem_close(self.f_sem)
        pthread_cancel(self.thread.memory)
        self.thread.dealloc(1)
    }
    
}