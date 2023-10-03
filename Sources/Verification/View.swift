import KripkeStructureViews

/// Specifies the available formats to output a Kripke structure to.
public enum View: Hashable, Codable, Sendable, CaseIterable {

    /// A graphviz dot file.
    case graphviz

    /// A nuXmv model file. 
    case nuXmv

    var factory: AnyKripkeStructureViewFactory {
        switch self {
        case .graphviz:
            return AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory())
        case .nuXmv:
            return AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory())
        }
    }

}
