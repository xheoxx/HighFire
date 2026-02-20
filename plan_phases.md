# Plan – HighFire Spellcraft Arena

## Referenz-Dokumente
| Dokument | Inhalt |
|----------|--------|
| `DESIGN.md` | Vollständiges Design: Visuals, Combos, Crafting, Balance, Kamera, Tutorial, Accessibility |
| `moodboard.md` | Bildgenerator-Prompts für 3 Stimmungswelten |
| `AGENTS.md` | Persona, Sprache, Koordinationsregeln für Agenten |

---

## Objective
Schneller, lokaler Multiplayer-Arena-Fighter (Steam-Ziel) mit Spellcrafting, Weaponcrafting, Controller-Motion-Combos, Target-Locking, Line-of-Sight und zerstörbarem Terrain – vollständig in Godot 4 mit Primitiven (ColorRect, Line2D, Labels, GPUParticles2D), keine externen Assets nötig.

---

## Phasen-Übersicht

### Phase 0 – Design Foundation ✅ ABGESCHLOSSEN
Alle Design-Entscheidungen getroffen und in `DESIGN.md` dokumentiert:
- Combo-Grammatik & Motion-Input-Lexikon
- Spellcrafting-Rezepte (6 Elemente, Kombinationen)
- Weaponcrafting-Archetypen & Upgrade-Nodes
- Balance-Parameter (HP, Schaden, Cooldowns)
- Arena-Layout-Varianten (4 Maps)
- Kamera-System (Shared/Split-Screen)
- Game Feel / Juice
- Sound-Design
- Spieler-Farbidentität
- Arena State Machine
- Tutorial-Flow
- Accessibility

---

### Phase 1 – Core Scene & Movement
**Ziel**: Spielbares Grundgerüst mit Bewegung, Dodge, Target-Lock in einer Arena.

**Parallel-Streams:**

| Stream | Aufgaben | Abhängigkeiten |
|--------|---------|----------------|
| **A: Scene-Setup** | `MainArena`-Szene, Tile-Grid (32x32), Spieler-Nodes, Kameras, HUD-Canvas | – |
| **B: Player Movement** | Bewegung, Dodge, Collision, Spieler-Farbidentität | Stream A |
| **C: Target System** | Target-Lock, Zielwechsel, HUD-Ringe (Cyan/Rot), Line-of-Sight | Stream A+B |
| **D: Terrain Base** | Tile-States (Intact/Cracked/Destroyed), Unterleuchten, Tile-Destruktion | Stream A |

---

### Phase 2 – Combat & Crafting
**Ziel**: Vollständige Kampfschleife mit Spells, Combos und Waffen.

**Parallel-Streams:**

| Stream | Aufgaben | Abhängigkeiten |
|--------|---------|----------------|
| **A: Motion-Input Parser** | Joystick-Gesten-Erkennung, Timing-Fenster, Combo-Chain-Visual | Phase 1 komplett |
| **B: Spellcrafting** | Element-Sammlung, Crafting-UI, Rezept-Logik, Spell-Slots | Stream A |
| **C: Weaponcrafting** | Waffen-Archetypen, Upgrade-Nodes, Material-Sammlung | Stream A |
| **D: Damage & LOS** | Schadensklassen, Hit-Detection, Line-of-Sight-Raycast | Phase 1 komplett |

---

### Phase 3 – Multiplayer & State
**Ziel**: Vollständige lokale Multiplayer-Runde mit Scoring und Round-Flow.

**Parallel-Streams:**

| Stream | Aufgaben | Abhängigkeiten |
|--------|---------|----------------|
| **A: ArenaStateManager** | State Machine (Lobby→Countdown→Combat→End), Signals | Phase 2 komplett |
| **B: Local Multiplayer** | Input-Mapping pro Spieler, Split/Shared-Screen-Kamera-Logik | Stream A |
| **C: Scoring & HUD** | Punkte, Leben, Rundenanzahl, Score-Screen | Stream A |
| **D: Network Hooks** | Abstraktion für späteres Online-Netcode (Multiplayer-API vorbereiten) | Stream A+B |

---

### Phase 4 – Polish & Feedback
**Ziel**: Spielgefühl, Sound, VFX, Tutorial und Accessibility.

**Parallel-Streams:**

| Stream | Aufgaben | Abhängigkeiten |
|--------|---------|----------------|
| **A: Game Feel** | Screen Shake, Hit-Pause, Slow-Motion, Controller-Rumble | Phase 3 komplett |
| **B: Sound** | AudioStreamGenerator-Töne, Pitch-Shift für Combos, Spatial Audio | Phase 2 komplett |
| **C: VFX** | Destruction-Partikel, Spell-Trails (Line2D), Combo-Rune-Chain | Phase 2 komplett |
| **D: Tutorial** | 9-Schritte-Tutorial-Flow, Highlight-System, Skip-Option | Phase 3 komplett |
| **E: Accessibility** | Farbenblindmodi, Combo-Assist, Remapping, Textgröße | Phase 4 A-D |

---

### Phase 5 – Steam-Vorbereitung
**Ziel**: Release-fähig auf Steam.

| Aufgabe | Beschreibung |
|---------|-------------|
| Arena-Varianten | Alle 4 Maps implementiert und spielbar |
| Online-Multiplayer | Netcode via Godot High-Level Multiplayer API |
| Steam-Integration | Steamworks SDK, Achievements, Leaderboards |
| Launcher & Build | Export für Windows/Linux, Godot-Export-Templates |
| QA & Balancing | Playtesting, Parameter-Tuning basierend auf Feedback |

---

## Koordinationsregeln für Agenten
- Jeder Agent arbeitet an einem Stream und hält seinen Output in einem dedizierten Unterordner (`/scenes/`, `/scripts/`, `/ui/`, `/audio/`)
- Änderungen an shared Interfaces (z. B. `ArenaStateManager`-Signals) werden zuerst in `DESIGN.md` dokumentiert, bevor implementiert wird
- Commits immer mit Stream-Präfix: `[A] feat: ...`, `[B] fix: ...`
- Bei Abhängigkeitskonflikten: Stream blockiert sich selbst und signalisiert via GitHub Issue
