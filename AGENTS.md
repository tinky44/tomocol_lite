# AGENTS

## Project Intent

このリポジトリは、普通体型の人々に合わせて作られた日常空間の中で、デフォルメされた住人たちが暮らす3D生活箱庭のプロトタイプです。

重要なのは「長身少女固定の造形」ではなく、住人作成の幅として高身長キャラクターを作れることです。普通の島、普通の家、普通の家具、普通のドア、普通の住人を成立させるほど、身長差は説明なしで画面に出ます。

## Reference Boundary

トモダチコレクションは、島の上に家がある構造、生活箱庭、正面寄りカメラ、顔パーツ編集、短い日常行動、住人観察のテンポの参考にします。

コピーしないもの:

- UIや見た目の直接模倣
- 特定作品の顔パーツ形状や編集UIの直接模倣
- 既存作品固有のゲームループ、名称、演出

## Repository Layout

- `specs/` - 企画、日常設計、スケール設計、キャラ作成、技術方針
- `godot-project/` - Godot 4.6 系プロジェクト
- `tools/` - Godot 起動や検証用スクリプト
- `artifacts/` - ローカル実行ログやキャプチャ。原則コミットしない

## Godot

Godot は 4.6 系を想定します。PowerShell からの検証は直接 Godot を呼ばず、原則として wrapper を使います。

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -Headless -Quit
```

Godot の場所を明示する場合:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -GodotExe "$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe" -Headless -Quit
```

`tools/run_godot.ps1` は `APPDATA`, `LOCALAPPDATA`, `TEMP`, `TMP` を `artifacts/godot-runtime` に逃がします。これにより `user://logs` などの作成失敗を避けます。

## Design Rules

- まず普通体型向けの環境を作る
- 島を外側の生活単位として作り、家の中へ入れる構造を維持する
- 住人作成では身長、頭、胴、脚バランス、横幅、厚み、顔パーツを編集できる方向へ進める
- 身長差は数字ではなく、ドア、天井、机、椅子、棚、住人同士の並びで見せる
- 住人同士が自律的に近づき、向かい合い、会話する状態を優先する
- 初期は凝ったモデルより、プリミティブ形状と姿勢差を優先する
- 不便さを悲劇として強調しすぎず、生活の身体感覚として扱う
- デフォルトカメラは正面寄りにし、上キーで画面の上方向へ進む直感的な操作を守る
- アクションは `E` キーを主導線にする。選択切替などを `E` に割り当てない

## Implementation Notes

- Godot の 1.0 unit は 1m として扱う
- 平均身長の住人はおおむね `1.60m`
- 住人作成の初期身長範囲はおおむね `1.35m` から `2.60m`
- ドアは `2.00m`、天井は `2.35m` から `2.45m` を基準にする
- スケール検証中は、寸法をコードで調整しやすい生成式シーンを優先する

## Validation

変更後は最低限以下を確認します。

```powershell
git diff --check
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -Headless -Quit
```

Godot が `.uid` ファイルを生成した場合は、シーンやスクリプト参照に関わるため基本的に残します。

## Commit Style

コミットする場合は短い日本語メッセージでよいです。

例:

```text
feat: 島と家の出入りを追加
fix: 住人の進行方向と向きを一致させる
docs: Godot実行手順を追加
```

メッセージ本文の最後に、次の co-author trailer を 1 行だけ正確に入れます。余計な文字、句読点、説明文を足さないでください。

```text
Co-authored-by: chatgpt-codex-connector[bot] <199175422+chatgpt-codex-connector[bot]@users.noreply.github.com>
```

例:

```bash
git commit -m "fix: 住人の向きと移動方向を修正" \
  -m "Co-authored-by: chatgpt-codex-connector[bot] <199175422+chatgpt-codex-connector[bot]@users.noreply.github.com>"
```

PR にはサマリー、テスト証跡（コマンドと結果）、ハードウェア前提（USB ウェブカメラ、GPU 等）を含めます。

## Subagents

サブエージェントを使える環境で、かつユーザーまたは上位指示が許可している場合だけ使います。使う場合は、担当範囲と編集対象ファイルを明確に分け、他の作業者の変更を戻さないようにします。
