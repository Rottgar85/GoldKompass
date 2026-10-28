-- GoldKompass Sprache: Deutsch und Englisch.
-- Die Texte im Addon sind deutsch. Diese Datei uebersetzt sie fuer die Anzeige (Fenster, Tooltips, Chat), ohne den
-- Rest des Addons anzufassen. Sprache: /gk sprache auto|de|en (danach /reload). "auto" folgt der Spielsprache.
-- Befehle gibt es zusaetzlich auf Englisch (/gk window, /gk options, /gk goal ...).
local GK = GoldKompass

-- Ganze Texte -------------------------------------------------------------------------------------------------
local X = {
    ["Heute"] = "Today", ["Woche"] = "Week", ["Beute"] = "Loot", ["Gruppe"] = "Group", ["Mehr"] = "More",
    ["Optionen"] = "Options", ["Fertig"] = "Done", ["Stopp"] = "Stop", ["Abziehen"] = "Deduct", ["Setzen"] = "Set",
    ["Verkaufshelfer"] = "Sell helper", ["Routen"] = "Routes", ["Ziele"] = "Goals", ["Preise"] = "Prices",
    ["Rückblick"] = "Recap", ["Gebiete"] = "Areas", ["Schnäppchen"] = "Bargains", ["Inventar"] = "Inventory",
    ["Merken"] = "Save", ["Löschen"] = "Delete", ["Weg"] = "Remove", ["Karte öffnen"] = "Open map",
    ["Auswahl lösen"] = "Clear selection", ["Im Chat zeigen"] = "Show in chat", ["Neu erstellen"] = "Create new",
    ["Suche"] = "Search", ["Ziel"] = "Goal", ["Fenster"] = "Window", ["Historie"] = "History",
    ["Taschen"] = "Bags", ["Funde"] = "Finds", ["Charaktere"] = "Characters",
    ["Alarm"] = "Alarm", ["Alarm: an"] = "Alarm: on", ["Alarm: aus"] = "Alarm: off",
    ["Blau"] = "Blue", ["Grün"] = "Green", ["Violett"] = "Purple", ["Rot"] = "Red",
    ["Saldo"] = "Balance", ["Erhalten"] = "Received", ["Ausgegeben"] = "Spent", ["Gesamtwert"] = "Total value",
    ["Du hast"] = "You have", ["Wert"] = "Value", ["Ton"] = "Sound",
    ["Verkaufspreis"] = "Vendor price", ["TSM Marktwert"] = "TSM market value", ["TSM Mindestgebot"] = "TSM min buyout",
    ["Kassen-Klingeln"] = "Cash register", ["Quest fertig"] = "Quest complete",
    ["Verlauf"] = "History", ["Einstellungen"] = "Settings", ["Pro Stunde"] = "Per hour",
    ["keine Farm"] = "no farm", ["kein Ziel"] = "no goal",
    -- 0.25: Seitenleiste, Einstellungsseite, Sicherung
    ["Übersicht"] = "Overview", ["Routen und Ziele"] = "Routes and goals", ["Gebiete und Inventar"] = "Areas and inventory",
    ["Analyse"] = "Analysis", ["Eigene Route"] = "Own route", ["Schließen"] = "Close",
    ["Sicherung"] = "Backup", ["Speicher prüfen"] = "Check memory", ["Selbsttest"] = "Self-test",
    ["Darstellung"] = "Appearance", ["Fenstergröße"] = "Window size", ["Farm-Fenster-Größe"] = "Farm window size",
    ["Ein Fenster mit Seitenleiste"] = "One window with sidebar", ["Fenster sperren"] = "Lock window",
    ["Farm-Fenster sperren"] = "Lock farm window", ["Im Kampf ausblenden"] = "Hide in combat",
    ["Einstellungen exportieren"] = "Export settings", ["Alles exportieren"] = "Export everything",
    ["Importieren"] = "Import", ["Leeren"] = "Clear", ["GoldKompass · Sicherung"] = "GoldKompass · Backup",
    -- 0.25: Sprachwahl
    ["Sprache"] = "Language", ["Automatisch"] = "Automatic", ["Deutsch"] = "Deutsch", ["English"] = "English",
    ["Sprache: Automatisch"] = "Language: Automatic", ["Sprache: Deutsch"] = "Language: Deutsch", ["Sprache: English"] = "Language: English",
    -- Willkommensseite
    ["Willkommen bei GoldKompass"] = "Welcome to GoldKompass", ["Verstanden"] = "Got it",
    -- Verkaufshelfer
    ["GoldKompass · Verkaufshelfer"] = "GoldKompass · Sell helper", ["Neu laden"] = "Refresh",
    ["Graue Items verkaufen"] = "Sell grey items", ["Mindestgewinn (Gold):"] = "Min. profit (gold):",
    ["   Nichts, das dort genug mehr bringt als beim Händler."] = "   Nothing that earns enough more there than at the vendor.",
    ["   Nichts mit Händlerwert."] = "   Nothing with vendor value.",
    ["Zum Verkaufen erst einen Händler öffnen."] = "Open a vendor to sell.",
    ["Keine graue Ware in den Taschen."] = "No grey items in your bags.",
    ["Erst einen Händler öffnen."] = "Open a vendor first.", ["Keine graue Ware gefunden."] = "No grey items found.",
    ["Der Verkaufshelfer ist in den Optionen ausgeschaltet."] = "The sell helper is turned off in the options.",
    ["Bitte eine Zahl in Gold eingeben, zum Beispiel 5 oder 2,5."] = "Please enter a number in gold, for example 5 or 2.5.",
    ["Klick: nie wieder vorschlagen"] = "Click: never suggest again", ["Klick: Sperre aufheben"] = "Click: unblock",
    -- Eigene Route
    ["GoldKompass · Eigene Route"] = "GoldKompass · Own route", ["Aufnahme starten"] = "Start recording",
    ["Aufnahme stoppen"] = "Stop recording", ["Punkt setzen"] = "Set point", ["Letzten weg"] = "Remove last",
    ["Verwerfen"] = "Discard", ["Speichern"] = "Save", ["Gewählte Route löschen"] = "Delete selected route",
    ["Route anklicken = Auswahl"] = "Click a route to select it",
    ["Bitte einen Namen für die Route eintragen."] = "Please enter a name for the route.",
    ["Eine Route braucht mindestens zwei Punkte."] = "A route needs at least two points.",
    ["Hier gibt es keine Karte (Instanz?). Dort geht keine Route."] = "There is no map here (instance?). Routes don't work here.",
    ["Du hast die Karte gewechselt. Route erst speichern oder verwerfen."] = "You changed the map. Save or discard the route first.",
    ["Position ist hier nicht abrufbar."] = "Your position is not available here.",
    -- Gruppe und Gruppen-Beute
    ["Gruppen-Beute"] = "Group loot", ["Host starten"] = "Start host", ["Host stoppen"] = "Stop host", ["Beitreten"] = "Join",
    ["Gruppen-Beute ist nicht geladen."] = "Group loot is not loaded.", ["Gruppen-Beute geöffnet."] = "Group loot opened.",
    ["Gruppen-Beute geleert."] = "Group loot cleared.", ["Gerade farmt niemand in der Gruppe."] = "Nobody in the group is farming right now.",
    ["Es läuft schon eine eigene Farm."] = "Your own farm is already running.",
    -- Farmzeit
    ["Farmzeit (Min, 0 = unendlich):"] = "Farm time (min, 0 = unlimited):", ["unbegrenzt"] = "unlimited",
    ["Farm-Dauer unbegrenzt."] = "Farm duration unlimited.",
    ["Bitte eine Zahl in Minuten eingeben, zum Beispiel 30. 0 heisst unendlich."] = "Please enter a number of minutes, for example 30. 0 means unlimited.",
    ["Benutzung: /gk dauer 30  (Minuten, 0 = unendlich)"] = "Usage: /gk dauer 30  (minutes, 0 = unlimited)",
    -- Pause und Sitzung
    ["Pause beendet, die Session laeuft weiter. Funde waehrend der Pause wurden nicht mitgezaehlt."] = "Pause ended, the session continues. Loot during the pause was not counted.",
    ["Session pausiert. Zeit und Funde stehen, bis du nochmal /gk pause eingibst oder den Knopf drueckst."] = "Session paused. Time and loot stop until you type /gk pause again or press the button.",
    -- Tagesuebersicht, Gilde
    ["Gestern: keine Aufzeichnung."] = "Yesterday: nothing recorded.", ["Noch keine beendete Farm-Session."] = "No finished farm session yet.",
    ["Gold pro Stunde je Charakter (Durchschnitt, netto):"] = "Gold per hour by character (average, net):",
    ["Tagesuebersicht beim Login an."] = "Daily summary at login on.", ["Tagesuebersicht beim Login aus."] = "Daily summary at login off.",
    ["BoE-Ton bei jedem BoE-Item."] = "BoE sound for every BoE item.",
    ["Du teilst dein Wochengold nicht. Einschalten: /gk gilde an"] = "You don't share your weekly gold. Turn on: /gk guild on",
    ["Von anderen ist noch nichts angekommen (sie brauchen GoldKompass und muessen /gk gilde an gesetzt haben)."] = "Nothing received from others yet (they need GoldKompass and /gk guild on).",
    ["So: /gk gilde ziel 50000   (Gold)"] = "Usage: /gk guild goal 50000   (gold)",
    ["Du teilst jetzt dein Wochengold mit der Gilde."] = "You now share your weekly gold with the guild.",
    ["Du teilst dein Wochengold nicht mehr."] = "You no longer share your weekly gold.",
    ["|cff66ff66Gilden-Wochenziel erreicht!|r"] = "|cff66ff66Guild weekly goal reached!|r",
    -- Sicherung, Speicher, Selbsttest
    ["Das ist kein GoldKompass-Sicherungstext."] = "This is not a GoldKompass backup text.",
    ["Der Text ist beschädigt (Zeichen fehlen oder sind falsch)."] = "The text is damaged (characters are missing or wrong).",
    ["Die Einstellungen im Text sind ungültig."] = "The settings in the text are invalid.",
    ["Einstellungen übernommen."] = "Settings imported.", ["Alle Daten übernommen."] = "All data imported.",
    ["Einstellungen aus der Sicherung übernehmen."] = "Import the settings from the backup.",
    ["ALLE Daten aus der Sicherung übernehmen."] = "Import ALL data from the backup.",
    ["Selbsttest läuft ..."] = "Self-test running ...",
    ["Fenster gesperrt."] = "Window locked.", ["Fenster verschiebbar."] = "Window movable.",
    ["geladen. /gk Fenster, /gk optionen, /gk start, /gk stop, /gk befehle."] = "loaded. /gk window, /gk options, /gk start, /gk stop, /gk commands.",
    -- Hilfetexte der Befehle (/gk befehle und Einstellungsseite)
    ["Farm-Session starten (optional mit Name)"] = "Start a farm session (optional name)",
    ["Farm-Session beenden"] = "End the farm session",
    ["Farm-Session pausieren / fortsetzen"] = "Pause / resume the farm session",
    ["Preisalarm: alarm add [Item] 150, alarm del 1, alarm test"] = "Price alarm: alarm add [item] 150, alarm del 1, alarm test",
    ["Optionen öffnen"] = "Open options",
    ["Kosten zur laufenden Farm buchen (Gold)"] = "Book costs for the running farm (gold)",
    ["Wochenziel setzen: ziel 5000, ziel aus"] = "Set the weekly goal: goal 5000, goal off",
    ["Farm-Fenster: Items unter X Gold ausblenden"] = "Farm window: hide items below X gold",
    ["Farm-Sessions als Tabelle exportieren"] = "Export farm sessions as a table",
    ["Wertwarner: meldet Funde ab X Gold (0 = aus)"] = "Value warning: reports finds from X gold (0 = off)",
    ["Plus-Fenster (Routen, Ziele, Material, Preise)"] = "Plus window (routes, goals, materials, prices)",
    ["Routen im Plus-Fenster"] = "Routes in the Plus window", ["Sparziele"] = "Savings goals",
    ["Material-Tracker"] = "Material tracker", ["Preisverlauf"] = "Price history",
    ["Wochen-Rückblick im Chat"] = "Weekly recap in chat",
    ["Farbe: design gold|blau|gruen|violett|rot"] = "Color: design gold|blue|green|purple|red",
    ["Mehr-Fenster (Gebiete, Schnäppchen, Inventar, Bericht)"] = "More window (areas, bargains, inventory, report)",
    ["Gebiete im Vergleich"] = "Areas compared", ["Inventar aller Charaktere"] = "Inventory of all characters",
    ["Wochenbericht zum Kopieren"] = "Weekly report to copy", ["Schnäppchen-Alarm: dip an|aus|25"] = "Bargain alarm: bargain on|off|25",
    ["Start/Stopp-Leiste unter dem Fenster an/aus"] = "Start/stop bar below the window on/off",
    ["Sprache: sprache de|en|auto"] = "Language: language de|en|auto",
    ["Zeigt Texte, denen die englische Übersetzung fehlt"] = "Shows texts that are missing an English translation",
    ["Tagesübersicht (gestern und Wochenziel)"] = "Daily summary (yesterday and weekly goal)",
    ["Tagesübersicht beim Login an/aus"] = "Daily summary at login on/off",
    ["BoE-Ton erst ab X Gold Wert (0 = immer)"] = "BoE sound only from X gold value (0 = always)",
    ["Gold pro Stunde je Charakter"] = "Gold per hour by character",
    ["Gilden-Wochenziel: gilde, gilde ziel 50000, gilde an|aus"] = "Guild weekly goal: guild, guild goal 50000, guild on|off",
    ["Willkommensseite mit Erklärung"] = "Welcome page with explanation", ["Eigene Route aufzeichnen"] = "Record your own route",
    ["Verkaufshelfer: was ins Auktionshaus, was zum Händler"] = "Sell helper: what goes to the auction house, what to the vendor",
    ["Hauptfenster im Reiter Gruppe (taschen/funde: Reiter Beute)"] = "Main window on the Group tab (bags/finds: Loot tab)",
    ["Gruppen-Beute (beute leeren setzt sie zurück)"] = "Group loot (loot clear resets it)",
    ["Farm stoppt automatisch nach X Minuten (0 = nie)"] = "Farm stops automatically after X minutes (0 = never)",
    ["Gold-Verlauf als Linie (30/90/365 Tage)"] = "Gold history as a line (30/90/365 days)",
    ["Items pro Stunde je Gebiet"] = "Items per hour by area",
    ["GoldKompass im Blizzard-Optionsmenü öffnen"] = "Open GoldKompass in the Blizzard options",
    ["Fenstergröße: groesse 0.9 oder groesse 110"] = "Window size: scale 0.9 or scale 110",
    ["Fensterposition sperren/entsperren"] = "Lock/unlock the window position",
    ["Sicherung: Einstellungen oder alle Daten exportieren/importieren"] = "Backup: export/import settings or all data",
    ["Speicher anzeigen, speicher aufraeumen räumt alte Daten weg"] = "Show memory, memory clean removes old data",
    ["Prüft, ob alle Teile und Spielfunktionen da sind"] = "Checks that all parts and game functions are present",
    ["Sprachwahl: Deutsch, English oder automatisch"] = "Choose language: Deutsch, English or automatic",
    ["GoldKompass: %s\n\nDie vorhandenen Werte werden dabei überschrieben. Fortfahren?"] = "GoldKompass: %s\n\nExisting values will be overwritten. Continue?",
    ["GoldKompass: Damit alles wirkt, die Oberfläche jetzt neu laden?"] = "GoldKompass: Reload the interface now so everything takes effect?",
    ["Hinweis"] = "Note", ["FEHLT"] = "MISSING", ["Wertwarner aus."] = "Value warning off.",
    -- Auswahllisten in den Optionen (Alarm-Sound, Design) und Plus-Reiter
    ["Auktionshaus auf"] = "Auction house open", ["Auktionshaus zu"] = "Auction house close",
    ["Bereitschaftscheck"] = "Ready check", ["Schlachtzugswarnung"] = "Raid warning", ["Ruhmeshalle"] = "Hall of fame",
    ["Gold"] = "Gold", ["Material"] = "Materials", ["Design"] = "Theme", ["GoldKompass · Mehr"] = "GoldKompass · More",
    ["Tagesbilanz"] = "Daily balance", ["Farm-Sessions"] = "Farm sessions", ["Wochengold"] = "Weekly gold",
    ["Gold je Charakter"] = "Gold by character", ["Eigene Routen"] = "Own routes", ["Routen-Statistik"] = "Route statistics",
    ["Laufende Session"] = "Running session", ["Preisalarme"] = "Price alarms", ["Verkaufs-Sperrliste"] = "Sell block list",
    ["Gespeicherte Daten geladen"] = "Saved data loaded", ["Hauptfenster bauen"] = "Build main window",
    ["Hauptfenster füllen"] = "Fill main window",
    ["Hauptfenster füllen: nur prüfbar, wenn die Übersicht offen ist (/gk, dann /gk selbsttest)"] = "Fill main window: only testable while the overview is open (/gk, then /gk selftest)",
    ["Anzeige in Titan Panel/ElvUI/Bazooka (LibDataBroker)"] = "Display in Titan Panel/ElvUI/Bazooka (LibDataBroker)",
    -- Rekorde, Einblendungen, Einfuehrung (Rekorde.lua)
    ["Neuer Rekord: bester Tag!"] = "New record: best day!", ["Neuer Rekord: beste Woche!"] = "New record: best week!",
    ["Neuer Rekord: beste Farm-Stunde!"] = "New record: best farm hour!", ["Wochenziel erreicht!"] = "Weekly goal reached!",
    ["Deine Rekorde"] = "Your records", ["Beste Farm-Stunde"] = "Best farm hour", ["Bester Tag"] = "Best day",
    ["Beste Woche"] = "Best week", ["Überspringen"] = "Skip", ["Weiter"] = "Next",
    ["Hier ist deine Übersicht: Gold heute, Gold pro Stunde und Wochenziel."] = "This is your overview: gold today, gold per hour and weekly goal.",
    ["Weitere Seiten öffnen sich rechts neben der Übersicht. Ein Klick auf Übersicht schließt sie wieder."] = "More pages open to the right of the overview. Click Overview to close them again.",
    ["Sprache, Optionen und Einstellungen findest du unten. Viel Spaß beim Farmen!"] = "Language, options and settings are at the bottom. Happy farming!",
    ["Einführung erneut zeigen"] = "Show the introduction again",
    ["Rekorde: beste Stunde, bester Tag, beste Woche"] = "Records: best hour, best day, best week",
    ["Vergleich zu den 7 Tagen davor"] = "Compared to the 7 days before",
}

