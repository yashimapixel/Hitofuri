class_name Text
extends RefCounted
## ゲーム内の文字列をここに集約する（日本語のみ）。

const TITLE := "ひとふりの剣姫"
const TAP_TO_START := "タップしてスタート"

# Home
const SORTIE := "出撃"
const UPGRADE := "強化"
const GACHA := "ガチャ"
const EQUIP := "装備"
const MISSION := "ミッション"
const SETTINGS := "設定"
const BACK := "もどる"
const CLOSE := "とじる"
const OK := "OK"

# エリア選択
const AREA_SELECT := "エリア選択"
const ENDLESS := "エンドレス"
const BEST_FLOOR := "最高 %dF"
const LOCKED := "未解放"
const CLEARED := "クリア"

# ゲーム
const PERFECT := "PERFECT"
const GOOD := "GOOD"
const MISS := "MISS"
const COMBO := "%d COMBO"
const FLOOR := "F%d/%d"
const FLOOR_ENDLESS := "F%d"
const PAUSE := "一時停止"
const RESUME := "再開"
const RETREAT := "撤退する"
const BOSS_APPEAR := "%s があらわれた！"
const AREA_CLEAR := "エリアクリア！"

# リザルト
const RESULT := "リザルト"
const RESULT_CLEAR := "エリアクリア！"
const RESULT_FLOOR := "到達階層"
const RESULT_KILLS := "撃破数"
const RESULT_MAX_COMBO := "最大コンボ"
const RESULT_PERFECT_RATE := "PERFECT率"
const RESULT_COINS := "獲得コイン"
const RESULT_FIRST_CLEAR := "初クリアボーナス"
const NEW_RECORD := "NEW!"
const AD_DOUBLE := "広告を見て2倍"
const TAKE_AS_IS := "そのまま受け取る"
const AD_FAILED := "広告を再生できませんでした（等倍で受け取りました）"
const AD_SKIPPED := "広告がスキップされました（等倍で受け取りました）"

# 強化
const UPGRADE_TITLE := "強化"
const MAX_LEVEL := "MAX"
const NOT_ENOUGH_COINS := "コインが足りません"
const LEVEL := "Lv%d"

# ガチャ
const GACHA_TITLE := "ガチャ"
const GACHA_SINGLE := "1回 %dコイン"
const GACHA_TEN := "10連 %dコイン"
const GACHA_TICKET := "チケットで1回（%d枚）"
const GACHA_TICKET_R2 := "★2以上確定（%d枚）"
const GACHA_TICKET_R3 := "★3確定（%d枚）"
const GACHA_RATES := "排出率  ★1 %s%% / ★2 %s%% / ★3 %s%%\n剣：衣装 = %s：%s（同じ★の中で均等）"
const GACHA_NEW := "NEW"
const GACHA_LEVEL_UP := "Lv%d に強化！"
const GACHA_CONVERT := "%dコインに変換"
const GACHA_TAP_SKIP := "タップでスキップ"
const SWORD := "剣"
const COSTUME := "衣装"

# 装備
const EQUIP_TITLE := "装備"
const EQUIPPED := "装備中"
const SWORD_TAB := "剣"
const COSTUME_TAB := "衣装"

# ミッション
const MISSION_TITLE := "デイリーミッション"
const MISSION_CLAIM := "受け取る"
const MISSION_CLAIMED := "受取済"
const MISSION_ALL_CLEAR := "全達成ボーナス：ガチャチケット×%d"
const MISSION_RESET := "毎日 %d:00 に更新"

# ログインボーナス
const LOGIN_BONUS := "ログインボーナス"
const LOGIN_DAY := "累計%d日目"
const REWARD_COIN := "%dコイン"
const REWARD_TICKET := "チケット"
const REWARD_TICKET_R2 := "★2確定"
const REWARD_TICKET_R3 := "★3確定"

# 設定
const SETTINGS_TITLE := "設定"
const BGM := "BGM"
const SE := "効果音"
const VIBRATION := "振動"
const ON := "ON"
const OFF := "OFF"
const DEBUG := "デバッグ（デバッグビルドのみ）"
const DEBUG_COINS := "コイン +10000"
const DEBUG_TICKETS := "チケット各 +5"
const DEBUG_UNLOCK := "全エリア解放"
const DEBUG_NEXT_DAY := "日付を1日進める"
const DEBUG_RESET := "セーブリセット"
const DEBUG_JUDGE_VIS := "判定範囲の可視化"
const DEBUG_AD_RESULT := "モック広告の結果"
const DEBUG_JUICE := "演出（juice）"

# 広告
const AD_MOCK := "広告（モック）"
const AD_COUNTDOWN := "あと %d 秒"

# 通貨
const COINS := "%d"
const TICKETS := "%d"

# エリア解放時のストーリー（エリア番号 → 3 行）
const STORY := {
	1: "王国の外れ、はじまりの草原。\n剣姫はひとふりの剣を手に旅立つ。\n「魔王城まで、斬って進むのみ」",
	2: "草原を抜けると、まどろみの森。\n木々のあいだで何かが囁いている。\n見えない敵に、心の眼で応えよ。",
	3: "森の奥に口を開ける水晶の洞窟。\n硬い鎧をまとう騎士が道を塞ぐ。\n一太刀で足りぬなら、二太刀。",
	4: "洞窟を抜けた先は氷雪の山脈。\n吹雪の向こうから魔法が飛んでくる。\n弾ごと斬り伏せて進め。",
	5: "ついに見えた、魔王城。\nこれまでのすべてが襲いかかる。\n最後のひとふりを、ここに。",
	6: "魔王は倒れた。だが闇は尽きない。\nエンドレスモードが解放された。\nどこまで登れるか、試してみよう。",
}
