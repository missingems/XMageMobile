import SwiftUI

enum CombatRole {
    case attacking, blocking

    var systemImage: String {
        switch self {
        case .attacking: "bolt.fill"
        case .blocking: "shield.fill"
        }
    }

    var tint: Color {
        switch self {
        case .attacking: .red
        case .blocking: .blue
        }
    }
}