-- Textteile (werden laengste zuerst ersetzt) ------------------------------------------------------------------
local R = {
    -- Rekorde und Vorwoche (Reiter Woche)
    { "Vergleich zu den 7 Tagen davor", "Compared to the 7 days before" }, { "Beste Farm-Stunde", "Best farm hour" },
    { "Bester Tag", "Best day" }, { "Beste Woche", "Best week" }, { "|cff66ff66neu|r", "|cff66ff66new|r" },
    -- Kompakt-Fenster
    { "Aufzeichnung ist aus (Optionen).", "Recording is off (Options)." },
    { "Aufzeichnung ist aus (/gk optionen).", "Recording is off (/gk optionen)." },
    { "Gold gesamt (alle Charaktere)", "Total gold (all characters)" },
    { "Heute eingenommen", "Earned today" }, { "Heute ausgegeben", "Spent today" }, { "Saldo heute", "Balance today" },
    { "Woher / wohin heute", "Where from / where to today" },
    { "Noch nichts aufgezeichnet.", "Nothing recorded yet." },
    { "Wochenziel (Netto aus Farm-Sessions)", "Weekly goal (net from farm sessions)" },
    { "Wochenziel (erhaltenes Gold seit Montag)", "Weekly goal (gold received since Monday)" },
    { "Wochenziel (erhaltenes Gold seit Montag: Loot, Quests, Post)", "Weekly goal (gold received since Monday: loot, quests, mail)" },
    { "Ziel erreicht!", "Goal reached!" }, { "Noch offen: ", "Remaining: " },
    { "Kein Ziel gesetzt: oben Betrag eintragen.", "No goal set: enter an amount above." },
    { "Diese Woche bisher", "This week so far" },
    { "Letzte 7 Tage (Saldo)", "Last 7 days (balance)" },
    { "Summe 7 Tage: ein ", "7-day total: in " }, { "  aus ", "  out " },
    { "Ort: ", "Location: " }, { "Läuft mit Route:", "Running with route:" }, { "Läuft:", "Running:" }, { "Laeuft:", "Running:" },
    { "Rohgold", "Raw gold" }, { "Item-Wert", "Item value" }, { "Kosten (g)", "Costs (g)" }, { "Kosten", "Costs" },
    { "Gold pro Stunde", "Gold per hour" },
    { "Keine Session aktiv. Start startet eine für deinen Ort.", "No session active. Start begins one for your location." },
    { "Keine Session aktiv. Start drueckt eine Session fuer deinen aktuellen Ort.", "No session active. Start begins one for your location." },
    { "Beste Gebiete (netto pro Stunde)", "Best areas (net per hour)" },
    { "Noch keine beendete Session.", "No finished session yet." },
    { "Letzte Sessions", "Recent sessions" },
    { "Farm-Empfehlung aus deinen eigenen Sessions", "Farm recommendation from your own sessions" },
    { "Noch zu wenig Daten. Beende ein paar Sessions von mindestens 5 Minuten.", "Not enough data yet. Finish a few sessions of at least 5 minutes." },
    { "  am besten ", "  best " }, { "nachmittags", "in the afternoon" }, { "vormittags", "in the morning" },
    { "abends", "in the evening" }, { "nachts", "at night" },
    { "Wert deiner Taschen", "Bag value" }, { "Bank beim letzten Besuch", "Bank at last visit" },
    { "Bank einmal öffnen", "Open the bank once" }, { "Wertvollste Stapel", "Most valuable stacks" },
    { "Teuerste Funde", "Most valuable finds" }, { "Noch nichts erfasst.", "Nothing recorded yet." },
    { "Erhaltenes Gold diese Woche", "Gold received this week" }, { "Alle zusammen", "All combined" },
    { "Gold auf den Charakteren", "Gold on characters" },
    { "Gruppen-Farm (alle brauchen GoldKompass)", "Group farm (everyone needs GoldKompass)" },
    { "Du bist in keiner Gruppe.", "You are not in a group." },
    { "Niemand farmt gerade. Start drücken, dann sehen es die anderen.", "Nobody is farming right now. Press Start and the others will see it." },
    { "Gemeinsam: ", "Together: " }, { "pro Kopf: ", "per person: " },
    { "GoldKompass-Spieler in der Gruppe", "GoldKompass players in the group" },
    { "Items ab (g)", "Items from (g)" }, { "Wochenziel (g)", "Weekly goal (g)" },
    -- Optionen
    { "GoldKompass · Optionen", "GoldKompass · Options" },
    { "Gold aufzeichnen", "Record gold" }, { "Farm-Rechner", "Farm calculator" }, { "Minimap-Button", "Minimap button" },
    { "Begrüßung beim Login", "Greeting on login" }, { "Wochenleiste zeigen", "Show week bar" },
    { "Leiste sperren", "Lock bar" }, { "Reparatur als Kosten", "Repairs as costs" },
    { "Woche nur aus Farm", "Week from farming only" },
    { "Ton bei grüner Beute", "Sound for Bind on Equip loot" }, { "Ton bei BoE-Beute", "Sound for Bind on Equip loot" },
    { "Einblendung blau/episch", "Popup for blue/epic" }, { "Meilenstein-Ton", "Milestone sound" },
    { "Tagesbilanz beim Logout", "Daily summary on logout" }, { "Preise im Tooltip", "Prices in tooltip" },
    { "Post/Auktions-Erinnerung", "Mail/auction reminder" }, { "Gruppe: Daten teilen", "Group: share data" },
    { "Gruppe: automatisch mit", "Group: auto-join" }, { "Preisalarm", "Price alarm" },
    { "Alarm: Ton", "Alarm: sound" }, { "Alarm: Einblendung", "Alarm: popup" }, { "Alarm: Chat", "Alarm: chat" },
    { "Alarm-Sound", "Alarm sound" }, { "Preisquelle", "Price source" },
    { "Wertwarner ab (g, 0 = aus)", "Value warning from (g, 0 = off)" },
    { "Wertwarner ab (Gold, 0 = aus):", "Value warning from (gold, 0 = off):" },
    { "Auctionator nicht gefunden.", "Auctionator not found." }, { "TSM nicht gefunden.", "TSM not found." },
    { "Ersatz: Auctionator oder Händlerpreis.", "Fallback: Auctionator or vendor price." },
    { "Ersatz: Händlerpreis.", "Fallback: vendor price." },
    { "Mehr Funktionen", "More features" },
    -- Wochenleiste und Steuerung
    { "Kein Wochenziel gesetzt", "No weekly goal set" }, { "Keine Farm-Session aktiv", "No farm session active" },
    { "GoldKompass Wochenziel", "GoldKompass weekly goal" }, { "Diese Woche netto: ", "This week net: " },
    { "Ziehen: verschieben (in den Optionen sperrbar)", "Drag to move (lockable in Options)" },
    { "Linksklick: Fenster", "Left-click: window" }, { "Rechtsklick: Optionen", "Right-click: options" },
    { "|r von |c", "|r of |c" }, { "|t von |c", "|t of |c" }, -- Betraege enden seit 0.24 mit dem Muenzsymbol (|t)
    -- Plus
    { "Route anklicken, dann Start im Hauptfenster", "Click a route, then Start in the main window" },
    { "Item-ID, Name oder Shift-Klick", "Item ID, name or shift-click" },
    { "Routen in ", "Routes in " }, { "Routes ist nicht geladen.", "Routes is not loaded." },
    { "   Routes muss als Addon aktiv sein.", "   Routes must be enabled as an addon." },
    { "   Hier gibt es noch keine Route. Lege sie in Routes an.", "   No route here yet. Create one in Routes." },
    { " Punkte)", " points)" }, { "noch nicht gefarmt", "not farmed yet" },
    { "Gewählt: ", "Selected: " }, { "(gilt beim nächsten Start)", "(applies at next start)" },
    { "Beste Routen (netto pro Stunde)", "Best routes (net per hour)" },
    { "   Noch keine Session mit Route beendet.", "   No session with a route finished yet." },
    { "Sparziele (Gold aller Charaktere)", "Savings goals (gold of all characters)" },
    { "Schnitt pro Tag (7 Tage)", "Average per day (7 days)" },
    { "   Noch kein Ziel. Name und Betrag oben eintragen.", "   No goal yet. Enter a name and amount above." },
    { "   Noch |c", "   Remaining |c" },
    { "kein Plus in den letzten 7 Tagen", "no gain in the last 7 days" },
    { "Material (Bestand inkl. Bank, Wert nach Preisquelle)", "Materials (stock incl. bank, value by price source)" },
    { "   Noch nichts gewählt. Item oben einfügen.", "   Nothing selected yet. Insert an item above." },
    { "Preisverlauf (", "Price history (" }, { " Items mit mindestens 3 Tagen)", " items with at least 3 days)" },
    { "   Noch zu wenig Daten. Der Verlauf füllt sich beim Spielen.", "   Not enough data yet. The history fills while you play." },
    { "   Preise werden aus Beute, Taschen und Tooltips erfasst.", "   Prices are collected from loot, bags and tooltips." },
    { "Preis unter dem Schnitt", "Price below average" }, { "Preis über dem Schnitt", "Price above average" },
    { "   Nichts auffällig.", "   Nothing unusual." },
    { "niedrig|r", "low|r" }, { "hoch|r", "high|r" }, { ", Schnitt ", ", average " }, { " Tage)", " days)" },
    { "Letzte Woche ", "Last week " }, { "Vorwoche erhalten: ", "Previous week received: " },
    { "keine Daten", "no data" },
    { "Beste Farm: keine Session von mindestens 5 Minuten", "Best farm: no session of at least 5 minutes" },
    { "Beste Farm: ", "Best farm: " },
    { "Teuerster Drop: keiner erfasst", "Most valuable drop: none recorded" }, { "Teuerster Drop: ", "Most valuable drop: " },
    -- Mehr
    { "Nur eigene Sessions ab 5 Minuten. Trend ab 4 Sessions je Gebiet.", "Own sessions of 5+ minutes only. Trend needs 4 sessions per area." },
    { "meldet ab ", "alerts at " }, { "% unter dem Schnitt", "% below average" },
    { "Gerade unter dem eigenen Schnitt (", "Currently below your own average (" },
    { "   Nichts auffällig. Der Verlauf füllt sich beim Spielen (mindestens 3 Tage je Item).", "   Nothing unusual. The history fills while you play (at least 3 days per item)." },
    { "Schnitt = frühere Tage aus deinem Preisverlauf. Das ist kein Kauftipp.", "Average = earlier days from your price history. This is not a buying tip." },
    { "Gebiete im Vergleich (netto pro Stunde)", "Areas compared (net per hour)" },
    { "   Noch keine Session ab 5 Minuten. Im Hauptfenster Farm: Start und Stopp.", "   No session of 5+ minutes yet. Use Start and Stop in the main window, Farm tab." },
    { "Trend offen", "Trend pending" }, { "schwächer|r", "weaker|r" }, { "stärker|r", "stronger|r" }, { "/h  stabil", "/h  stable" },
    { "Der Trend vergleicht deine letzten 2 Sessions mit den früheren dort.", "The trend compares your last 2 sessions there with the earlier ones." },
    { "Inventar (", "Inventory (" }, { " Charaktere, Taschen und besuchte Bank)", " characters, bags and visited bank)" },
    { "   Noch nichts erfasst. Taschen werden beim Spielen mitgezählt, die Bank beim Öffnen.", "   Nothing recorded yet. Bags are counted while you play, the bank when you open it." },
    { "   Kein Treffer.", "   No match." }, { " weitere. Oben suchen, um einzugrenzen.", " more. Search above to narrow down." },
    { "Name oder Item-ID", "Name or item ID" },
    { "Alles markieren, Strg+C kopiert, dann im Gilden-Chat oder Notizbuch einfügen.", "Select all, Ctrl+C copies, then paste into guild chat or a notebook." },
    -- Export (Textfeld)
    { "GoldKompass Wochenbericht ", "GoldKompass weekly report " },
    { "Erhalten: ", "Received: " }, { "Ausgegeben: ", "Spent: " }, { "Saldo: ", "Balance: " },
    { " mit Route ", " with route " }, { ", Schnitt ", ", average " },
    { "Beste Gebiete (netto pro Stunde):", "Best areas (net per hour):" },
    { "Gold aller Charaktere: ", "Gold of all characters: " }, { "Sparziel ", "Savings goal " },
    -- Toast, Tooltips
    { "Wert |c", "Value |c" }, { "(Verkaufspreis)", "(vendor price)" },
    { "GoldKompass Preise", "GoldKompass prices" },
    { "Weder Auctionator noch TSM gefunden.", "Neither Auctionator nor TSM found." },
    { "Kein Auktionshauspreis bekannt.", "No auction house price known." },
    { "Jetzt ", "Now " }, { "(Ziel ", "(target " },
    -- Chat
    { "Der Farm-Rechner ist in den Optionen ausgeschaltet (/gk optionen).", "The farm calculator is turned off in the options (/gk optionen)." },
    { "Es laeuft schon eine Session.", "A session is already running." },
    { "Farm-Session gestartet: ", "Farm session started: " }, { "Keine Session aktiv.", "No session active." },
    { " beendet: ", " finished: " }, { " Min = ", " min = " }, { " pro Stunde", " per hour" },
    { ", das sind ", ", that is " },
    { "Keine Session aktiv. Starte zuerst eine Farm-Session.", "No session active. Start a farm session first." },
    { "So: /gk kosten 50   (Betrag in Gold)", "Usage: /gk kosten 50   (amount in gold)" },
    { "Kosten gebucht: ", "Costs booked: " }, { "  (gesamt ", "  (total " },
    { "Wochenziel entfernt.", "Weekly goal removed." }, { "Wochenziel erreicht!", "Weekly goal reached!" },
    { "Wochenziel: ", "Weekly goal: " }, { "% vom Wochenziel geschafft.", "% of the weekly goal done." },
    { " werden ausgeblendet.", " will be hidden." }, { "Items unter ", "Items below " }, { "Filter aus.", "Filter off." },
    { "Reparatur als Kosten gebucht: ", "Repair booked as costs: " },
    { "Tagesbilanz: eingenommen ", "Daily summary: earned " }, { ", ausgegeben ", ", spent " }, { ", Saldo ", ", balance " },
    { "  Beste Farm: ", "  Best farm: " }, { " mit |c", " with |c" }, { " pro Stunde.", " per hour." },
    { "Wertvoller Fund: ", "Valuable find: " }, { " ist |c", " is |c" }, { "|r wert.", "|r worth." }, { "|t wert.", "|t worth." },
    { "Neue Post wartet im Briefkasten.", "New mail is waiting in the mailbox." },
    { "Neue Post im Briefkasten.", "New mail in the mailbox." },
    { "Deine Auktionen sind vermutlich abgelaufen oder verkauft. Schau im Auktionshaus und in der Post nach.",
      "Your auctions have probably expired or sold. Check the auction house and your mail." },
    { "Verkaufshelfer: nichts gefunden, das im Auktionshaus mehr bringt als der Verkaufspreis.", "Sell helper: nothing found that sells for more at the auction house than at the vendor." },
    { "Nicht zum Verkaufspreis verkaufen!", "Do not sell to the vendor!" },
    { " Im Auktionshaus bringt mehr:", " The auction house pays more:" },
    { " statt Verkaufspreis ", " instead of vendor price " },
    { "geladen. /gk Fenster, /gk optionen, /gk alarm, /gk start, /gk stop.", "loaded. /gk window, /gk options, /gk alarm, /gk start, /gk stop." },
    { "Route für diese Session: ", "Route for this session: " },
    { "Bitte einen Betrag in Gold eintragen.", "Please enter an amount in gold." },
    { "Mehr als sechs Ziele gehen nicht.", "No more than six goals." },
    { "Dieses Item kenne ich nicht. Item-ID oder Link einfügen.", "I don't know this item. Insert an item ID or link." },
    { "Mehr als zwölf Materialien gehen nicht.", "No more than twelve materials." },
    { "Designs: gold, blau, gruen, violett, rot (/gk design blau)", "Designs: gold, blue, green, purple, red (/gk design blue)" },
    { "Schnäppchen-Alarm ist an.", "Bargain alarm is on." }, { "Schnäppchen-Alarm ist aus.", "Bargain alarm is off." },
    { "Schnäppchen:|r", "Bargain:|r" }, { " jetzt |c", " now |c" }, { "  jetzt ", "  now " },
    { "Alarm entfernt.", "Alarm removed." },
    { "Nicht gefunden. /gk alarm zeigt die Liste.", "Not found. /gk alarm shows the list." },
    { "Keine Alarme. /gk alarm add [Item] 150  setzt einen (Preis in Gold).", "No alarms. /gk alarm add [item] 150 sets one (price in gold)." },
    { "So: /gk alarm add [Item-Link per Shift-Klick] 150   (Wunschpreis in Gold)", "Usage: /gk alarm add [item link via shift-click] 150   (target price in gold)" },
    { "Entfernen: /gk alarm del <Nummer>.  Ton testen: /gk alarm test", "Remove: /gk alarm del <number>.  Test sound: /gk alarm test" },
    { "  Ziel ", "  target " }, { "unbekannt", "unknown" }, { " oder weniger.", " or less." },
    { " farmt in ", " is farming in " },
    -- 0.23: Kriegsmeute-Bank, Auktionshaus-Verkaeufe, Befehle, Analyse, Menue
    { "Gold gesamt (Charaktere und Kriegsmeute-Bank)", "Total gold (characters and warband bank)" },
    { "   davon Kriegsmeute-Bank", "   of which warband bank" },
    { "Sparziele (Charaktere und Kriegsmeute-Bank)", "Savings goals (characters and warband bank)" },
    { "Gold aller Charaktere und Kriegsmeute-Bank: ", "Gold of all characters and warband bank: " },
    { "Auktionshaus-Verkäufe diese Woche", "Auction sales this week" },
    { "Auktionshaus-Verkauf", "Auction sales" }, { "Kriegsmeute-Bank:", "Warband bank:" }, { "Kriegsmeute-Bank", "Warband bank" },
    { "Looten / Sonstiges", "Loot / Other" },
    { "Unbekannter Befehl: ", "Unknown command: " }, { ". Alle Befehle: /gk befehle", ". All commands: /gk befehle" },
    { "Alle Befehle (/gk ...):", "All commands (/gk ...):" },
    { "So: /gk ziel 5000   (Wochenziel in Gold, /gk ziel aus entfernt es)", "Usage: /gk goal 5000   (weekly goal in gold, /gk goal off removes it)" },
    { "Gold pro Stunde|r", "Gold per hour|r" }, { "Gold heute|r", "Gold today|r" }, { "Wochenziel|r", "Weekly goal|r" },
    { "keine Farm aktiv", "no farm running" }, { "keins gesetzt (Reiter Woche)", "none set (Week tab)" }, { "misst ...", "measuring ..." },
    { "   eingenommen ", "   earned " }, { "   ausgegeben ", "   spent " },
    -- Analyse-Fenster
    { "GoldKompass · Analyse", "GoldKompass · Analysis" }, { "Gold-Verlauf", "Gold history" },
    { "Items pro Stunde", "Items per hour" },
    { "30 Tage", "30 days" }, { "90 Tage", "90 days" }, { "1 Jahr", "1 year" },
    { "Veränderung in ", "Change in " }, { " Tagen: ", " days: " }, { "(geschätzt)", "(estimated)" },
    { "Noch zu wenig Daten. Der Verlauf füllt sich ab heute jeden Tag.", "Not enough data yet. The history fills up every day from now on." },
    { "Grau: aus der Tagesbilanz geschätzt (vor dem ", "Grey: estimated from the daily balance (before " },
    { "). Ab jetzt speichert GoldKompass jeden Tag den echten Stand.", "). From now on GoldKompass saves the real value every day." },
    { "heutigen Tag", "today" },
    { "Gold aller Charaktere und der Kriegsmeute-Bank, jeweils der letzte Stand des Tages.", "Gold of all characters and the warband bank, last value of each day." },
    { "Noch keine Daten", "No data yet" }, { " Sessions, ", " sessions, " },
    { "Beende eine Farm-Session (ab dieser Version), dann erscheinen hier ihre Funde.", "Finish a farm session (from this version on) and its loot appears here." },
    { "Item-Wert zusammen|r", "Item value total|r" },
    -- Blizzard-Optionsmenue und Addon-Fach
    { "Gold gesamt:", "Total gold:" }, { "Gold gesamt", "Total gold" }, { "Charaktere:", "Characters:" },
    { "Fenster öffnen", "Open window" }, { "Optionen öffnen", "Open options" }, { "Plus-Fenster", "Plus window" },
    { "Willkommensseite", "Welcome page" }, { "Befehle (/gk ...)", "Commands (/gk ...)" },
    { "Zeichnet auf, woher dein Gold kommt und wohin es geht, rechnet Gold pro Stunde aus und hilft beim Farmen und Verkaufen.",
      "Records where your gold comes from and where it goes, calculates gold per hour and helps with farming and selling." },
    { "Die Einstellungen findest du im GoldKompass-Fenster unter Optionen.", "You find the settings in the GoldKompass window under Options." },
    -- 0.25: Willkommensseite (jede Zeile als Ganzes)
    { "Was GoldKompass macht", "What GoldKompass does" },
    { "Es zeichnet auf, woher dein Gold kommt und wohin es geht, und rechnet aus, wie viel du pro Stunde verdienst.",
      "It records where your gold comes from and where it goes, and calculates how much you earn per hour." },
    { "Die Reiter im Fenster", "The tabs in the window" },
    { "|cffffffffHeute|r  Einnahmen, Ausgaben, Saldo und die wichtigsten Quellen", "|cffffffffToday|r  Income, expenses, balance and the main sources" },
    { "|cffffffffWoche|r  Wochenziel setzen und den Verlauf der letzten 7 Tage sehen", "|cffffffffWeek|r  Set a weekly goal and see the last 7 days" },
    { "|cffffffffFarm|r  Sessions starten und stoppen, Gold pro Stunde, beste Gebiete", "|cffffffffFarm|r  Start and stop sessions, gold per hour, best areas" },
    { "|cffffffffBeute|r  Wert deiner Taschen, wertvollste Stapel, teuerste Funde", "|cffffffffLoot|r  Value of your bags, most valuable stacks, best finds" },
    { "|cffffffffChars|r  Gold und Wochenertrag aller deiner Charaktere", "|cffffffffChars|r  Gold and weekly income of all your characters" },
    { "|cffffffffGruppe|r  Farm mit Mitspielern vergleichen (alle brauchen GoldKompass)", "|cffffffffGroup|r  Compare farming with others (everyone needs GoldKompass)" },
    { "Dazu gibt es|r", "Also included|r" },
    { "Gold-Verlauf, Items pro Stunde, Preisalarm, Schnaeppchen-Alarm, Verkaufshelfer,", "Gold history, items per hour, price alarm, bargain alarm, sell helper," },
    { "Gilden-Wochenziel, Wochenbericht und Routes-Anbindung. Die Kriegsmeute-Bank zaehlt mit.", "guild weekly goal, weekly report and Routes support. The warband bank is included." },
    { "Preise kommen von Auctionator oder TSM, ohne beide gilt der Haendlerpreis.", "Prices come from Auctionator or TSM, without them the vendor price is used." },
    { "Wichtige Befehle|r", "Important commands|r" },
    { "/gk  Fenster auf und zu      /gk optionen  Einstellungen", "/gk  open and close the window      /gk options  settings" },
    { "/gk start  und  /gk stop  Farm-Session      /gk verlauf  Gold-Verlauf", "/gk start  and  /gk stop  farm session      /gk history  gold history" },
    { "/gk befehle  alle Befehle      /gk hilfe  diese Seite noch einmal", "/gk commands  all commands      /gk help  this page again" },
    { "Auch im Addon-Menue an der Minimap und unter Esc > Optionen > AddOns.", "Also in the addon menu at the minimap and under Esc > Options > AddOns." },
    -- Verkaufshelfer
    { "Ins Auktionshaus|r", "To the auction house|r" }, { "Zum Händler|r", "To the vendor|r" }, { "Gesperrt|r", "Blocked|r" },
    { "Klick hebt die Sperre auf", "click to unblock" },
    { "Auktionshaus: ", "Auction house: " }, { "   Händler: ", "   Vendor: " }, { "   Grau: ", "   Grey: " }, { "   Frei: ", "   Free: " },
    { "Taschen fast voll: nur noch ", "Bags almost full: only " }, { " freie Plätze.", " free slots." },
    { "Verkauft nur graue Items (", "Sells grey items only (" }, { "), gesperrte bleiben.", "), blocked ones stay." },
    { " graue Stapel verkauft, zusammen ", " grey stacks sold, total " }, { "Mindestgewinn: ", "Minimum profit: " },
    -- Eigene Route
    { "Karte: ", "Map: " }, { "\nPunkte: ", "\nPoints: " }, { "Länge: ", "Length: " }, { "% der Karte", "% of the map" },
    { "\nAufnahme: aus", "\nRecording: off" }, { "\nAufnahme: ", "\nRecording: " }, { "läuft, einfach laufen", "running, just walk" },
    { "Deine Routen in ", "Your routes in " }, { ": noch keine", ": none yet" },
    { "Route gespeichert: ", "Route saved: " }, { " Punkte in ", " points in " },
    { "). Sie ist für den nächsten Farm-Start gewählt.", "). It is selected for the next farm start." },
    { "Route gelöscht: ", "Route deleted: " }, { "Eigene Route für diese Session: ", "Own route for this session: " },
    { "Maximal ", "Reached the maximum of " }, { " Punkte erreicht.", " points." },
    -- Farmzeit, Pause, Sitzung
    { "Farm stoppt automatisch nach ", "Farm stops automatically after " }, { "Farm-Zeit von ", "Farm time of " },
    { " Minuten erreicht.|r Die Session wurde beendet.", " minutes reached.|r The session was ended." }, { " Minuten.", " minutes." },
    { "Session wiederhergestellt: ", "Session restored: " }, { " (pausiert)", " (paused)" },
    -- Tagesuebersicht, BoE, Gilde
    { "Gestern: eingenommen ", "Yesterday: earned " }, { "BoE-Ton nur ab ", "BoE sound only from " }, { " Wert.", " value." },
    { "Aeltere Sessions (ohne Charakter)", "Older sessions (no character)" }, { " Sessions)", " sessions)" },
    { "Kein Gildenziel gesetzt (/gk gilde ziel 50000).", "No guild goal set (/gk guild goal 50000)." },
    { "Diese Woche: ", "This week: " }, { "Gildenziel: ", "Guild goal: " }, { " (wird an die Gilde geschickt).", " (sent to the guild)." },
    { " hat das Gildenziel auf ", " set the guild goal to " }, { " (du)", " (you)" },
    -- Sicherung, Speicher, Selbsttest
    { "Exportieren: Text wird markiert, mit Strg+C kopieren und z. B. in einer Textdatei aufheben.",
      "Export: the text gets selected, copy it with Ctrl+C and keep it, e.g. in a text file." },
    { "Importieren: Sicherungstext mit Strg+V unten einfügen und auf Importieren klicken.",
      "Import: paste a backup text below with Ctrl+V and click Import." },
    { "Alle Daten: ", "All data: " }, { "Einstellungen: ", "Settings: " }, { " KB. Jetzt Strg+C drücken.", " KB. Now press Ctrl+C." },
    { "Der Text ist beschädigt: ", "The text is damaged: " },
    { "Gespeicherte Daten: ", "Saved data: " }, { ", Arbeitsspeicher: ", ", memory: " },
    { "   Aufräumen: /gk speicher aufraeumen", "   Clean up: /gk memory clean" },
    { "Aufgeräumt: ", "Cleaned up: " }, { " KB vorher, ", " KB before, " }, { " KB jetzt.", " KB now." },
    { "\nRoh ", "\nRaw " }, -- Farm-Fenster: zweite Zeile "Roh ... Items ..."
    { " ist jetzt ", " is now " }, { "Wertwarner ab ", "Value warning from " },
    { "Spielfunktion ", "Game function " }, { "Funktion ", "Function " }, { "Preisquelle: ", "Price source: " },
    { "keine (es gilt der Händlerpreis)", "none (the vendor price is used)" }, { "Datenversion ", "Data version " },
    { "Interface-Nummer: .toc ", "Interface number: .toc " }, { ", Spiel ", ", game " }, { "|cff999999... und ", "|cff999999... and " },
    { "Selbsttest fertig: ", "Self-test finished: " }, { " in Ordnung, ", " OK, " }, { " Hinweise, ", " notes, " }, { " Fehler.", " errors." },
    { "Alles markiert: Strg+C kopiert, dann in Excel oder Editor einfuegen (Trennzeichen ;).", "All selected: Ctrl+C copies it, then paste into Excel or an editor (separator ;)." },
}

