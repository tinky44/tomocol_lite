# tomocol_lite

デフォルメされた3Dの生活箱庭で、普通体型の人々に合わせて作られた日常の中に長身少女を置くための実験プロジェクトです。

## Structure

- `specs/` - 企画、表現方針、スケール設計、Godot 実装方針
- `godot-project/` - Godot 4 向けの最小3Dプロトタイプ

## Current Prototype

`godot-project` は、家具・ドア・天井・平均身長NPC・長身少女をすべて単純な3Dプリミティブで描く小さな部屋です。
まずは「普通の部屋にいるだけで背が高い」を確認するための基準シーンとして使います。

## Run

Godot 4.6 系で開けます。PowerShell からの起動確認には、ローカルランタイムを `artifacts/godot-runtime` に逃がす wrapper を使います。

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -Headless -Quit
```

Godot の場所を明示する場合:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -GodotExe "$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe" -Headless -Quit
```
