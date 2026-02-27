# PR-Checkliste – HighFire

## 1) Kontext
- Phase/Stream: [ ] 2A [ ] 2B [ ] 2C [ ] 2D [ ] 3A [ ] 3B [ ] 3C [ ] 3D [ ] 3E [ ] 4A [ ] 4B [ ] 4C [ ] 4D [ ] 4E [ ] 4F [ ] 4G [ ] 4H [ ] 5A [ ] 5B [ ] 5C [ ] 5D [ ] 5E
- Branchname folgt Konvention (z. B. phase2/stream-a-motion-input): [ ] Ja
- Diese PR deckt genau einen Stream bzw. eine logische Einheit ab: [ ] Ja

## 2) Was wurde umgesetzt?
Kurzbeschreibung (Warum + Was):

-

## 3) Scope-Check gegen Plan
- Dateiliste aus PLAN_PHASES.md eingehalten: [ ] Ja
- Abhängigkeiten geprüft und erfüllt: [ ] Ja
- Keine unkoordinierten Änderungen an project.godot: [ ] Ja [ ] N/A

## 4) Cloud-Validierung
- GDScript-Syntax geprüft (headless check-only): [ ] Ja
- Szenen/Import geprüft (headless import): [ ] Ja [ ] N/A
- Keine neuen relevanten Fehler im geänderten Scope: [ ] Ja

## 5) Lokaler Pflicht-Test (Godot-Editor)
- Feature lokal getestet: [ ] Ja
- Input/Timing/Gameplay-Feel geprüft (falls relevant): [ ] Ja [ ] N/A
- HUD/UI-Lesbarkeit geprüft (falls relevant): [ ] Ja [ ] N/A
- Audio/VFX/Kamera geprüft (falls relevant): [ ] Ja [ ] N/A

Kurzer Testnachweis (Was, Ergebnis):

-

## 6) Akzeptanzkriterien
- Alle Kriterien des Streams erfüllt: [ ] Ja
- Offene Punkte / bekannte Einschränkungen dokumentiert: [ ] Ja [ ] N/A

Offene Punkte (falls vorhanden):

-

## 7) Dokumentation & Status
- Relevante Doku aktualisiert (PLAN_PHASES.md, DESIGN.md, TOOLS.md): [ ] Ja [ ] N/A
- Stream-Status in PLAN_PHASES.md aktualisiert (z. B. ✅ ABGESCHLOSSEN): [ ] Ja [ ] N/A

## 8) Risiko-Check
- Keine breaking Änderungen an Signalen/Interfaces ohne Doku: [ ] Ja
- Keine hardcodierten Balance-Werte statt .tres-Config: [ ] Ja
- Keine vermischten, unabhängigen Systeme in dieser PR: [ ] Ja

## 9) Reviewer-Hinweise
Bitte besonders prüfen:

-
