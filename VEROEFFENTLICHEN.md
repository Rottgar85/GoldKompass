# GoldKompass veröffentlichen

Statt die ZIP von Hand zu packen, baut GitHub sie automatisch und lädt sie zu CurseForge
(und auf Wunsch zu Wago) hoch. Diese Datei und der Ordner `.github` landen nicht in der ZIP.

## Einmalig einrichten

1. **GitHub-Repository anlegen** und diesen Ordner (`GoldKompass`) als Inhalt hochladen.
   Die Datei `.pkgmeta` muss direkt im Hauptverzeichnis des Repositorys liegen.
2. **CurseForge-Projekt-ID:** ist bereits in `GoldKompass.toc` eingetragen (`## X-Curse-Project-ID: 1768724`).
   Für Wago zusätzlich: `## X-Wago-ID: abcdef12` (deine Wago-ID)

## Ohne GitHub: ZIP von Hand hochladen

Auf curseforge.com → Projekt 1768724 → „Upload File“ die fertige ZIP wählen
(z. B. `GoldKompass-0.25.3.zip`), als Spielversion Retail 12.0 angeben, Release-Typ „Release“
und den Abschnitt der neuen Version aus `CHANGELOG.md` als Changelog einfügen.
3. **API-Schlüssel als GitHub-Secrets hinterlegen** (Repository → Settings → Secrets and variables → Actions):
   - `CF_API_KEY`: auf curseforge.com unter Konto → API Tokens erzeugen
   - `WAGO_API_TOKEN`: auf addons.wago.io unter Account → API Keys (nur wenn du Wago nutzt)
   Das GitHub-Token ist automatisch vorhanden.

## Neue Version veröffentlichen

1. In `GoldKompass.toc` die `## Version:` erhöhen und in `CHANGELOG.md` eintragen, was neu ist.
2. Änderungen hochladen (commit und push).
3. Einen Tag mit der Version setzen und hochladen, zum Beispiel:
   `git tag v0.23.0` und dann `git push origin v0.23.0`
4. Unter „Actions“ im Repository siehst du, wie die ZIP gebaut und hochgeladen wird.
   Die fertige ZIP liegt danach auch unter „Releases“.
