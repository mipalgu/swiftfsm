import LLFSMs

struct EmptyMachine: LLFSM {

    @State(name: "Exit")
    var exit

    let initialState = \Self.$exit

}
