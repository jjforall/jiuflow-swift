import SwiftUI

/// Skeleton loading with BJJ tips/trivia
struct LoadingWithTips: View {
    @State private var tipIndex = 0

    private static let tips = [
        // 村田良蔵の教え
        tr("💡 やられない → コントロール → アタック。この順番を崩すな"),
        tr("💡 クローズドガードができない人は、他のガードもできない"),
        tr("💡 ズボンを掴ませるな。掴まれた瞬間に状況が五分になる。即切れ"),
        tr("💡 ハーフで勝負するな。技が使えなくなる。脱出してオープンガードへ"),
        tr("💡 お尻を中に入れられたら即斜めにする。まっすぐは絶対NG"),
        tr("💡 三角ファースト。腕コントロールが取れたら即三角を狙う"),
        tr("💡 スイープできたらマウント。これが最も望ましい展開"),
        tr("💡 頭を下げさせるか腕をコントロールするか。どちらかを常に確立する"),
        tr("💡 焦りは敗因の第一位。焦ったらまず呼吸を整えろ"),
        tr("💡 相手の体重を感じるのは目じゃなく足と腰"),
        tr("💡 エスケープは柔術で最も大事なスキル。技を100個覚えるより先にやれ"),
        tr("💡 パスガードは3段階：①グリップ殺し ②フック外し ③パス。①を飛ばすな"),
        tr("💡 マウントでは急がない。深呼吸一回。相手が必ず動く"),
        tr("💡 足関節は安全第一。練習で怪我させたら柔術家として失格"),
        tr("💡 亀になったら3秒以内に動け。座るか立つか転がるか"),
        tr("💡 アンダーフックは命綱。取れなかったらニーシールドに戻せ"),
        tr("💡 バタフライスイープはタイミングのゲーム。打ち込み100回で身につく"),
        tr("💡 DLRでは足首グリップが命。離したら全て崩壊する"),
        tr("💡 サイドでは圧が全て。横隔膜に体重を集中させる"),
        tr("💡 バックエスケープは手の戦い。手首をコントロールすれば絞められない"),
        // 柔術の教訓
        tr("💡 タップは恥じゃない。タップして学ぶのが柔術"),
        tr("💡 グリップファイトに勝てば試合の半分は勝ち"),
        tr("💡 相手の動きに反応するな。相手を動かせ"),
        tr("💡 呼吸を止めるな。吐きながら技をかける"),
        tr("💡 柔術は楽しいから続く。楽しいから強くなる"),
        tr("💡 40代からでも強くなれる。体の使い方と判断力が武器になる"),
        tr("💡 正しいより楽しいを選べ。楽しいから人が集まる"),
        tr("💡 練習では安全第一。パートナーを怪我させない"),
        tr("💡 スイープの秘訣は相手の手をマットから離すこと"),
        tr("💡 一つの技を1000回やった人は100の技を10回やった人に勝つ"),
    ]

    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                SkeletonCard(height: 180)
                SkeletonCard(height: 70)
                SkeletonCard(height: 70)
                SkeletonCard(height: 70)
            }

            // Tip card
            Text(Self.tips[tipIndex])
                .font(.subheadline)
                .foregroundStyle(Color.jfTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .transition(.opacity)
                .id(tipIndex)
                .animation(.easeInOut(duration: 0.5), value: tipIndex)
        }
        .padding()
        .onReceive(timer) { _ in
            tipIndex = (tipIndex + 1) % Self.tips.count
        }
    }
}
