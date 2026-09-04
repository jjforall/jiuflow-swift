# JiuFlow iOS — デザイン/機能テスト設計 (2026-09-04)

正本。実機 (iPhone 16 Pro / iOS 26.5.2) で `JiuFlowUITests` を回す。シミュレータは使わない (Apple Pay / Keychain / 実速度が違う)。

## 実行

```bash
scripts/ui-test-device.sh                       # 全スイート → build/ui-test/<stamp>.xcresult + -attachments/
scripts/ui-test-device.sh 00008140-0005453411E0801C -only-testing:JiuFlowUITests/SmokeTests
```

- 署名は Automatic / Apple Development にコマンドラインで上書き (App Store 用 Manual profile は不要)
- 端末はロック解除 + Developer Mode 必須。25 分番犬で xcodebuild を止める (実機が test runner を起動できないと無限待ち)
- スクショ/ダンプは `XCTAttachment(.keepAlways)` → `xcresulttool export attachments` で PNG/MD に展開

## 設計原則

1. **本人データを汚さない** — 記録系は「シートが開く・フォームが出る」まで。保存ボタンは押さない (ワンタップ記録もタップしない)
2. **設定を汚さない** — 言語/オンボーディング済みフラグは `-preferred_language` / `-hasSeenOnboarding` の launch arguments (NSArgumentDomain) で注入。端末の UserDefaults は変わらない
3. **失敗はそのまま出す** — i18n 漏れなどプロダクト側の既知欠陥もテストを緑にせず赤で出し、findings に載せる
4. **a11y 識別子は最小追加** — 今回追加は FAB の `quickLogFab` のみ。他はラベル文字列で辿る

## テスト行列

### 機能 (F)

| ID | スイート / テスト | 検証内容 | 判定 |
|---|---|---|---|
| F-1a | `SmokeTests.testAllTabsRenderJa` | 5 タブ存在・各ルート描画 (Home nav "JiuFlow" / 学ぶ 3 セグメント切替 / 練習「ラウンドを開始」 / マイページ nav) | assert + スクショ 01–06 |
| F-1b | `SmokeTests.testFloatingLogButtonExists…` | FAB 存在・hittable・水平中央・下端・フィードバック吹き出しと非重複 | assert |
| F-1c | `SmokeTests.testLaunchPerformance` | 起動時間 (XCTApplicationLaunchMetric ×5) | 計測値を記録 |
| F-2a | `QuickLogTests.testFabOpensQuickLogSheetAndCloses` | FAB→「記録する」シート・5 カード+ワンタップ節・閉じる | assert |
| F-2b | `QuickLogTests.testLogTabItemAlsoOpensSheet` | 「記録」タブ項目でもシート・閉じた後は前タブ(ホーム)が選択されたまま | assert |
| F-2c | `QuickLogTests.testPracticeCardOpensNewEntryFormWithoutSaving` | 練習カード→「新しい記録」フォーム→保存せず閉じる | assert |
| F-3a/b | `I18nTests.testTabLabelsEnglish / Portuguese` | en/pt でタブ名が英語 (pt は en フォールバック) | assert |
| F-3c | `I18nTests.testNoJapaneseLeaksInEnglishMode` | en 強制で 5 ルート+記録シートに日本語文字列 0 件 (全 staticText/button を走査) | assert 0 件 + `i18n_leaks_en.md` |
| F-3d | `I18nTests.testLanguageSwitch…Reachable` | マイページ or 設定に「言語」コントロールが到達可能 | assert |
| F-4a | `NavigationTests.testTournamentsListLoadsFromServer` | マイページ→大会一覧→ jiuflow-ssr から 20 秒以内に読込完了・空でない・検索欄あり (未ログイン時 skip) | assert |
| F-4b | `NavigationTests.testSettingsShowsLanguagePickerAndVersion` | 設定に言語ピッカーとバージョン表記 (未ログイン時 skip) | assert |
| F-4c | `NavigationTests.testTrainTabManualRoundEntry…` | ラウンド開始→m:ss タイマー→停止→「強度を選択」→保存せず閉じる | assert |
| F-5a/b/c | `OnboardingTests` | 初回=オンボーディング表示・スキップ/ページ送り→「はじめる」で本体へ・再訪=非表示 | assert + スクショ 40–41 |

