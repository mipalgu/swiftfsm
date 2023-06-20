// swiftlint:disable type_body_length
// swiftlint:disable function_parameter_count
// swiftlint:disable identifier_name
// swiftlint:disable file_length

import FSM

@resultBuilder
public struct TransitionBuilder {

    public static func buildBlock<T0: TransitionProtocol>(_ t0: T0) -> [AnyTransition<T0.Source, T0.Target>] {
        [AnyTransition(t0)]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol
    >(_ t0: T0, _ t1: T1) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol
    >(_ t0: T0, _ t1: T1, _ t2: T2) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol
    >(_ t0: T0, _ t1: T1, _ t2: T2, _ t3: T3) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol
    >(_ t0: T0, _ t1: T1, _ t2: T2, _ t3: T3, _ t4: T4) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol
    >(_ t0: T0, _ t1: T1, _ t2: T2, _ t3: T3, _ t4: T4, _ t5: T5) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol,
        T6: TransitionProtocol
    >(
        _ t0: T0,
        _ t1: T1,
        _ t2: T2,
        _ t3: T3,
        _ t4: T4,
        _ t5: T5,
        _ t6: T6
    ) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target,
        T0.Source == T6.Source,
        T0.Target == T6.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
            AnyTransition(t6),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol,
        T6: TransitionProtocol,
        T7: TransitionProtocol
    >(
        _ t0: T0,
        _ t1: T1,
        _ t2: T2,
        _ t3: T3,
        _ t4: T4,
        _ t5: T5,
        _ t6: T6,
        _ t7: T7
    ) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target,
        T0.Source == T6.Source,
        T0.Target == T6.Target,
        T0.Source == T7.Source,
        T0.Target == T7.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
            AnyTransition(t6),
            AnyTransition(t7),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol,
        T6: TransitionProtocol,
        T7: TransitionProtocol,
        T8: TransitionProtocol
    >(
        _ t0: T0,
        _ t1: T1,
        _ t2: T2,
        _ t3: T3,
        _ t4: T4,
        _ t5: T5,
        _ t6: T6,
        _ t7: T7,
        _ t8: T8
    ) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target,
        T0.Source == T6.Source,
        T0.Target == T6.Target,
        T0.Source == T7.Source,
        T0.Target == T7.Target,
        T0.Source == T8.Source,
        T0.Target == T8.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
            AnyTransition(t6),
            AnyTransition(t7),
            AnyTransition(t8),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol,
        T6: TransitionProtocol,
        T7: TransitionProtocol,
        T8: TransitionProtocol,
        T9: TransitionProtocol
    >(
        _ t0: T0,
        _ t1: T1,
        _ t2: T2,
        _ t3: T3,
        _ t4: T4,
        _ t5: T5,
        _ t6: T6,
        _ t7: T7,
        _ t8: T8,
        _ t9: T9
    ) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target,
        T0.Source == T6.Source,
        T0.Target == T6.Target,
        T0.Source == T7.Source,
        T0.Target == T7.Target,
        T0.Source == T8.Source,
        T0.Target == T8.Target,
        T0.Source == T9.Source,
        T0.Target == T9.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
            AnyTransition(t6),
            AnyTransition(t7),
            AnyTransition(t8),
            AnyTransition(t9),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol,
        T6: TransitionProtocol,
        T7: TransitionProtocol,
        T8: TransitionProtocol,
        T9: TransitionProtocol,
        T10: TransitionProtocol
    >(
        _ t0: T0,
        _ t1: T1,
        _ t2: T2,
        _ t3: T3,
        _ t4: T4,
        _ t5: T5,
        _ t6: T6,
        _ t7: T7,
        _ t8: T8,
        _ t9: T9,
        _ t10: T10
    ) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target,
        T0.Source == T6.Source,
        T0.Target == T6.Target,
        T0.Source == T7.Source,
        T0.Target == T7.Target,
        T0.Source == T8.Source,
        T0.Target == T8.Target,
        T0.Source == T9.Source,
        T0.Target == T9.Target,
        T0.Source == T10.Source,
        T0.Target == T10.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
            AnyTransition(t6),
            AnyTransition(t7),
            AnyTransition(t8),
            AnyTransition(t9),
            AnyTransition(t10),
        ]
    }

    public static func buildBlock<
        T0: TransitionProtocol,
        T1: TransitionProtocol,
        T2: TransitionProtocol,
        T3: TransitionProtocol,
        T4: TransitionProtocol,
        T5: TransitionProtocol,
        T6: TransitionProtocol,
        T7: TransitionProtocol,
        T8: TransitionProtocol,
        T9: TransitionProtocol,
        T10: TransitionProtocol,
        T11: TransitionProtocol
    >(
        _ t0: T0,
        _ t1: T1,
        _ t2: T2,
        _ t3: T3,
        _ t4: T4,
        _ t5: T5,
        _ t6: T6,
        _ t7: T7,
        _ t8: T8,
        _ t9: T9,
        _ t10: T10,
        _ t11: T11
    ) -> [AnyTransition<T0.Source, T0.Target>]
    where
        T0.Source == T1.Source,
        T0.Target == T1.Target,
        T0.Source == T2.Source,
        T0.Target == T2.Target,
        T0.Source == T3.Source,
        T0.Target == T3.Target,
        T0.Source == T4.Source,
        T0.Target == T4.Target,
        T0.Source == T5.Source,
        T0.Target == T5.Target,
        T0.Source == T6.Source,
        T0.Target == T6.Target,
        T0.Source == T7.Source,
        T0.Target == T7.Target,
        T0.Source == T8.Source,
        T0.Target == T8.Target,
        T0.Source == T9.Source,
        T0.Target == T9.Target,
        T0.Source == T10.Source,
        T0.Target == T10.Target,
        T0.Source == T11.Source,
        T0.Target == T11.Target
    {
        [
            AnyTransition(t0),
            AnyTransition(t1),
            AnyTransition(t2),
            AnyTransition(t3),
            AnyTransition(t4),
            AnyTransition(t5),
            AnyTransition(t6),
            AnyTransition(t7),
            AnyTransition(t8),
            AnyTransition(t9),
            AnyTransition(t10),
            AnyTransition(t11),
        ]
    }

}
