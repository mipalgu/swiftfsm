public protocol EnvironmentHandler: Identifiable where ID == String {

    associatedtype Value: DataStructure

}
