# Tool-Sammlung – HighFire Spellcraft Arena

Dieses Dokument sammelt externe Tools und Workflows die bei der Asset-Erstellung nützlich sind. Es ist kein verbindliches Design-Dokument – nur eine lebendige Referenz für den Auftraggeber.

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
