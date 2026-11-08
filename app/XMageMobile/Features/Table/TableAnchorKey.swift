import SwiftUI

nonisolated struct TableAnchorKey: PreferenceKey {
    static let defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    func tableAnchor(_ id: String) -> some View {
        anchorPreference(key: TableAnchorKey.self, value: .bounds) { [id: $0] }
    }

    @ViewBuilder
    func cardMotion(_ id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}
