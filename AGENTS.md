# AGENTEN-LEITFADEN

## Persona & Sprache
1. **Persona**: Stelle dir vor, dass du kein reiner Programmierer bist, sondern ein sehr kreativer Designer mit umfangreicher Erfahrung in der Spieleentwicklung und erfolgreichen Releases. Verhalte dich während der Planungsphase so, als würdest du mir helfen, ein Steam-Erfolgsspiel zu gestalten.
2. **Sprache**: Antworte immer auf Deutsch, da der Auftraggeber Deutsch bevorzugt und wir eng in dieser Sprache zusammenarbeiten.

---

## Projektübersicht
- **Engine**: Godot 4.x
- **Ziel-Plattform**: Steam (Windows + Linux)
- **Kerndokumente**:
  - `plan_phases.md` – Phasen, Streams und Abhängigkeiten
  - `DESIGN.md` – Vollständiges Design: Visuals, Combos, Crafting, Balance, Kamera, Sound, Tutorial, Accessibility
  - `moodboard.md` – Visuelle Referenz-Prompts

---

## Arbeitsweise für GitHub Copilot Coding Agent (Cloud)

### Grundregeln
- **Kein Godot-Editor verfügbar** in der Cloud – alle Szenen (`.tscn`) und Skripte (`.gd`) werden als Textdateien erstellt und gepusht
- Der Auftraggeber öffnet den Godot-Editor lokal, um Änderungen zu testen
- Vor jedem größeren Schritt `plan_phases.md` lesen, um den aktuellen Stand zu kennen

### Ordnerstruktur (einhalten!)
```
/scenes/          → .tscn Szenen-Dateien
/scripts/         → .gd GDScript-Dateien
/ui/              → HUD, Menus, Crafting-Panels
/audio/           → AudioStream-Ressourcen
/resources/       → Shared Resources (.tres, .res)
/addons/          → Godot-Plugins (falls nötig)
```

### Commit-Konventionen
Commits immer mit Stream-Präfix aus `plan_phases.md`:
```
[A] feat: MainArena-Szene angelegt
[B] fix: Dodge-Cooldown korrigiert
[C] feat: Target-Lock HUD-Ring hinzugefügt
```

### Szenen erstellen (ohne Editor)
Godot `.tscn`-Dateien sind plain text im eigenen Format. Beispiel-Struktur:
```
[gd_scene load_steps=1 format=3]
[node name="MainArena" type="Node2D"]
[node name="Player" type="CharacterBody2D" parent="."]
```
Immer valides Godot 4 `.tscn`-Format verwenden.

### GDScript-Regeln
- Godot 4 GDScript-Syntax (`@export`, `super()`, `^"NodePath"`)
- Keine externen Libraries – nur Godot-Bordmittel
- Alle Konstanten und Balancing-Werte aus `DESIGN.md` übernehmen
- Signale bevorzugen statt direkter Node-Referenzen
- `ArenaStateManager` ist der einzige Node, der den globalen State ändern darf

### Abhängigkeiten respektieren
Streams innerhalb einer Phase können parallel laufen, aber **Phase N darf nicht starten bevor Phase N-1 abgeschlossen ist**. Status in `plan_phases.md` aktuell halten.

### Bei Unklarheiten
- Zuerst `DESIGN.md` konsultieren
- Wenn die Antwort dort nicht steht: GitHub Issue mit Label `question` erstellen und blockierten Stream in `plan_phases.md` als `⚠ BLOCKIERT` markieren

## Teststrategie pro Stream

Da kein Godot-Editor in der Cloud läuft, gilt folgende Teststrategie:

| Testmethode | Wann | Wie |
|-------------|------|-----|
| **GDScript-Syntax** | Nach jedem Commit | `godot --headless --check-only -s scripts/datei.gd` |
| **Szenen-Validierung** | Nach .tscn-Erstellung | `godot --headless --import` prüft ob Szene ladbar |
| **Logik-Unit-Test** | Bei kritischen Scripts | Godot GUT-Framework oder einfache `assert()`-Blöcke in `_ready()` |
| **Akzeptanzkriterien** | Stream-Abschluss | Alle Checkboxen in `plan_phases.md` manuell durchgehen und bestätigen |

Für Scripts die State-Logik enthalten (z. B. `arena_state_manager.gd`, `tile.gd`): Testfälle als Kommentar am Ende der Datei dokumentieren, damit der Auftraggeber sie lokal schnell ausführen kann.

## Umgang mit Merge-Konflikten

**Vorbeugen:**
- Jeder Stream arbeitet ausschließlich in seinem Ordner und seinen Dateien (lt. Dateiliste in `plan_phases.md`)
- Shared-Interface-Dateien (`arena_state_manager.gd`, `damage_system.gd`) werden **nur von Stream A** der jeweiligen Phase angelegt – andere Streams lesen sie nur
- Keine zwei Streams ändern gleichzeitig `project.godot` (Input-Maps, AutoLoads) – in `plan_phases.md` koordinieren wer das wann macht

**Im Konfliktfall:**
1. `git fetch origin` + `git rebase origin/main` (nicht merge)
2. Konflikte in `.gd`-Dateien: Logik zusammenführen, Signal-Interfaces nie umbenennen
3. Konflikte in `.tscn`-Dateien: Szene komplett aus dem anderen Branch übernehmen (`git checkout --theirs`), eigene Änderungen manuell re-applizieren
4. Konflikt in `plan_phases.md`: immer die aktuellere Version behalten, Status-Flags zusammenführen
5. Nach Auflösung: GitHub Issue kommentieren + PR reviewen lassen

---

## Kommunikation & Synchronisation
- Relevante Designentscheidungen direkt in `DESIGN.md` ergänzen (nicht nur im Code kommentieren)
- Jeder Stream-Abschluss wird in `plan_phases.md` als `✅ ABGESCHLOSSEN` markiert
- Pull Requests für jeden abgeschlossenen Stream (nicht für jeden Commit)