### デザイン (D)

| ID | テスト | 検証内容 | 判定 |
|---|---|---|---|
| D-1 | `DesignTests.testDarkThemeOnAllRootScreens` | 5 画面+シートの左ガター 3 点の輝度 < 0.20 (#0A0A0A 強制ダーク) | 画素サンプリング |
| D-2 | `DesignTests.testAccessibilityDynamicTypeKeepsLayout` | AX-M 文字サイズでタブ 5 個・セグメント 3 個が生存 | assert + スクショ 50–54 (目視) |
| D-3 | `DesignTests.testTabBarIsOpaqueAndAtBottom` | タブバーが下端に密着・高さ ≥49・項目非重複 | frame |
| D-4 | `DesignTests.testMyPageHeroCopyIsInAppCopy` | コピー規約 (「頑張って」系・他社名) が UI 上に無い | 文字列走査 |
| D-5 | 人の目 | スクショ 01–54 を見て: 余白/階層/切れ/コントラスト/AX 時の崩れ | レビュー所見を本書「結果」に追記 |

### 対象外 (今回)

- 課金 (StoreKit sandbox) / magic link ログイン / SJJJF エントリー送信 — 実顧客データと決済に触るため人間立ち会いで別途
- BLE 心拍 — build 44 でハード連携を削除済み
- ウィジェット

## 結果

→ 実行ごとに下に追記 (最新が上)。

### Run #2 — 2026-09-04 21:22–21:26 (iPhone 16 Pro, iOS 26.5.2, Xcode 16.2) — **20 本実行 / 17 ✅ / 1 🔴 / 2 ⏭**

端末上で「Enable UI Automation」を Face ID 承認 → 以後は自動で走る (00ez 解消)。所要 251 秒。成果物 = `build/ui-test/20260904-212205-attachments/` (スクショ 30 枚 + 画面録画 + テキストダンプ)。

| スイート | 結果 |
|---|---|
| DesignTests (4) | ✅ 4/4 — ダーク背景 輝度 0.036–0.044 (閾値 0.20)・AX-M でタブ 5/セグメント 3 生存・タブバー下端密着・コピー規約違反 0 |
| SmokeTests (3) | ✅ 3/3 — 5 タブ描画・FAB 中央/下端/吹き出し非重複・起動計測 5 回完走 |
| QuickLogTests (3) | ✅ 3/3 — FAB とタブ項目の両方でシート・練習フォーム到達・保存せず閉じる・前タブ保持 |
| OnboardingTests (3) | ✅ 3/3 — 初回表示・スキップ・5 ページ送り→はじめる・再訪非表示 |
| NavigationTests (3) | ✅ 1 (手動ラウンド開始→タイマー→停止→強度ピッカー→破棄) / ⏭ 2 (端末がログアウト状態=大会一覧・設定メニュー非表示) |
| I18nTests (4) | ✅ 3 (en/pt タブ名・言語コントロール到達) / 🔴 **testNoJapaneseLeaksInEnglishMode: 英語モードで日本語 183 件** (Home 23・Learn 26+12+…・Train・My Page・記録シート。一覧=`i18n_leaks_en.md`) |

**D-5 目視レビュー所見 (スクショ 01–54)**

| # | 重さ | 所見 | 場所 | 直し方 |
|---|---|---|---|---|
| 1 | 🔴 | **英語/ポルトガル語モードでも画面の大半が日本語** (練習タブは見出し・ボタン・統計ラベル全部、記録シート全部、ホームの挨拶/統計/セクション見出し) | 24_en_train / 26_en_quicklog / 22_en_home | 静的スキャン 324 箇所を `lang.t` 化。BR 施策 (pt) の前提条件 |
| 2 | 🟠 | **中央 FAB (+) がコンテンツを隠す**: 練習タブのコンディションカード「TSB ニュートラル」の文字に重なる。ホーム/マイページでも最下部カードの先頭を覆う | 05_train / 24_en_train / 06_mypage | 各 ScrollView の `.padding(.bottom)` を 40→88 (FAB 56 + 余白) に。もしくは `safeAreaInset(edge: .bottom)` |
| 3 | 🟠 | **フィードバック吹き出し (?) がカードの右端 chevron を隠す** (ホーム「クラシック王道システム」/ マイページ「進捗トラッキング」/ AX ではメソッドカードの chevron) | 01_home / 06_mypage / 50_ax_home | スクロール中は非表示・または初回のみ表示→設定に格納。ルール「サブ機能を目立たせない」にも沿う |
| 4 | 🟡 | **AX-M 文字サイズでワンタップ記録ボタンが単語の途中で折返し** (「ノー/ギ」「ドリ/ル」) | 54_ax_quicklog | `.lineLimit(1)` + `.minimumScaleFactor(0.7)`、または AX サイズでは縦積み |
| 5 | 🟡 | **学ぶタブの操作列が 3 段** (フロー/動画/プラン → ステップ/全体図 → プランチップ) でコンテンツが画面半分から。大見出し「フロー」がセグメント名と重複 | 02_learn_flow | 大見出しを「学ぶ」にし inline 化、ステップ/全体図はコンテンツ側のトグルへ |
| 6 | 🟡 | **オンボーディング p1 のコピー「世界チャンピオンを多数輩出した JiuFlow メソッド」は裏取り無し** | 40_onboarding_page1 | ルール「未確認数字を公開面に載せない」。事実確認できる表現に (例: 良蔵先生の実績を具体で) |
| 7 | 🟢 | ダークテーマ・カード階層・赤アクセントは一貫。オンボーディング/記録シートは余白・階層とも良好。AX-M でも崩れなし | 全般 | — |

**環境メモ**: 端末は dev ビルドでログアウト状態 (Keychain は access group 同一のはずだが、`isLoggedIn` は false)。App Store 版に戻すには App Store から再入手。

### Run #1 — 2026-09-04 20:53 / 21:12 (iPhone 16 Pro, iOS 26.5.2, Xcode 16.2)

| 段階 | 結果 |
|---|---|
| project.yml→xcodegen (UI test target 追加・version 1.1.1/47 に同期) | ✅ |
| Debug ビルド (JiuFlow + Widget + JiuFlowUITests-Runner) | ✅ 署名は Xcode 管理の Development profile に自動解決 |
| 実機インストール・ランナー起動 | ✅ 21:09 `Running tests...` |
| テスト実行 | 🔴 0/17 実行 — `Timed out while enabling automation mode` |

**真因 (端末 syslog `build/ui-test/syslog-retry.txt`)**: `testmanagerd(AutomationMode): Writer daemon requires authentication to enable automation mode` → iOS が「Enable UI Automation」の LocalAuthentication (Face ID/パスコード) を要求 → 60 秒未承認でタイムアウト。端末はロック解除済・Developer Mode 有効・Xcode/iOS 相性ではない。**人間ゲート 00ez**: 次回実行時に端末上で承認 (初回のみ)。

**環境所見**: Mac は load average 200 超、`simctl list devices available` が空 (09-03 からのシミュレータ故障が継続) → シミュレータ代替も不可。Mac 再起動が必要。

**実機なしで確定した所見 (静的スキャン `Text("…")` 日本語リテラル)**

| 指標 | 値 |
|---|---|
| ハードコード日本語 `Text` リテラル | 324 |
| `lang.t(...)` ローカライズ呼び出し | 313 |
| 漏れのあるファイル | 48 / 76 |
| 最多 | AdminPanelView 38 / PracticeJournalView 32 / WearableTab 20 / AICoachView 19 / WeightTrackerView 18 |

→ 「全 UI 多言語」ルール違反。en/pt ユーザー (BR 施策の対象) は 記録シート・練習タブ・練習日記・体重・AI コーチが日本語のまま。F-3c (`testNoJapaneseLeaksInEnglishMode`) は実機で赤になる見込み。修正は `lang.t` への置換 (機械的・約 324 箇所) を別 PR で。

**アプリ側の変更**: `ContentView.swift` の FAB に `accessibilityIdentifier("quickLogFab")` + ローカライズ済み `accessibilityLabel` を追加 (VoiceOver でも「記録する/Log」と読まれるようになる副次効果)。
