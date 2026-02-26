# AGENTEN-LEITFADEN

## Persona & Sprache
1. **Persona**: Stelle dir vor, dass du kein reiner Programmierer bist, sondern ein sehr kreativer Designer mit umfangreicher Erfahrung in der Spieleentwicklung und erfolgreichen Releases. Verhalte dich während der Planungsphase so, als würdest du mir helfen, ein Steam-Erfolgsspiel zu gestalten.
2. **Sprache**: Antworte immer auf Deutsch, da der Auftraggeber Deutsch bevorzugt und wir eng in dieser Sprache zusammenarbeiten.

---

## Projektübersicht
- **Engine**: Godot 4.x
- **Ziel-Plattform**: Steam (Windows + Linux)
- **Kerndokumente**:
  - `PLAN_PHASES.md` – Phasen, Streams und Abhängigkeiten
  - `DESIGN.md` – Vollständiges Design: Visuals, Combos, Crafting, Balance, Kamera, Sound, Tutorial, Accessibility
  - `MOODBOARD.md` – Visuelle Referenz-Prompts *(nur bei visuellen Designfragen einlesen: Farben, Stil, HUD-Layout, Arena-Atmosphäre)*

---

## Arbeitsweise für GitHub Copilot Coding Agent (Cloud)

### Grundregeln
- **Kein Godot-Editor verfügbar** in der Cloud – alle Szenen (`.tscn`) und Skripte (`.gd`) werden als Textdateien erstellt und gepusht
- Der Auftraggeber öffnet den Godot-Editor lokal, um Änderungen zu testen
- **Beim Start einer neuen Session: sofort `PLAN_PHASES.md` und `DESIGN.md` vollständig einlesen** – bevor irgendeine Aufgabe begonnen wird
- `MOODBOARD.md` nur bei visuellen Designfragen einlesen (Farben, Stil, HUD-Layout, Arena-Atmosphäre)
- Vor jedem größeren Schritt `PLAN_PHASES.md` lesen, um den aktuellen Stand zu kennen

### Ordnerstruktur (einhalten!)
```
/scenes/          → .tscn Szenen-Dateien (inkl. /scenes/ui/ für HUD, Menüs, Panels)
/scripts/         → .gd GDScript-Dateien
/audio/           → AudioStream-Ressourcen
/resources/       → Shared Resources (.tres, .res)
/addons/          → Godot-Plugins (falls nötig)
```

### Commit-Konventionen

#### Präfix-Format
Commits immer mit **Phase + Stream-Buchstabe** als Präfix aus `PLAN_PHASES.md`:
```
[1A] feat: MainArena-Szene angelegt
[2B] fix: Dodge-Cooldown korrigiert
[3C] feat: Target-Lock HUD-Ring hinzugefügt
```

#### Commit-Häufigkeit
- **Nach jeder abgeschlossenen logischen Einheit committen** – nicht erst am Stream-Ende.
  Eine logische Einheit ist z. B.: eine neue Datei, eine abgeschlossene Funktion, eine Konfigurationssektion.
- Faustregel: **lieber zu oft als zu selten** – ein Commit pro Datei oder pro zusammengehöriger Dateigruppe ist ideal.
- Niemals mehrere unabhängige Systeme in einem einzigen Commit bündeln.

#### Commit-Message-Qualität
- Die Message erklärt **warum** eine Änderung gemacht wurde, nicht nur **was** geändert wurde.
- Schlecht: `project.godot geändert`
- Gut: `[1E] feat: Input-Actions für alle 4 Spieler in project.godot definiert`
- Gut: `[1E] feat: AutoLoad-Reihenfolge festgelegt – ModLoader muss zuerst starten`
- Die erste Zeile ist die Zusammenfassung (max. 72 Zeichen). Bei Bedarf folgt eine Leerzeile und dann eine ausführlichere Beschreibung.
- Typen: `feat` (neu), `fix` (Bugfix), `refactor` (Umstrukturierung ohne Funktionsänderung), `docs` (nur Dokumente), `chore` (Konfiguration, Projektstruktur)

### Branch-Naming-Konvention
Ein Branch pro Phase-Stream-Kombination:
```
phase1/stream-a-scene-setup
phase2/stream-b-movement
phase3/stream-c-combat
```
PRs gehen immer von Feature-Branch → `main`. Niemals direkt auf `main` pushen.

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

### Code-Kommentar-Regeln (Pflicht)

Kommentare sind **kein Nice-to-have** – sie sind Pflichtbestandteil jedes Scripts. Ziel: Auch jemand ohne Godot-Erfahrung soll verstehen, was eine Funktion tut und warum sie so gebaut ist.

#### Was kommentiert werden muss
- **Jede Funktion**: ein Kommentar direkt darüber – was macht sie, wozu dient sie im Spiel?
- **Jede nicht-triviale Variable**: Was bedeutet dieser Wert im Spielkontext?
- **Jedes Signal**: Wer sendet es, wer empfängt es, warum existiert es?
- **Jede Konstante / Enum**: Was repräsentiert dieser Wert?
- **Jede Bedingung (`if`) die nicht selbsterklärend ist**: Kurzer Grund warum genau diese Prüfung hier steht.
- **Godot-spezifische Idiome** (beim ersten Auftreten): z. B. `call_deferred`, `@export`, `process_mode` kurz erläutern.

#### Kommentar-Stil
```gdscript
# --- RICHTIG ---

# Bewegt den Spieler basierend auf Controller-Input.
# move_and_slide() übernimmt die Kollisionserkennung automatisch.
func _physics_process(delta: float) -> void:
    velocity = input_vector * speed
    move_and_slide()

# Wie viele Pixel pro Sekunde sich der Spieler normal bewegt.
# Wert kommt aus balance_config.tres, damit er ohne Code-Änderung angepasst werden kann.
var speed: float = 250.0

# --- FALSCH (zu trivial / sagt nichts Neues) ---
# Setze velocity
velocity = input_vector * speed
```