-- Muster (zuerst angewendet) ---------------------------------------------------------------------------------
local P = {
    { "^(   .-)Haendler$", "%1Vendor" }, -- Quelle "Haendler" im Reiter Heute (nur ganze Zeile, nicht "Haendlerpreis")
    { "^Woche: (%d+g) von (%d+g)", "Week: %1 of %2" },
    { "^Woche: (.-) von (.-) · ", "Week: %1 of %2 · " },
    { "^Top (%d+) von (%d+) erfassten Drops, nach Wert", "Top %1 of %2 recorded drops, by value" },
    { "^noch (%d+:%d+)$", "%1 left" }, { "^stoppt nach (%d+) Min$", "stops after %1 min" },
    { "^etwa (%d+) Tage %(bis ", "about %1 days (until " },
    { "(%d%d%.%d%d%.) bis (%d%d%.%d%d%.)", "%1 to %2" },
    { "^Alarm gesetzt: (.-) bei ", "Alarm set: %1 at " },
    { "^Ziel geaendert: (.-) auf ", "Target changed: %1 to " },
    { "^Nach Kosten %(", "After costs (" },
    { "^Schnäppchen ab (%d+)%% unter dem Schnitt%.", "Bargains from %1%% below average." },
    { "^Du hattest (%d+) Auktionen laufen %(zuletzt geprueft vor (%d+) Std%)%. Schau im Auktionshaus und Briefkasten nach%.",
      "You had %1 auctions running (last checked %2 h ago). Check the auction house and mailbox." },
    { "^(.-) farmt in (.-)%. Ich steige automatisch ein%.", "%1 is farming in %2. Joining automatically." },
    { "^(.-) hat eine Farm%-Session gestartet %((.-)%)%. Mitmachen: /gk start", "%1 started a farm session (%2). Join with /gk start" },
    { "^(.-)%s+heute$", "%1 today" },
}

