# Tool-Sammlung – HighFire Spellcraft Arena

Dieses Dokument sammelt externe Tools und Workflows die bei der Asset-Erstellung nützlich sind. Es ist kein verbindliches Design-Dokument – nur eine lebendige Referenz für den Auftraggeber.

Verbindliche Prozessregeln, Checklisten und Umsetzungs-Gates stehen in `AGENTS.md`.

---

## Dokumenten-Check

### Plan- und Link-Konsistenz
Prüft automatisiert:
- in `PLAN_PHASES.md`, ob als `✅ ABGESCHLOSSEN` markierte Streams noch offene `- [ ]`-Checkboxen enthalten
- in allen `*.md`-Dateien, ob interne Markdown-Links auf existierende Pfade zeigen
- ob Markdown-Dateien nur die Endung `.md` (klein) verwenden und keine `.MD`-Dateien existieren

**Ausführen:**
```bash
python3 tools/plan_consistency_check.py
```

**Erwartung:**
- Exit Code `0`: konsistent
- Exit Code `1`: Inkonsistenzen gefunden
- Exit Code `2`: Datei fehlt oder Lesefehler

---

## Musik

### Strudel (https://strudel.cc)
**Typ**: Live-Coding-Musikgenerator (Browser, JavaScript, kostenlos)
**Stärken:**
- Vollständig skriptbasiert – Musik entsteht durch Code-Patterns, nicht durch Klicken
- Algorithmisch: Patterns variieren sich selbst, kein statisches Loop-Gefühl
- BPM-synchron by default – perfekt für Layer-Systeme
- Läuft direkt im Browser, kein Install nötig

**Empfohlener Workflow für HighFire:**
1. Strudel im Browser öffnen, Musik-Layers scripten (85 BPM Basis, DnB-Breaks intern 170 BPM)
2. Jeden Layer einzeln aufnehmen (Browser-Audio-Capture oder Loopback-Recording)
3. In DAW auf Beat-Grenzen schneiden und Loop-Punkte setzen
4. Als OGG exportieren → in Godot einbinden

**Nicht empfohlen:** Direkte Laufzeit-Integration in Godot (AGPL-3.0-Lizenz problematisch für Steam-Release, Latenz-Risiko via WebSocket/OSC)

---

### Suno (https://suno.com)
**Typ**: KI-Musikgenerator, Text-Prompt → fertiger Track
**Stärken**: Schnelle Ergebnisse, Genre-Steuerung per Text, kostenloser Einstieg
**Schwächen**: Wenig Kontrolle über BPM/Struktur, Loop-Qualität variiert
**Workflow**: Prompt mit Stil (Power Metal, DnB, 85 BPM) → Track generieren → in DAW auf Loop-Punkte schneiden

---

### Udio (https://udio.com)
**Typ**: KI-Musikgenerator, ähnlich Suno
**Stärken**: Teils bessere Instrumentierung als Suno
**Status**: Noch in früher Phase, Verfügbarkeit schwankend

---

### Stable Audio (Adobe)
**Typ**: KI-Musikgenerator mit präziser Längensteuerung
**Stärken**: Gut für Loops definierter Länge, Adobe-Qualität
**Schwächen**: Adobe-Abo oder Pay-per-use

---

### LMMS (https://lmms.io)
**Typ**: DAW (Digital Audio Workstation), kostenlos, Open Source
**Verwendung**: Loop-Punkte setzen, Layer synchronisieren, OGG exportieren
**Hinweis**: Kein Profi-Tool, aber für den Zweck (Schneiden + Exportieren) völlig ausreichend

---

### GarageBand (macOS/iOS)
**Typ**: DAW, kostenlos für Apple-Geräte
**Verwendung**: Wie LMMS – Loop-Punkte, Export
**Hinweis**: Nur auf Apple-Hardware verfügbar

---

## Pixelart-Sprites

### PixelLab (https://www.pixellab.ai) ⭐ Empfehlung für HighFire
**Typ**: KI-Pixelart-Generator speziell für Spiele, cloudbasiert, kein leistungsstarker PC nötig
**Kosten**: Kostenloser Einstieg, kostenpflichtige Pläne für mehr Credits

**Warum ideal für HighFire:**
- **4-Richtungs-Rotation auf Knopfdruck**: Konzeptbild hochladen → automatisch alle 4 Richtungen als Spritesheet – löst das aufwändigste Problem bei Top-Down-Sprites
- **Animations-Generator**: Walk, Attack, Dodge, Cast per Text-Prompt oder Skeleton-Steuerung, direkt als animiertes Spritesheet exportierbar
- **Style-Konsistenz**: Alle Charaktere und Items bleiben im selben visuellen Stil – Tool „versteht" dein Referenzbild beim Generieren neuer Assets
- **Top-Down-Support**: Explizit für Top-Down- und isometrische Spiele ausgelegt
- **Tilesets & Environments**: Auch Arena-Tiles und Hintergründe generierbar (bis 400×400 px)
- **True Inpainting**: Teile eines Sprites gezielt bearbeiten ohne den Rest zu verändern

**Empfohlener Workflow für HighFire:**
1. Charakter-Konzept generieren (Text-Prompt: `top-down pixel art warrior, 48x48, neutral colors, dark fantasy`)
2. Rotation-Tool: automatisch 4 Richtungen erzeugen
3. Animations-Tool: `walk`, `attack_light`, `attack_heavy`, `cast`, `dodge`, `hit`, `death` generieren
4. Als Spritesheet exportieren (PNG, transparent)
5. Optional: Feinschliff in Aseprite

---

### Aseprite (https://www.aseprite.org)
**Typ**: Pixelart-Editor & Animations-Tool, ca. 20€ (einmalig)
**Empfehlung**: Standard-Tool für Spiel-Pixelart, Animation frame-weise, Spritesheet-Export direkt eingebaut
**Workflow**: KI-Referenz generieren → in Aseprite nachzeichnen/animieren → Spritesheet exportieren

---

### Midjourney (https://midjourney.com)
**Typ**: KI-Bildgenerator
**Stärken**: Beste visuelle Qualität, guter Pixelart-Stil mit passenden Prompts
**Schwächen**: Kein direktes Spritesheet-Layout, Nachbearbeitung in Aseprite nötig
**Empfohlener Prompt-Stil**: `top-down pixel art character, 48x48, transparent background, neutral colors, fantasy warrior, 4 directions`

---

### Leonardo.ai (https://leonardo.ai)
**Typ**: KI-Bildgenerator mit Pixelart-Modellen
**Stärken**: Konsistentere Charakter-Wiederholung als Midjourney, kostenloser Einstieg
**Schwächen**: Qualität unter Midjourney-Niveau

---

### Stable Diffusion (lokal)
**Typ**: Open-Source-KI-Bildgenerator
**Stärken**: Volle Kontrolle, Pixelart-LoRAs (Feintuning-Modelle) verfügbar, kostenlos
**Schwächen**: Technischer Einrichtungsaufwand, GPU empfohlen

---

## Sonstiges

*(Weitere Tools hier ergänzen)*
