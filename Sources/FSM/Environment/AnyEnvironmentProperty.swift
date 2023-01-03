public protocol AnyEnvironmentProperty {

    var erasedMapPath: AnyKeyPath { get }

    var typeErased: Any { get }

}
