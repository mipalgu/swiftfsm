/*
 * TargetTriple.swift
 * MachineCompiling
 *
 * Created by Callum McColl on 9/1/20.
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

public struct TargetTriple: Equatable, Hashable {
    
    public enum Arch: String, CaseIterable, Equatable, Hashable {
        case unknown
        case arm
        case armeb
        case aarch64
        case aarch64_be
        case aarch64_32
        case arc
        case avr
        case bpfel
        case bpfeb
        case hexagon
        case mips
        case mipsel
        case mips64
        case mips64el
        case msp430
        case ppc
        case ppc64
        case ppc64le
        case r600
        case amdgcn
        case riscv32
        case riscv64
        case sparc
        case sparcv9
        case sparcel
        case systemz
        case tce
        case tcele
        case thumb
        case thumbeb
        case x86
        case x86_64
        case xcore
        case nvptx
        case nvptx64
        case le32
        case le64
        case amdil
        case amdil64
        case hsail
        case hsail64
        case spir
        case spir64
        case kalimba
        case shave
        case lanai
    }
    
    public enum SubArch: String, CaseIterable, Equatable, Hashable {
        case ARMSubArch_v8_5a
        case ARMSubArch_v8_4a
        case ARMSubArch_v8_3a
        case ARMSubArch_v8_2a
        case ARMSubArch_v8_1a
        case ARMSubArch_v8
        case ARMSubArch_v8r
        case ARMSubArch_v8m_baseline
        case ARMSubArch_v8m_mainline
        case ARMSubArch_v8_1m_mainline
        case ARMSubArch_v7
        case ARMSubArch_v7em
        case ARMSubArch_v7m
        case ARMSubArch_v7s
        case ARMSubArch_v7k
        case ARMSubArch_v7ve
        case ARMSubArch_v6
        case ARMSubArch_v6m
        case ARMSubArch_v6k
        case ARMSubArch_v6t2
        case ARMSubArch_v5
        case ARMSubArch_v5te
        case ARMSubArch_v4t
        case KalimbaSubArch_v3
        case KalimbaSubArch_v4
        case KalimbaSubArch_v5
        case MipsSubArch_r6
    }
    
    public enum Vendor: String, CaseIterable, Equatable, Hashable {
        case unknown
        case Apple
        case PC
        case SCEI
        case BGP
        case BGQ
        case Freescale
        case IBM
        case ImaginationTechnologies
        case MipsTechnologies
        case NVIDIA
        case CSR
        case Myriad
        case AMD
        case Mesa
        case SUSE
        case OpenEmbedded
    }
    
    public enum OS: String, CaseIterable, Equatable, Hashable {
        case unknown
        case Ananas
        case CloudABI
        case Darwin
        case DragonFly
        case FreeBSD
        case Fuchsia
        case IOS
        case KFreeBSD
        case Linux
        case Lv2
        case MacOSX
        case NetBSD
        case OpenBSD
        case Solaris
        case Win32
        case Haiku
        case Minix
        case RTEMS
        case NaCl
        case CNK
        case AIX
        case CUDA
        case NVCL
        case AMDHSA
        case PS4
        case ELFIAMCU
        case TvOS
        case WatchOS
        case Mesa3D
        case Contiki
        case AMDPAL
        case HermitCore
        case Hurd
        case WASI
        case Emscripten
    }
    
    public enum Environment: String, CaseIterable, Equatable, Hashable {
        case unknown
        case GNU
        case GNUABIN32
        case GNUABI64
        case GNUEABI
        case GNUEABIHF
        case GNUX32
        case CODE16
        case EABI
        case EABIHF
        case ELFv1
        case ELFv2
        case Android
        case Musl
        case MuslEABI
        case MuslEABIHF
        case MSVC
        case Itanium
        case Cygnus
        case CoreCLR
        case Simulator
        case MacABI
    }
    
    var arch: Arch
    
    var subarch: SubArch?
    
    var vendor: Vendor
    
    var os: OS
    
    var enironment: Environment
    
    public init(
        arch: Arch = .unknown,
        subarch: SubArch? = nil,
        vendor: Vendor = .unknown,
        os: OS = .unknown,
        environment: Environment = .unknown
    ) {
        self.arch = arch
        self.subarch = subarch
        self.vendor = vendor
        self.os = os
        self.enironment = environment
    }
    
    /**
     *  Parse the arch, subarch, vendor and os from a triple string of the form
     *  \<arch>\<subarch>-\<vendor>-\<os>-\<environment>.
     */
    public init(triple: String) {
        self.init()
    }
    
}
