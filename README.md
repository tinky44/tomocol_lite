# tomocol_lite

デフォルメされた3Dの生活箱庭で、住人を作り、普通体型の人々に合わせて作られた日常空間の中で暮らす様子を観察する実験プロジェクトです。

身長や体型の編集幅を大きく取り、長身少女のようなキャラクターも自然に作れる方向を目指します。

## Structure

- `specs/` - 企画、日常設計、キャラ作成、スケール設計、技術方針
- `godot-project/` - Godot 4.6 系の最小3Dプロトタイプ
- `tools/` - Godot 起動や検証用スクリプト

## Current Prototype

`godot-project` は、島、家、室内、複数住人をすべて単純な3Dプリミティブで描く小さな生活箱庭です。

まずは「住人作成の身長幅」と「普通の島や部屋にいるだけで体格差が見える」ことを確認するための基準シーンとして使います。島では住人をマップ用に小さく表示し、家の中では生活スケールで表示します。中央の家の前で `E` を押すと、選択中の住人だけが家に入ります。

Prototype controls:

- `Q` / `Tab`: selected resident
- `WASD` or arrow keys: move selected resident relative to the camera
- `E`: action, such as entering or exiting the home near a door mat
- `Enter` / `Space`: alternate action
- `F`: toggle body edit mode
- `1` - `6`: choose body edit field
- `Z` / `X`: decrease/increase the active body edit field
- `J` / `L`: rotate camera view
- `I` / `K`: raise/lower camera
- `-` / `=`: zoom camera
- `Home`: reset to front camera

## Specs

- [specs/00_vision.md](specs/00_vision.md)
- [specs/01_daily_life_design.md](specs/01_daily_life_design.md)
- [specs/02_scale_language.md](specs/02_scale_language.md)
- [specs/03_godot_technical_plan.md](specs/03_godot_technical_plan.md)
- [specs/04_character_creator.md](specs/04_character_creator.md)
- [specs/05_resident_social_system.md](specs/05_resident_social_system.md)

## Run

Godot 4.6 系で開けます。PowerShell からの起動確認には、ローカルランタイムを `artifacts/godot-runtime` に逃がす wrapper を使います。

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -Headless -Quit
```

Godot の場所を明示する場合:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_godot.ps1 -GodotExe "$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe" -Headless -Quit
```
