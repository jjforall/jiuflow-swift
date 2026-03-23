import SwiftUI

struct ProBadge: View {
    var size: BadgeSize = .small

    enum BadgeSize {
        case tiny, small, medium
    }

    var body: some View {
        Text("PRO")
            .font(.system(size: fontSize, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(.black)
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .background(LinearGradient.jfGoldGradient)
            .cornerRadius(cornerR)
    }

    private var fontSize: CGFloat {
        switch size {
        case .tiny: return 7
        case .small: return 9
        case .medium: return 11
        }
    }

    private var hPad: CGFloat {
        switch size {
        case .tiny: return 5
        case .small: return 8
        case .medium: return 12
        }
    }

    private var vPad: CGFloat {
        switch size {
        case .tiny: return 2
        case .small: return 3
        case .medium: return 5
        }
    }

    private var cornerR: CGFloat {
        switch size {
        case .tiny: return 3
        case .small: return 4
        case .medium: return 6
        }
    }
}
