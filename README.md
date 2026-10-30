# ひとふりの剣姫（Godot 版）

1タップ・タイミング斬りアクション（縦画面 / iOS・Android）。仕様は「ひとふりの剣姫 ゲーム仕様書 v0.2」に準拠。

- エンジン: **Godot 4.7.2 stable**（GDScript・静的型付け）
- レンダラー: Compatibility（2D のみ）
- 論理解像度: 360×640（stretch: viewport / keep / integer）

## 遊び方

画面のどこかをタップすると剣を振る。敵が判定ライン（y=470）に重なる瞬間に斬る。
PC 実行時はマウスクリック（タッチをエミュレート）またはスペースキー。

## 実装状況（マイルストーン）

| # | 内容 | 状態 |
|---|---|---|
| M1 | コアループ（判定・HP・コンボ・Result） | ✅ |
| M2 | 経済（コイン・強化4種・セーブ/ロード・モック広告で2倍） | ✅ |
| M3 | 5エリア・敵5種＋魔法弾・中ボス/エリアボス・エリア解放・エンドレス | ✅ |
| M4 | ガチャ（排出率表示）・剣12本の効果・衣装9着・装備画面 | ✅ |
| M5 | ログインボーナス・デイリーミッション・4:00 の日付切り替え | ✅ |
| M6 | Android / iOS エクスポート設定・アイコン/スプラッシュの差し替え口 | ✅（AdMob は差し込み口のみ。下記参照） |

## ディレクトリ構成

```
config/            調整用データ（インスペクタで編集する）
  game_config.tres   GameConfig: 判定幅・速度・出現間隔・ボス・コインなど
  juice_config.tres  JuiceConfig: ヒットストップ・画面揺れ・判定文字・振動など（juice_enabled で一括 ON/OFF）
  enemies/*.tres     EnemyData（1体=1ファイル）
  bosses/*.tres      BossData（中ボス・エリアボス）
  areas/*.tres       AreaData（速度倍率・コイン倍率・出現テーブル・ボス攻撃パターンの重み・背景）
  swords/*.tres      SwordData（effect_id・Lv1の値・Lvごとの増分）
  costumes/*.tres    CostumeData（SpriteFrames とパレット色）
  upgrades.tres / gacha.tres / missions.tres / login_bonus.tres
  text.gd            ゲーム内の文字列（日本語のみ）
scripts/
  resources/         上記リソースのクラス定義（class_name + @export）
  game/              enemy / projectile / heroine / judge_system / spawner / boss / boss_controller / sword_effects / gacha_system / game
  autoload/          GameState / SaveService / DailyService / AudioService / HapticsService / AdService
  ads/               AdBackend（基底）/ MockAdBackend / AdMobBackend（M6 で実装）
  ui/                各画面と共通部品（Modal・TopBar・UiUtil）
scenes/              boot / title / home / area_select / game / result / upgrade / gacha / equip / settings
  parts/             enemy / projectile / boss / heroine
assets/
  sprites/ bg/ ui/ fonts/ sfx/ bgm/ shaders/
tools/               仮素材・設定の生成ツール、自動テスト、スクリーンショット
```

## 数値の調整

- すべて `res://config/` の `.tres` をエディタのインスペクタで編集する。ロジックに数値の直書きはしていない。
- 剣を増やす: `config/swords/` に `.tres` を追加するだけ（既存の `effect_id` を使う場合）。新しい効果は `SwordData.EffectId` に追加し、`scripts/game/sword_effects.gd` のフックに分岐を書く。
- エリア・敵・衣装・ミッションも同様にファイル追加で増やせる。

## 素材の差し替え

すべて仮素材（`tools/gen_placeholders.gd` で生成したドット絵・合成音）。

### スプライト（AnimatedSprite2D + SpriteFrames）

`.tres` の中のテクスチャを差し替える（またはフレームを追加する）だけで交換できる。アニメ名は以下で統一。

| 素材 | SpriteFrames | サイズ | アニメ名 |
|---|---|---|---|
| ヒロイン | `assets/sprites/heroine_frames.tres` | 48×48 | `idle`(4) / `slash`(4) / `hurt`(2) / `down`(4) |
| 通常敵・魔法弾 | `assets/sprites/enemies/<id>_frames.tres` | 32×32 | `move` |
| 中ボス・エリアボス | `assets/sprites/bosses/<id>_frames.tres` | 64×64 | `idle`(2) / `windup`(2) / `hurt`(1) |
| ボスの弾 | `assets/sprites/bosses/boss_bullet_frames.tres` | 32×32 | `move` |
| 斬撃エフェクト | `assets/sprites/fx/slash_frames.tres` | 200×24 | `slash`(4) |
| 宝箱 | `assets/ui/chest_frames.tres` | 48×48 | `closed` / `open` |

- 衣装: プロトタイプはパレット差し替え（`assets/shaders/palette_swap.gdshader`）。ヒロインの仮スプライトのキー色（赤=服、緑=スカート、青=髪）を `CostumeData` の3色に置き換える。個別のドット絵に差し替える場合は `CostumeData.sprite_frames` を差し替えて `use_palette = false` にする。
- 背景: `assets/bg/area1〜5.png`（縦にループする 360×640）と `home.png`。`AreaData.background` で差し替え可。
- UI: `assets/ui/theme.tres`（ウィンドウ枠・ボタンは StyleBoxTexture の9スライス）。
- アイコン: `assets/ui/icon.png`（192px）、Android アダプティブ用 `icon_foreground.png` / `icon_background.png`（432px）。
- ブートスプラッシュ: `assets/ui/boot_splash.png`（プロジェクト設定 `application/boot_splash/image`）。