-- Kleine Korrekturen auch im Deutschen (z. B. Ton gilt nur noch bei BoE)
local DE_R = { { "Ton bei grüner Beute", "Ton bei BoE-Beute" } }

table.sort(R, function(a, b) return #a[1] > #b[1] end)

-- Zustand ------------------------------------------------------------------------------------------------------
local function Lang()
    local o = GK.DB and GK.DB() and GK.DB().opt
    local l = o and o.lang or "auto"
    if l == "auto" then l = (GetLocale() == "deDE") and "de" or "en" end
    return l
end

local function Esc(s) return (s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")) end
local function EscR(s) return (s:gsub("%%", "%%%%")) end

-- Erkennt, ob ein Text nach der Uebersetzung noch deutsch aussieht (fuer /gk sprachcheck)
local GERMAN = { " der ", " die ", " das ", " und ", " nicht", " noch ", " mit ", " ist ", " von ", " für ", " fuer ",
    "keine", " pro ", " heute", " seit ", " eine", " bitte", " oder " }
local function LooksGerman(s)
    local plain = (" " .. s .. " "):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h.-|h", ""):gsub("|T.-|t", "")
    if plain:find("[äöüÄÖÜß]") then return true end
    plain = strlower(plain)
    for _, w in ipairs(GERMAN) do if plain:find(w, 1, true) then return true end end
    return false
end

local cache, cacheN, cacheLang = {}, 0, nil
local function T(s)
    local lang = Lang()
    if cacheLang ~= lang then cache, cacheN, cacheLang = {}, 0, lang end
    local hit = cache[s]
    if hit then return hit end
    local out = s
    if lang == "en" then
        out = X[s] or s
        if out == s then
            for _, p in ipairs(P) do out = out:gsub(p[1], p[2]) end
            for _, r in ipairs(R) do
                if out:find(r[1], 1, true) then out = out:gsub(Esc(r[1]), EscR(r[2])) end
            end
        end
        -- Befehle im Text auf ihren englischen Namen umschreiben (/gk verlauf -> /gk history)
        if GK.CommandEN and out:find("/gk ", 1, true) then out = GK.CommandEN(out) end
    else
        for _, r in ipairs(DE_R) do
            if out:find(r[1], 1, true) then out = out:gsub(Esc(r[1]), EscR(r[2])) end
        end
    end
    if lang == "en" and LooksGerman(out) then
        GK.missingText = GK.missingText or {}
        GK.missingText[s] = true
    end
    if cacheN > 3000 then cache, cacheN = {}, 0 end
    cache[s] = out; cacheN = cacheN + 1
    return out
end
GK.T = T

-- Fenster durchgehen -------------------------------------------------------------------------------------------
local ROOTS = { "GoldKompassFrame", "GoldKompassOptionsFrame", "GoldKompassPlusFrame", "GoldKompassMehrFrame",
    "GoldKompassFarmHud", "GoldKompassWeekBar", "GoldKompassFarmControl", "GoldKompassRareToast", "GoldKompassAlarmPopup",
    "GoldKompassAnalyseFrame", "GoldKompassSettingsPanel", "GoldKompassNav", "GoldKompassTransfer",
    "GoldKompassIntroFrame", "GoldKompassSellFrame", "GoldKompassRouteEditor", "GoldKompassBeuteHud", "GoldKompassDauer",
    "GoldKompassExport" }

-- Sofort-Uebersetzung: ein Haken auf SetText jedes Textfelds und Knopfs. Wird ein deutscher Text gesetzt, ersetzt
-- ihn der Haken noch im selben Moment durch den englischen, bevor er angezeigt wird. So springt nichts hin und her,
-- auch wenn ein Fenster seine Zeilen jede Sekunde neu befuellt (z. B. der Reiter Heute bei laufender Farm).
local busy = {}
local function HookText(obj)
    if obj.gkTrHook or not obj.SetText then return end
    obj.gkTrHook = true
    hooksecurefunc(obj, "SetText", function(self, text)
        if busy[self] or type(text) ~= "string" or text == "" or Lang() ~= "en" then return end
        local n = T(text)
        if n ~= text then
            busy[self] = true
            self:SetText(n)
            busy[self] = nil
        end
    end)
end

local function Fix(fs)
    HookText(fs)
    local t = fs:GetText()
    if not t or t == "" or fs.gkSeen == t then return end
    local n = T(t)
    if n ~= t then fs:SetText(n); fs.gkSeen = n else fs.gkSeen = t end
end

local function Walk(f, depth)
    if depth > 8 then return end
    for _, r in ipairs({ f:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "FontString" then Fix(r) end
    end
    for _, c in ipairs({ f:GetChildren() }) do
        local kind = c.GetObjectType and c:GetObjectType()
        if not c.SetupMenu and kind ~= "EditBox" then
            -- Knoepfe setzen ihren Text am eigenen SetText vorbei: auch dort einhaken
            if kind == "Button" or kind == "CheckButton" then HookText(c) end
            Walk(c, depth + 1)
        end
    end
end

local function ScanAll()
    if Lang() ~= "en" then return end
    for _, name in ipairs(ROOTS) do
        local f = _G[name]
        if f then
            -- beim Oeffnen sofort uebersetzen (laeuft nach dem eigenen OnShow, das die Zeilen fuellt)
            if not f.gkTrRoot then
                f.gkTrRoot = true
                f:HookScript("OnShow", function(self) pcall(Walk, self, 0) end)
            end
            if f:IsShown() then pcall(Walk, f, 0) end
        end
    end
    -- Textfeld des Wochenberichts
    local m = GK.mehr
    if m and m.exportBox and Lang() == "en" then
        local t = m.exportBox:GetText()
        if t and t ~= "" and t:find("Wochenbericht", 1, true) then
            local n = T(t)
            if n ~= t then m.exportBox:SetText(n) end
        end
    end
end

for _, name in ipairs({ "Refresh", "RefreshPlus", "RefreshMehr", "RefreshHud", "UpdateBar", "UpdateControl", "RefreshOptions",
    "Build", "BuildOptions", "BuildPlus", "BuildMehr", "BuildHud" }) do
    if type(GK[name]) == "function" then pcall(hooksecurefunc, GK, name, ScanAll) end
end

-- Tooltips ---------------------------------------------------------------------------------------------------------
local function Tip(tt)
    if tt ~= GameTooltip or not tt.NumLines then return end
    local on = false
    for i = 1, tt:NumLines() do
        for _, side in ipairs({ "Left", "Right" }) do
            local fs = _G["GameTooltipText" .. side .. i]
            local t = fs and fs:GetText()
            if t and t ~= "" then
                if t:find("GoldKompass", 1, true) then on = true end
                if on then
                    local n = T(t)
                    if n ~= t then fs:SetText(n) end
                end
            end
        end
    end
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, Tip)
end
pcall(function() GameTooltip:HookScript("OnShow", Tip) end)

-- Chat -------------------------------------------------------------------------------------------------------------------
-- Nur die Chat-Ausgaben von GoldKompass laufen hier durch (jede Datei leitet ihr print auf GK.Out um).
-- Das globale print bleibt unberuehrt, damit andere Addons und die Blizzard-Oberflaeche nicht betroffen sind.
function GK.Out(first, ...)
    if type(first) == "string" and Lang() == "en" then
        local _, j = first:find("|r: ", 1, true)
        if j and first:sub(1, j):find("GoldKompass", 1, true) then
            first = first:sub(1, j) .. T(first:sub(j + 1))
        elseif first:find(" statt Verkaufspreis ", 1, true) then
            first = T(first)
        end
    end
    return print(first, ...)
end

-- Befehle: Sprache und englische Namen ---------------------------------------------------------------------------------
local ALIAS = {
    window = "", options = "optionen", goal = "ziel", goals = "ziele", savings = "ziele", areas = "gebiete",
    inventory = "inventar", report = "bericht", bargain = "dip", bargains = "dip", group = "gruppe", bags = "taschen",
    finds = "funde", sell = "verkauf", recap = "rueckblick", routes = "route", materials = "mats", prices = "preise",
    more = "mehr", cost = "kosten", costs = "kosten", bar = "leiste", language = "sprache", stop = "stop", start = "start",
}

-- Englischer Name je Befehl: wird im englischen Modus angezeigt (Befehlsliste, Hilfetexte, Chat) und funktioniert immer
local EN_NAME = {
    verlauf = "history", wert = "value", sicherung = "backup", speicher = "memory", selbsttest = "selftest",
    routenbau = "newroute", routendebug = "routedebug", groesse = "scale", ["größe"] = "scale", sperren = "lock",
    gilde = "guild", befehle = "commands", gruppe = "group", taschen = "bags", funde = "finds", beute = "loot",
    hilfe = "help", mehr = "more", gebiete = "areas", inventar = "inventory", bericht = "report", dip = "bargain",
    schnaeppchen = "bargain", einstellungen = "settings", optionen = "options", route = "routes", routen = "routes",
    ziele = "goals", sparen = "goals", mats = "materials", material = "materials", preise = "prices",
    rueckblick = "recap", ["rückblick"] = "recap", sprache = "language", sprachcheck = "langcheck", leiste = "bar",
    dauer = "duration", verkauf = "sell", verkaufshelfer = "sell", kosten = "cost", ziel = "goal", tag = "day",
    charstd = "charhour", stopp = "stop", fenster = "window", rekorde = "records",
}
for de, en in pairs(EN_NAME) do
    if de ~= "fenster" and ALIAS[en] == nil then ALIAS[en] = de end
end

-- Englische Befehlsnamen: der zentrale /gk-Befehl (GoldKompass.lua) schlaegt hier nach
for k, v in pairs(ALIAS) do GK.CommandAlias[k] = v end

-- Englische Unterbefehle (z. B. /gk guild on, /gk loot clear, /gk design blue)
GK.SubAlias = {
    gilde = { goal = "ziel", on = "an", off = "aus" },
    dip = { on = "an", off = "aus" },
    beute = { clear = "leeren" },
    design = { blue = "blau", green = "gruen", purple = "violett", violet = "violett", red = "rot" },
    alarm = { new = "neu", remove = "del", delete = "del" },
}
local SUB_EN = {
    guild = { ziel = "goal", an = "on", aus = "off" }, bargain = { an = "on", aus = "off" }, loot = { leeren = "clear" },
    goal = { aus = "off" }, memory = { aufraeumen = "clean", ["aufräumen"] = "clean" },
    design = { blau = "blue", gruen = "green", violett = "purple", rot = "red" },
}

-- Name eines Befehls in der gewaehlten Sprache (fuer Befehlsliste und Einstellungsseite)
function GK.CommandName(name)
    if Lang() ~= "en" then return name end
    return EN_NAME[name] or name
end

-- Im Text: "/gk gilde ziel 5" -> "/gk guild goal 5" (nur deutsche Namen werden ersetzt)
function GK.CommandEN(s)
    return (s:gsub("/gk ([^%s|%.,:;%(%)]+)( ?)([^%s|%.,:;%(%)]*)", function(cmd, sp, sub)
        local en = EN_NAME[strlower(cmd)] or strlower(cmd)
        local se = SUB_EN[en] and SUB_EN[en][strlower(sub)]
        if en == strlower(cmd) and not se then return nil end
        return "/gk " .. en .. sp .. (se or sub)
    end))
end

-- Sprache waehlen: "de", "en" oder "auto" (folgt der Spielsprache). Wirkt nach dem Neuladen der Oberflaeche,
-- weil bereits angezeigte deutsche Texte sonst nicht zurueckgeholt werden koennen.
StaticPopupDialogs["GOLDKOMPASS_LANG_RELOAD"] = {
    text = "", button1 = YES, button2 = NO,
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
function GK.GetLanguageSetting()
    local o = GK.DB and GK.DB() and GK.DB().opt
    return o and o.lang or "auto"
end
GK.Lang = Lang
function GK.SetLanguage(lang)
    if lang ~= "de" and lang ~= "en" and lang ~= "auto" then return end
    local db = GK.DB and GK.DB()
    if not db then return end
    db.opt.lang = lang
    local willBe = lang == "auto" and ((GetLocale() == "deDE") and "de" or "en") or lang
    local name = lang == "auto" and (willBe == "en" and "Automatic (English)" or "Automatisch (Deutsch)") or (lang == "en" and "English" or "Deutsch")
    print("|cffffd100GoldKompass|r: " .. (willBe == "en" and "Language: " or "Sprache: ") .. name .. ".")
    StaticPopupDialogs["GOLDKOMPASS_LANG_RELOAD"].text = willBe == "en"
        and "GoldKompass: Reload the interface now to switch the language?"
        or "GoldKompass: Oberfläche jetzt neu laden, damit die Sprache wechselt?"
    StaticPopup_Show("GOLDKOMPASS_LANG_RELOAD")
    if GK.RefreshLanguageUI then GK.RefreshLanguageUI() end
end

GK.RegisterCommand("sprache", function(arg)
    arg = strlower(arg or "")
    if arg == "deutsch" or arg == "german" then arg = "de" elseif arg == "englisch" or arg == "english" then arg = "en" end
    if arg == "de" or arg == "en" or arg == "auto" then
        GK.SetLanguage(arg)
    else
        print("|cffffd100GoldKompass|r: /gk sprache de | en | auto")
    end
end, "Sprachwahl: Deutsch, English oder automatisch")

-- Tastenbelegung passend zur gewaehlten Sprache beschriften
local bev = CreateFrame("Frame")
bev:RegisterEvent("PLAYER_LOGIN")
bev:SetScript("OnEvent", function()
    local en = Lang() == "en"
    BINDING_NAME_GOLDKOMPASS_TOGGLE = en and "Open/close window" or "Fenster öffnen/schließen"
    BINDING_NAME_GOLDKOMPASS_FARM = en and "Start/stop farm session" or "Farm-Session starten/stoppen"
    BINDING_NAME_GOLDKOMPASS_PAUSE = en and "Pause/resume farm session" or "Farm-Session pausieren/fortsetzen"
end)

-- Fehlende Uebersetzungen: im englischen Modus sammelt T() deutsche Texte, die unuebersetzt blieben.
-- /gk sprachcheck listet sie, damit sie in die Tabellen oben eingetragen werden koennen.
GK.RegisterCommand("sprachcheck", function()
    local list = {}
    for s in pairs(GK.missingText or {}) do list[#list + 1] = s end
    table.sort(list)
    if Lang() ~= "en" then
        print("|cffffd100GoldKompass|r: sprachcheck funktioniert im englischen Modus (/gk sprache en, dann /reload).")
    elseif #list == 0 then
        print("|cffffd100GoldKompass|r: No untranslated texts seen in this session.")
    else
        print("|cffffd100GoldKompass|r: " .. #list .. " untranslated texts seen in this session:")
        for i = 1, math.min(40, #list) do print("   " .. list[i]:gsub("|", "||")) end
    end
end, "Zeigt Texte, denen die englische Übersetzung fehlt")

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    -- Auf Deutsch gibt es nichts zu uebersetzen: dann kein Durchsuchen der Fenster
    if Lang() ~= "en" then return end
    C_Timer.After(1, ScanAll)
    C_Timer.NewTicker(0.5, ScanAll)
end)

-- Das Muster fuer "... heute" (Material-Reiter) darf "Saldo heute" nicht treffen: nur nach Farbende oder +-0
P[#P] = { "^(.*|r)%s+heute$", "%1 today" }
P[#P + 1] = { "^(.*±0)%s+heute$", "%1 today" }
