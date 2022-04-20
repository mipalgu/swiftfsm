import swiftfsm
import SwiftfsmWBWrappers

public final class SonarVars: Variables {

    public var distance: UInt16

    public var numLoops: UInt16

    public var maxLoops: UInt16!

    public private(set) var SPEED_OF_SOUND: Double

    public var SCHEDULE_LENGTH: Double!

    public var SONAR_OFFSET: Double

    public init(distance: UInt16 = UInt16.max, numLoops: UInt16 = 0, maxLoops: UInt16! = nil, SPEED_OF_SOUND: Double = 34300, SCHEDULE_LENGTH: Double! = nil, SONAR_OFFSET: Double = 40) {
        self.distance = distance
        self.numLoops = numLoops
        self.maxLoops = maxLoops
        self.SPEED_OF_SOUND = SPEED_OF_SOUND
        self.SCHEDULE_LENGTH = SCHEDULE_LENGTH
        self.SONAR_OFFSET = SONAR_OFFSET
    }

    public final func clone() -> SonarVars {
        return SonarVars(
            distance: ((self.distance as? Cloneable)?.clone() as? UInt16) ?? self.distance,
            numLoops: ((self.numLoops as? Cloneable)?.clone() as? UInt16) ?? self.numLoops,
            maxLoops: ((self.maxLoops as? Cloneable)?.clone() as? UInt16) ?? self.maxLoops,
            SPEED_OF_SOUND: ((self.SPEED_OF_SOUND as? Cloneable)?.clone() as? Double) ?? self.SPEED_OF_SOUND,
            SCHEDULE_LENGTH: ((self.SCHEDULE_LENGTH as? Cloneable)?.clone() as? Double) ?? self.SCHEDULE_LENGTH,
            SONAR_OFFSET: ((self.SONAR_OFFSET as? Cloneable)?.clone() as? Double) ?? self.SONAR_OFFSET
        )
    }

}