### サウンド

`AudioService.play_se("キー")` / `play_bgm("キー")`。`assets/sfx/<キー>.(ogg|wav|mp3)`・`assets/bgm/<キー>.(ogg|wav|mp3)` を同じキー名で置けば差し替わる（ogg が優先）。

- SE: `slash` `perfect` `good` `whiff` `damage` `kill` `coin` `reflect` `boss_kill` `boss_appear` `windup` `guard` `heal` `gacha_1` `gacha_2` `gacha_3` `chest_shake` `button`
- BGM: `home` `battle` `boss` `result`
- バス: `BGM` / `SE`（`assets/default_bus_layout.tres`）。設定画面で個別にミュート。

## 広告（AdService）

```gdscript
AdService.show_rewarded("result_double")
var result: AdService.Result = await AdService.rewarded_finished  # REWARDED / SKIPPED / ERROR
```

- 現在は `MockAdBackend`（「広告（モック）」と2秒のカウントダウン）。デバッグ設定で SKIPPED / ERROR も返せる。
- 広告表示中は `get_tree().paused = true` にし、BGM/SE をミュートする。
- 実機（`OS.has_feature("mobile")`）で AdMob プラグインのシングルトンが見つかったときだけ `AdMobBackend` を使う。

### AdMob の導入（M6 の残作業）

この環境では Google のサーバー（dl.google.com）に接続できず Android SDK / Gradle ビルドが使えないため、プラグインは未導入。以下の手順で導入する。

1. Godot 4 用 AdMob プラグイン（例: Poing Studios「godot-admob-plugin」）を `addons/` と `android/plugins/` に入れ、プラグインを有効化する。
2. エクスポート設定で `gradle_build/use_gradle_build = true` にする（Android ビルドテンプレートのインストールが必要）。
3. `scripts/ads/admob_backend.gd` の `PLUGIN_SINGLETON` と `TODO(M6)` の箇所を、プラグインの API に合わせて実装する。テスト用ユニットIDは定義済み。
4. AndroidManifest に AdMob アプリIDを設定する（テストID: `ca-app-pub-3940256099942544~3347511713`）。

## セーブ

- `user://save.json`（JSON）。`save_version` を持ち、`SaveService._migrate()` で旧形式を変換する。
- 書き込みは `save.json.tmp` に書いてからリネームする。

## 日付

`Time.get_datetime_dict_from_system()`（端末ローカル時刻）を使い、`GameConfig.day_reset_hour`（既定 4:00）で日付が切り替わる。ログインボーナスは累計ログイン日数で進む（14日サイクル。2周目以降は確定チケットを通常チケットに置き換える）。

## デバッグ機能

デバッグビルド（`OS.is_debug_build()`）のときだけ、設定画面に表示される。

- コイン +10000 / チケット各 +5 / 全エリア解放 / 日付を1日進める / セーブリセット
- 判定範囲の可視化（判定ライン付近の PERFECT=黄・GOOD=青 の帯）
- モック広告の結果（REWARDED / SKIPPED / ERROR）
- 演出（juice）の一括 ON/OFF

## ツール

```sh
# 仮素材の生成（既存ファイルは上書きしない。--force で作り直す）
godot --headless -s res://tools/gen_placeholders.gd
# 設定リソースの生成（同上）
godot --headless --editor --quit   # 先にインポートしてクラスを登録する
godot --headless -s res://tools/gen_config.gd
# 自動テスト（全画面を開き、ボットでエリア1・4をクリア、放置でゲームオーバー、広告2倍などを確認）
godot --headless --fixed-fps 60 res://tools/smoke_test.tscn
# 各画面のスクリーンショット
xvfb-run godot --rendering-driver opengl3 --resolution 360x640 res://tools/screenshots.tscn -- /tmp/shots
```

## ビルド

### Android（APK）

1. Godot 4.7.2 のエクスポートテンプレートをインストールする。
2. エディタ設定 `export/android/android_sdk_path` に Android SDK（build-tools に `apksigner` があること）を、`java_sdk_path` に JDK 17 以上を設定する。
3. `プロジェクト → エクスポート → Android` で書き出す。コマンドラインなら:
   ```sh
   godot --headless --export-debug "Android" build/hitofuri-debug.apk
   godot --headless --export-release "Android" build/hitofuri-release.apk
   ```
4. リリース署名は環境変数 `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` / `_USER` / `_PASSWORD` で指定する（キーストアはリポジトリに入れない）。
5. パッケージ名は `com.yashimapixel.hitofuri`（`export_presets.cfg` で変更可）。権限は振動（VIBRATE）のみ。

### iOS

iOS ビルドには Mac と Xcode が必要。

1. Mac に Godot 4.7.2 とエクスポートテンプレート、Xcode を入れる。
2. `export_presets.cfg` の iOS プリセットで `application/app_store_team_id`（Apple Developer の Team ID）と `bundle_identifier` を設定する。
3. エクスポートで Xcode プロジェクトを書き出し、Xcode で署名して実機にビルドする。
4. AdMob を入れる場合は iOS 版プラグインを導入し、`Info.plist` に `GADApplicationIdentifier` を設定する。

## ライセンス

- フォント: PixelMplus（PixelMplus10 / PixelMplus12、© M+ FONTS PROJECT / itouhiro）。M+ FONT LICENSE により、改変の有無・商用/非商用を問わず使用・複製・再配布が許可されている。全文は `assets/fonts/LICENSE_PixelMplus.txt`。
- その他の仮素材（画像・音）は `tools/gen_placeholders.gd` による自動生成。
