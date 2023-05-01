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

#if os(macOS)
import Darwin
#else
import Glibc
#endif

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
    
    public fileprivate(set) var rawArch: String?
    
    public var arch: Arch {
        didSet {
            self.rawArch = nil
        }
    }
    
    public var subarch: SubArch? {
        didSet {
            self.rawArch = nil
        }
    }
    
    public var vendor: Vendor
    
    public var os: OS
    
    public var environment: Environment
    
    public var sharedObjectExtension: String {
        switch self.os {
        case .IOS, .Darwin, .MacOSX:
            return "dylib"
        case .Win32:
            return "dll"
        default:
            return "so"
        }
    }
    
    public static var platform: TargetTriple? {
        #if os(macOS)
        return TargetTriple(arch: .x86_64, vendor: .Apple, os: .MacOSX, environment: .MacABI)
        #else
        var uts = utsname()
        guard
            0 == uname(&uts),
            let os = withUnsafePointer(to: &uts.sysname.0, { String(validatingUTF8: $0) }),
            let arch = withUnsafePointer(to: &uts.machine.0, { String(validatingUTF8: $0) })
        else {
            return nil
        }
        return TargetTriple(triple: "\(arch)-unknown-\(os)-unknown")
        #endif
    }
    
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
        self.environment = environment
    }
    
    /**
     *  Parse the arch, subarch, vendor and os from a triple string of the form
     *  \<arch>\<subarch>-\<vendor>-\<os>-\<environment>.
     */
    public init(triple: String) {
        func parseArch(_ str: String) -> (Arch, SubArch?, String?)? {
            guard let arch = Arch.allCases.sorted(by: {
                    $0.rawValue.count > $1.rawValue.count
                }).first(where: {
                    if str.uppercased().hasPrefix($0.rawValue.uppercased()) {
                        return true
                    }
                    let x86Archs = ["i386", "i486", "i586", "i686", "i786", "i886", "i986"]
                    let x86_64Archs = x86Archs.map { $0 + "_64" }
                    if $0 == .x86 {
                        return nil != x86Archs.first { str.uppercased() == $0.uppercased() }
                    }
                    if $0 == .x86_64 {
                        return nil != x86_64Archs.first { str.uppercased() == $0.uppercased() }
                    }
                    return false
                })
            else {
                return nil
            }
            if arch == .x86_64 || arch == .x86 {
                return (arch, nil, str)
            }
            let subarchStr = String(str.dropFirst(arch.rawValue.count))
            let subarch = SubArch.allCases.first { (arch.rawValue + "SubArch_" + subarchStr).uppercased() == $0.rawValue.uppercased() }
            return (arch, subarch, nil)
        }
        func parseVendor(_ str: String) -> Vendor? {
            return Vendor.allCases.first { str.uppercased() == $0.rawValue.uppercased() }
        }
        func parseOS(_ str: String) -> OS? {
            return OS.allCases.first { str.uppercased() == $0.rawValue.uppercased() }
        }
        func parseEnvironment(_ str: String) -> Environment? {
            return Environment.allCases.first { str.uppercased() == $0.rawValue.uppercased() }
        }
        let split = triple.split(separator: "-").lazy.map { String($0) }
        if split.count >= 4 {
            let (arch, subarch, rawArch) = parseArch(split[0]) ?? (.unknown, nil, nil)
            let vendor = parseVendor(split[1]) ?? .unknown
            let os = parseOS(split[2]) ?? .unknown
            let environment = parseEnvironment(split[3]) ?? .unknown
            self.init(arch: arch, subarch: subarch, vendor: vendor, os: os, environment: environment)
            self.rawArch = rawArch
            return
        }
        if split.count < 1 {
            self.init()
            return
        }
        var arch: Arch = .unknown
        var subarch: SubArch?
        var rawArch: String?
        var vendor: Vendor = .unknown
        var os: OS = .unknown
        var environment: Environment = .unknown
        for i in 0..<split.count {
            if i == 0, let (parsedArch, parsedSubArch, parsedRawArch) = parseArch(split[i]) {
                arch = parsedArch
                subarch = parsedSubArch
                rawArch = parsedRawArch
                continue
            }
            if i <= 1, let parsedVendor = parseVendor(split[i]) {
                vendor = parsedVendor
                continue
            }
            if i <= 2, let parsedOS = parseOS(split[i]) {
                os = parsedOS
                continue
            }
            if i <= 3, let parsedEnvironment = parseEnvironment(split[i]) {
                environment = parsedEnvironment
                continue
            }
        }
        self.init(arch: arch, subarch: subarch, vendor: vendor, os: os, environment: environment)
        self.rawArch = rawArch
    }
    
}
