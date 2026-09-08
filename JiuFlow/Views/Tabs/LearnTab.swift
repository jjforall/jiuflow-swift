import SwiftUI

/// Learn tab — フロー + 動画 + ゲームプラン統合
struct LearnTab: View {
    @EnvironmentObject var api: APIService
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedSegment) {
                    Text(tr("フロー")).tag(0)
                    Text(tr("動画")).tag(1)
                    Text(tr("プラン")).tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                Group {
                    switch selectedSegment {
                    case 0: FlowTab()
                    case 1: VideosTab()
                    case 2: GamePlansView()
                    default: EmptyView()
                    }
                }
            }
            .background(Color.jfDarkBg)
        }
    }
}
