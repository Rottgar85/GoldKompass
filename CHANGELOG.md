# GoldKompass Changelog

## 0.26.0

**English**
- Records: best farm hour, best day and best week, shown on the Week tab and with /gk records. A new record is celebrated with a short golden pop-up
- Weekly goal reached: pop-up once per week
- Week tab: comparison with the 7 days before in percent
- Savings goals: shift-click an item into the name field and the goal shows its icon
- Introduction: on first open, three tips explain the sidebar (/gk tour shows them again)
- Pages fade in smoothly

**Deutsch**
- Rekorde: beste Farm-Stunde, bester Tag und beste Woche, im Reiter Woche und mit /gk rekorde. Ein neuer Rekord wird kurz golden eingeblendet
- Wochenziel erreicht: Einblendung einmal pro Woche
- Reiter Woche: Vergleich mit den 7 Tagen davor in Prozent
- Sparziele: Gegenstand per Shift-Klick ins Namensfeld, dann zeigt das Ziel sein Symbol
- Einführung: beim ersten Öffnen erklären drei Hinweise die Seitenleiste (/gk tour zeigt sie erneut)
- Seiten blenden weich ein
## 0.25.3

**English**
- The overview always stays open: Routes and goals, Areas and inventory, Analysis, Sell helper and Own route now open to the right of it instead of replacing it. Clicking "Overview" closes the extra page again
- English: every command has an English name (/gk history, /gk goal, /gk guild on, /gk loot clear, /gk memory clean, /gk design blue …). In English mode the command list, help texts, settings page and chat messages show the English commands; the German commands keep working
- CurseForge project ID added

**Deutsch**
- Die Übersicht bleibt immer offen: Routen und Ziele, Gebiete und Inventar, Analyse, Verkaufshelfer und Eigene Route öffnen sich rechts daneben statt sie zu ersetzen. Ein Klick auf „Übersicht“ schließt die Zusatzseite wieder
- Englisch: alle Befehle haben englische Namen (/gk history, /gk goal, /gk guild on, /gk loot clear, /gk memory clean, /gk design blue …). Befehlsliste, Hilfetexte, Einstellungsseite und Chat-Meldungen zeigen im englischen Modus die englischen Befehle; die deutschen Befehle funktionieren weiterhin
- CurseForge-Projekt-ID eingetragen

## 0.25.2
- Fensterpositionen bleiben nach /reload und Neustart erhalten: Seitenleiste, alle Seiten (auch ohne Seitenleiste), Gruppen-Beute, Willkommensseite, Sicherung und Export; Farm-Fenster, Wochenleiste und Minimap-Button wie bisher
- Positionen stimmen auch nach einer Änderung der Fenstergröße
- Gruppen-Beute dockt nur noch ans Farm-Fenster an, solange du sie nicht selbst verschoben hast
- Positionen sind Teil der Sicherung „Einstellungen“

## 0.25.1
- Englisch: Der Reiter Today (und alle anderen Fenster) springt nicht mehr zwischen Deutsch und Englisch hin und her. Texte werden jetzt im selben Moment übersetzt, in dem sie gesetzt werden, und beim Öffnen eines Fensters sofort
- Englisch: Auswahllisten in den Optionen (Alarm-Sound, Preisquelle, Design) übersetzt, ebenso die Zeile „Roh“ im Farm-Fenster und weitere Fenstertitel

## 0.25.0
- Ein Fenster mit Seitenleiste: Übersicht, Routen und Ziele, Gebiete und Inventar, Analyse, Verkaufshelfer und Eigene Route erscheinen als Seiten am selben Platz (abschaltbar in den Einstellungen)
- Sprache wählbar: Automatisch, Deutsch oder English, per Knopf in der Seitenleiste, in den Einstellungen oder mit /gk sprache de|en|auto; deutlich mehr Texte übersetzt (Willkommensseite, Verkaufshelfer, Eigene Route, Gruppen-Beute, Farmzeit, Sicherung, Hilfetexte aller Befehle, Chat-Meldungen)
- Fenstergröße und Farm-Fenster-Größe einstellbar, Fenster und Farm-Fenster sperrbar (/gk groesse, /gk sperren)
- Im Kampf ausblenden (wahlweise): Fenster verschwinden im Kampf und kommen danach wieder
- Anzeige in Titan Panel, ElvUI, Bazooka und anderen LibDataBroker-Leisten
- Sicherung: Einstellungen oder alle Daten als Text exportieren und importieren (/gk sicherung); der Import führt keinen Code aus
- Speicher anzeigen und aufräumen (/gk speicher, /gk speicher aufraeumen)
- Selbsttest (/gk selbsttest) prüft Addon-Teile, Spielfunktionen, Preisquellen und Interface-Nummer
- Gespeicherte Daten haben jetzt eine Versionsnummer; alte Stände werden beim Laden automatisch umgewandelt
- Einstellungsseite im Blizzard-Menü erweitert: Darstellung, Sprache, Sicherung, Speicher, Selbsttest
- CurseForge-Beschreibung (Deutsch und Englisch) und Logo als 512-px-PNG

