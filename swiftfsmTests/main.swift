import XCTest

XCTMain([
    DispatchSchedulerTests(),
    DynamicLibraryCreatorTests(),
    DynamicLibraryMachineLoaderFactoryTests(),
    DynamicLibraryResourceTests(),
    LibraryMachineLoaderTests(),
    MachineRunnerTests(),
    NuSMVKripkeStateParserTests(),
    TimerTests()
])
