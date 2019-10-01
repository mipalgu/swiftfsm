@_cdecl("test")
public func test() {
    print("This is a test")
}

@_cdecl("test2")
public func test2_wrapper(a: Any) -> Any {
    return test2(a: a as! Int)
}

public func test2(a: Int) -> Int {
    return a * 2
}

@_cdecl("test3")
public func test3(a: Any) -> Any {
    guard let person = a as? Person else {
        fatalError("Unable to convert a to person.")
    }
    if person.name == "Bob" {
        return Person(name: "Bill")
    }
    fatalError("Persons name is not Bob")
}