## 0.24.1
- Tastenbelegung: Fenster öffnen/schließen, Farm starten/stoppen und Pause (Esc > Optionen > Tastenbelegung > AddOns > GoldKompass), funktioniert auch im Kampf
- Das Hauptfenster lässt sich immer umschalten, auch wenn beim Füllen ein Fehler auftritt (der Fehler wird trotzdem gemeldet)
- Midnight: geschützte („geheime“) Chat- und Addon-Nachrichten im Kampf werden übersprungen statt einen Fehler auszulösen

## 0.24.0
- Goldbeträge mit Gold- und Silbermünzen aus dem Spiel und Tausenderpunkten (12.345 statt 12345g 00s)
- Reiter Heute: drei Kacheln oben für Gold heute, Gold pro Stunde und Wochenziel mit Balken (Klick führt zum Reiter)
- Reiter mit Symbolen, der aktive Reiter ist farbig hinterlegt; Charaktername in der Kopfzeile
- Farm-Fenster: die wertvollsten Funde als Symbole mit Rahmen in Qualitätsfarbe und Anzahl, Tooltip beim Drüberfahren
- Farm-Fenster: Balken für das Zeitlimit (/gk dauer)
- Wochenleiste: Striche bei 25, 50 und 75 % und Beträge mit Münzsymbol
- Einblendung seltener Funde in der Qualitätsfarbe des Gegenstands

## 0.23.0
- Neu: Gold-Verlauf als Linie über 30 Tage, 90 Tage oder 1 Jahr (/gk verlauf oder Knopf „Verlauf“ im Reiter Woche)
- Neu: Items pro Stunde je Gebiet aus deinen Farm-Sessions (/gk items oder Knopf „Items/h“ im Reiter Farm)
- Neu: Gold der Kriegsmeute-Bank zählt beim Gesamtgold und bei den Sparzielen mit; Ein- und Auszahlungen gelten nicht als Einnahme oder Ausgabe
- Neu: Auktionshaus-Verkäufe aus der Post werden als eigene Quelle erfasst, mit Wochensumme im Reiter Woche
- Neu: GoldKompass im Addon-Menü an der Minimap und unter Esc > Optionen > AddOns (/gk einstellungen)
- Neu: /gk befehle listet alle Befehle; unbekannte Befehle werden gemeldet statt das Fenster zu öffnen
- Neu: /gk ziel aus entfernt das Wochenziel
- Neu: /gk sprachcheck zeigt im englischen Modus Texte, denen die Übersetzung fehlt
- Intern: alle Befehle laufen über ein zentrales Register, doppelte Namen werden als Fehler gemeldet
- Intern: ein einziger Goldzähler statt drei getrennter
- Intern: weniger Dauer-Timer; auf Deutsch durchsucht das Addon die Fenster nicht mehr nach Texten
- Veröffentlichung: .pkgmeta und GitHub-Workflow für automatisches Packen (siehe VEROEFFENTLICHEN.md)

## 0.22.1
- /gk ziel 5000 setzt wieder das Wochenziel (ohne Betrag öffnet /gk ziel die Sparziele)
- /gk language en und die anderen englischen Befehlsnamen für die Sprache funktionieren
- Stopp während der Pause zählt Funde aus der Pause nicht mehr mit
- Symbole vor den Goldquellen im Reiter Heute und Logo im Hauptfenster wieder sichtbar
- GoldKompass verändert die globale print-Funktion nicht mehr (keine Auswirkung auf andere Addons)
- Keine Lade-Meldungen von Startseite und Gruppenfenster mehr im Chat
- Kein doppelter Ton mehr bei blauen und epischen BoE-Funden
- Englische Übersetzung der Post- und Auktions-Erinnerung
- Eigenes GoldKompass-Logo in der Addon-Liste, am Minimap-Button, im Hauptfenster und auf der Willkommensseite
- Aufgeräumt: doppelte Kartenanzeige und altes Gruppen-Beute-Fenster entfernt, leere Extras3.lua entfernt

## 0.22.0
- Gruppen-Beute: eigenes kompaktes Fenster im Stil des Farm-Fensters, zeigt nur die 8 wertvollsten Drops, in der Größe veränderbar, folgt der Designfarbe aus den Optionen
- Gruppenfarm: Knöpfe „Host starten“ und „Beitreten“ im Gruppe-Reiter; die Farm heißt „Name (Host)“
- /gkgruppe und /gk beute öffnen die Gruppen-Beute
- Gruppen-Beute wird zusammen mit dem Farm-Fenster ein- und ausgeblendet

## 0.21.0
- Farm-Fenster: Tooltips über Gegenständen
- Pause-Funktion (Knopf im Farm-Fenster oder /gk pause)
- Sitzung wird nach Reload oder Neustart wiederhergestellt (max. 2 Stunden alt)
- Anzeige in der Pause korrigiert (kein Springen mehr)
- Schalter Verkaufshelfer und Post-Erinnerung in den Optionen funktionieren jetzt
- Allgemeine Verbesserungen und Fehlerbehebungen

## 0.1.0
- Erste Version: Goldverlauf, Farm-Rechner, Minimap-Button
