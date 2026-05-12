トモコレに足りないもの

この repoでは、トモダチコレクションの再現を目指している。
キャラの体型編集にて、身長の上限を大きくする。キャラは日常を過ごす、イベントも起きるが、高身長であるためにおこる不便さや便利さもある

過去作品：develop\tall_life_simulator

## 2026-05-12 追加: 足りないものと今後の To do

### キャラ・モーション

- 歩きモーションが乏しいので、住人の歩行、立ち止まり、向き変更、会話開始、座るなどの基本アニメーションを増やす。
- キャラの素体をもう少し人間らしくする。今後、脚・足・靴まで自然に見える構造へ寄せる。
- 表情変化を追加する。会話、満足、不満、照れ、友好、驚きなど、短い日常イベントで読める顔差分を持たせる。
- 足まわりを発展させる。歩行アニメーション、座り姿勢、身長差表現と連動できるようにする。
- 1 人のメインキャラで、歩行・表情・会話イベントの見え方を検証する。

### キャラアセット・アニメーション調査メモ

- Godot Asset Store の Universal Animation Library は、Godot 対応のリターゲット可能なヒューマノイドアニメーション集。歩行、走行、8方向移動、座り、クロール、エモートなどを含み、CC0。候補として優先調査する。
  - https://store.godotengine.org/asset/quaternius/universal-animation-library/
- KayKit の Godot Asset Library には、リギング済み・アニメーション済みのキャラパックがある。見た目はトモコレライト本体にはそのまま合わないが、プロトタイプ用の歩行・待機・アクセサリ構成の参考になる。
  - Adventurers: https://godotengine.org/asset-library/asset/2129
  - Skeletons: https://godotengine.org/asset-library/asset/2566
- Mannequiny は Godot 用の 3D キャラコントローラと 10 個のアニメーションを含む。Godot 3.5 向けなので、そのまま採用よりも構成参考・試作参考にする。
  - https://godotengine.org/asset-library/asset/440
- Mixamo アニメーションを Godot に入れる場合は、Godot 4 の `SkeletonProfileHumanoid` / `BoneMap` によるリターゲットを使う。MixaBridge は Mixamo から Godot 4.6 へのリターゲットと AnimationLibrary 構築を自動化する候補。
  - Godot retargeting docs: https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/retargeting_3d_skeletons.html
  - MixaBridge: https://godotassetlibrary.com/asset/SV3FDn/mixabridge
- VRoid Studio / Blender で人間が素体を作る案もあり。VRoid は VRM 出力でき、Godot には VRM Importer for 3D Avatars and MToon Shader がある。顔・髪・衣装の作りやすさは高いが、トモコレライト独自の低負荷デフォルメ素体に合わせるには調整が必要。
  - VRoid VRM export: https://vroid.pixiv.help/hc/en-us/articles/38726063278233-How-do-I-export-a-model-as-VRM
  - Godot VRM Importer: https://godotengine.org/asset-library/asset/2031

### 服装・着せ替え

- 服装の種類を増やす。
- 服ごとの形状差を増やす。今は色と簡易パーツ中心なので、トップス、ボトムス、制服、部屋着などを見た目で分ける。
- 表情やイベント中の顔差分を、住人データとして保存できるようにする。

### 交流イベント

- 交流イベントを増やす。友人になる、関係性が上がる、ケンカ、仲直り、訪問、相談などを段階的に追加する。
- 関係性の種類を増やす。友人、親しい友人、苦手、ケンカ中、仲直り済みなど。
- イベント中はカメラをズームし、横から会話を見る演出を入れる。
- 会話中は吹き出しを出す。ハートのような気持ち表現、短いセリフ、反応アイコンを出せるようにする。

### キャラ編集 UI

- キャラ編集画面が必要。
- 名前編集をできるようにする。
- 現在の左上テキスト操作ではなく、項目を見ながら選べる UI にする。
- 表情関連も、段階的に編集できるようにする。