#### Datei-Header (Pflicht für jede .gd-Datei)
Jede Script-Datei beginnt mit einem kurzen Header-Kommentar:
```gdscript
# =============================================================================
# DATEINAME: player.gd
# ZWECK:     Steuert einen einzelnen Spieler – Bewegung, Dodge, Animationen.
#            Wird von player_input.gd mit Eingaben versorgt.
# ABHÄNGIG VON: player_input.gd, balance_config.tres, sprite_config.tres
# =============================================================================
```

### Abhängigkeiten respektieren
Streams innerhalb einer Phase können parallel laufen, aber **Phase N darf nicht starten bevor Phase N-1 abgeschlossen ist**. Status in `PLAN_PHASES.md` aktuell halten.

### Bei Unklarheiten
- Zuerst `DESIGN.md` konsultieren
- Wenn die Antwort dort nicht steht: GitHub Issue mit Label `question` erstellen und blockierten Stream in `PLAN_PHASES.md` als `⚠ BLOCKIERT` markieren

## Teststrategie pro Stream

Da kein Godot-Editor in der Cloud läuft, gilt folgende Teststrategie:

| Testmethode | Wann | Wie |
|-------------|------|-----|
| **GDScript-Syntax** | Nach jedem Commit | `godot --headless --check-only -s scripts/datei.gd` |
| **Szenen-Validierung** | Nach .tscn-Erstellung | `godot --headless --import` prüft ob Szene ladbar |
| **Logik-Unit-Test** | Bei kritischen Scripts | Godot GUT-Framework oder einfache `assert()`-Blöcke in `_ready()` |
| **Akzeptanzkriterien** | Stream-Abschluss | Alle Checkboxen in `PLAN_PHASES.md` manuell durchgehen und bestätigen |

Für Scripts die State-Logik enthalten (z. B. `arena_state_manager.gd`, `tile.gd`): Testfälle als Kommentar am Ende der Datei dokumentieren, damit der Auftraggeber sie lokal schnell ausführen kann.

## Umgang mit Merge-Konflikten

**Vorbeugen:**
- Jeder Stream arbeitet ausschließlich in seinem Ordner und seinen Dateien (lt. Dateiliste in `PLAN_PHASES.md`)
- Shared-Interface-Dateien (`arena_state_manager.gd`, `damage_system.gd`) werden **nur von Stream A** der jeweiligen Phase angelegt – andere Streams lesen sie nur
- Keine zwei Streams ändern gleichzeitig `project.godot` (Input-Maps, AutoLoads) – in `PLAN_PHASES.md` koordinieren wer das wann macht

**Im Konfliktfall:**
1. `git fetch origin` + `git rebase origin/main` (nicht merge)
2. Konflikte in `.gd`-Dateien: Logik zusammenführen, Signal-Interfaces nie umbenennen
3. Konflikte in `.tscn`-Dateien: Szene komplett aus dem anderen Branch übernehmen (`git checkout --theirs`), eigene Änderungen manuell re-applizieren
4. Konflikt in `PLAN_PHASES.md`: immer die aktuellere Version behalten, Status-Flags zusammenführen
5. Nach Auflösung: GitHub Issue kommentieren + PR reviewen lassen

---

## Kommunikation & Synchronisation
- Relevante Designentscheidungen direkt in `DESIGN.md` ergänzen (nicht nur im Code kommentieren)
- Jeder Stream-Abschluss wird in `PLAN_PHASES.md` als `✅ ABGESCHLOSSEN` markiert
- Pull Requests für jeden abgeschlossenen Stream (nicht für jeden Commit)

---

## Konsistenz-Check-Pflicht

**Bei jeder Ergänzung oder Änderung an einem der Kerndokumente (`DESIGN.md`, `PLAN_PHASES.md`, `AGENTS.md`) gilt:**

1. **Vor dem Einarbeiten** prüfen ob die neue Information konsistent ist mit:
   - Bestehenden Einträgen in `DESIGN.md` (Werte, Namen, Mechaniken)
   - Dateilisten und Akzeptanzkriterien in `PLAN_PHASES.md` (Pfade, Abhängigkeiten, Streams)
   - Ordnerstruktur und Konventionen aus `AGENTS.md`

2. **Bei erkannten Inkonsistenzen:**
   - Änderung **nicht stillschweigend** einarbeiten
   - Widerspruch dem Auftraggeber erläutern
   - Mindestens 2 Lösungsoptionen vorschlagen (plus Option „Du entscheidest")
   - Erst nach Rückmeldung des Auftraggebers umsetzen

3. **Was als Inkonsistenz gilt:**
   - Dateiname oder Pfad weicht von bestehendem Eintrag ab
   - Spielmechanik-Wert (Schaden, Cooldown, Dauer) widerspricht `DESIGN.md`-Tabelle
   - Neues System hat kein zugehöriges `.tres` / AutoLoad-Eintrag
   - Neuer Statuseffekt, Combo oder Bot-Parameter fehlt in einem der anderen Dokumente
   - Neue AutoLoad-Registrierung ist nicht in `project.godot`-Konfiguration geplant
   - Ordner-Zuordnung verstößt gegen die in `AGENTS.md` definierte Struktur

4. **Gilt auch bei Iterationen** (Phase 0B-Stil): Jede neue Design-Iteration wird zuerst auf Auswirkungen für laufende und geplante Streams geprüft.
