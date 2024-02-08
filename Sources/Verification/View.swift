import KripkeStructureViews

/// Specifies the available formats to output a Kripke structure to.
public enum View: Hashable, Codable, Sendable {

    /// A graphviz dot file.
    case graphviz

    /// A nuXmv model file. 
    case nuXmv

    /// A uppaal model file.
    ///
    /// - Parameters layoutIterations: The number of iterations taken to
    /// layout the graph in uppaal.
    case uppaal(layoutIterations: Int = 0)

    var factory: AnyKripkeStructureViewFactory {
        switch self {
        case .graphviz:
            return AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory())
        case .nuXmv:
            return AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory())
        case .uppaal(let iterations):
            return AnyKripkeStructureViewFactory(
                UppaalKripkeStructureViewFactory(layoutIterations: iterations)
            )
        }
    }

}
