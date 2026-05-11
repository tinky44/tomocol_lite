# Godot Technical Plan

## Engine Choice

Godot 4 を第一候補にする。

理由:

- 小さな3D箱庭を軽く作れる
- GDScript でプロトタイプが速い
- 2D資産や既存の感覚から移行しやすい
- プリミティブ形状だけでもスケール検証ができる
- 将来、会話UIや生活シミュレーションを足しやすい

## Project Layout

```text
godot-project/
  project.godot
  scenes/
    main.tscn
  scripts/
    Main.gd
tools/
  run_godot.ps1
```

## Prototype Goal

最初の Godot シーンは、完成したゲームではなくスケール検証台。

必須要素:

- 島と複数の家
- 家の外から室内への出入り
- 普通体型向けの部屋
- 2.0mのドア
- 2.4m前後の天井
- 椅子、机、棚、ベッド
- 可変身長の複数住人
- 簡易的な顔パーツと体型編集
- `E` キーを主導線にしたアクション入力
- 自律的な住人交流
- 正面寄りの3Dカメラ
- カメラ相対の直感的な移動

## Implementation Style

最初は `.tscn` に細かいノードを手で置かず、`Main.gd` でプリミティブを生成する。

利点:

- 寸法をコードで管理できる
- 身長、体型、顔パーツ、家具サイズをすぐ調整できる
- Blender等の外部モデリングを待たずに検証できる

## Next Milestones

1. Static Scale Room
   - 現在の最小プロトタイプ
   - 立ち姿と家具比較だけを見る

2. Walkable Island and Room
   - 選択中の住人をキーボードで少し動かす
   - 身長、頭、胴、脚バランス、横幅、厚みをキー入力で調整する
   - 島から家の中へ入る
   - ドア前や家具前で姿勢を変える

3. Daily Actions
   - 座る
   - ドアを通る
   - 棚を見る
   - 住人同士が向かい合う

4. Social Observation
   - 住人が見上げる/見下ろす
   - 短い吹き出し
   - 頼みごと

5. Multi-Room Life
   - 島、家、部屋、廊下、教室などを切り替える

## Local Run Wrapper

Godot は `user://logs` や editor 設定をユーザーディレクトリへ書こうとする。自動検証や Codex 実行では権限差分で失敗しやすいため、`tools/run_godot.ps1` を経由して起動する。

この wrapper は以下を行う。

- `Downloads` などから Godot 実行ファイルを探索する
- `APPDATA`, `LOCALAPPDATA`, `TEMP`, `TMP` を `artifacts/godot-runtime` 配下に一時変更する
- `--log-file` を明示する
- `-Headless -Quit` でプロジェクト読み込みだけを検証できる
