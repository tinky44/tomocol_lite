# AGENTS

## Project Intent

このリポジトリは、普通体型の人々に合わせて作られた日常空間の中に、デフォルメされた長身少女を配置する3D生活箱庭のプロトタイプです。

重要なのは「長身少女単体の造形」より先に、普通の部屋、普通の家具、普通のドア、普通のNPCを成立させることです。普通の環境が基準になるほど、身長差は説明なしで画面に出ます。

## Reference Boundary

トモダチコレクションは、生活箱庭、固定寄りカメラ、短い日常行動、住人観察のテンポの参考にします。

コピーしないもの:

- UIや見た目の直接模倣
- Mii風の顔パーツ編集そのもの
- 既存作品固有のゲームループ、名称、演出

## Repository Layout

- `specs/` - 企画、日常設計、スケール設計、技術方針
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
- 身長差は数字ではなく、ドア、天井、机、椅子、棚、NPCとの並びで見せる
- 初期は凝ったモデルより、プリミティブ形状と姿勢差を優先する
- 不便さを悲劇として強調しすぎず、生活の身体感覚として扱う
- 画面の一目でスケール差がわかる固定寄りカメラを大事にする

## Implementation Notes

- Godot の 1.0 unit は 1m として扱う
- 平均身長NPCはおおむね `1.60m`
- 長身少女はおおむね `2.12m` から `2.25m`
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
feat: 3D生活箱庭の基準部屋を追加
fix: Godot 4.6 の型推論エラーを修正
docs: Godot実行手順を追加
```

