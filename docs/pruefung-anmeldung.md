# Prüfliste Anmeldebildschirm (Test-VMs)

Funktionale Prüfung des Pakets `querencia-anmeldung` **nur auf Test-VMs**,
nie in der Entwicklungsumgebung mit dem laufenden Anmeldebildschirm. Zwei Wege:

- **Weg G (GDM):** Ubuntu Desktop 26.04 mit GNOME und GDM, Querencia
  Desktop schon installiert (Koexistenz, z. B. VM 116).
- **Weg S (Server):** frisches Ubuntu 26.04 ohne Display-Manager, Paketsatz
  wie bei der Pflichtprobe (z. B. VM 115, Snapshot `frisch`).

Jeder Punkt: PASS/FAIL mit Bildschirmfoto bzw. Befehlsausgabe; die Nummer
ist der Dateiname des Belegs. Passwörter nicht in Belege schreiben.

## 0 Vorbereitung (beide Wege)

| Nr. | Schritt | Erwartung |
|---|---|---|
| 0.1 | Paket und `SHA256SUMS` auf die VM kopieren, `sha256sum -c SHA256SUMS` | `OK` |
| 0.2 | `dpkg-deb -I querencia-anmeldung_*.deb` | Depends greetd, labwc (≥ 0.9.8), dbus-daemon, glycin-loaders, debconf |
| 0.3 | Ausgangslage festhalten: `cat /etc/X11/default-display-manager; readlink /etc/systemd/system/display-manager.service; systemctl is-active display-manager` | G: `/usr/sbin/gdm3`, `…/gdm3.service`, `active`; S: nichts, nichts, `inactive` |
| 0.4 | `ls /usr/share/wayland-sessions /usr/share/xsessions` | G: `ubuntu.desktop` (GNOME) und `querencia.desktop`; S: `querencia.desktop` (und ggf. `labwc.desktop`) |

## G Ubuntu Desktop mit GDM (Koexistenz)

| Nr. | Schritt | Erwartung |
|---|---|---|
| G1 | `sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./querencia-anmeldung_*.deb` | Ausgabe „gdm3 bleibt Standard-Anmeldedienst. Wechsel: sudo dpkg-reconfigure querencia-anmeldung“; greetd wird mitinstalliert |
| G2 | wie 0.3 | **unverändert** `/usr/sbin/gdm3`, `…/gdm3.service`; GDM läuft weiter, die angemeldete Sitzung bleibt |
| G3 | `sudo debconf-show querencia-anmeldung` | `shared/default-x-display-manager: gdm3` |
| G4 | Neustart | GDM erscheint wie vorher, Anmeldung an Ubuntu und an Querencia Desktop wie vorher |
| G5 | `sudo dpkg-reconfigure querencia-anmeldung` | Frage „Standard-Anmeldedienst“ mit `gdm3` und `querencia-anmeldung`, vorbelegt `gdm3`; `querencia-anmeldung` wählen; Ausgabe „Standard-Anmeldedienst ist jetzt querencia-anmeldung (wirkt nach dem nächsten Neustart)“ |
| G6 | wie 0.3 | `/usr/sbin/querencia-anmeldung`, `/usr/lib/systemd/system/querencia-anmeldung.service`; GDM läuft noch (nicht angehalten) |
| G7 | Neustart | **Querencia-Anmeldebildschirm** auf Konsole 7: Grußtext „Querencia Desktop“ (mit Versionsdatei „Querencia Desktop Alpha 2.1“, Ü5), Hintergrund Querencia Blau, Thema Querencia-Klassisch, Beschriftung und Uhr in der Systemsprache (Ü1–Ü4); nirgends „Classic2“; Sitzung **„Querencia Desktop“ vorgewählt** (KB3) |
| G8 | Sitzungsliste öffnen | **nur** „Querencia Desktop“ (kein „Ubuntu“, kein „labwc“) |
| G8a | `cat /run/querencia-anmeldung/auswahl.txt; ls /run/querencia-anmeldung/wayland-sessions` | `angeboten …/querencia.desktop querencia`, `ausgeblendet …/ubuntu.desktop nicht-freigegeben`, ggf. `…/labwc.desktop labwc-nie`; im Ordner nur `querencia.desktop` mit `Exec=/usr/libexec/querencia-anmeldung/sitzung-starten /usr/share/wayland-sessions/querencia.desktop` |
| G8b | Freigabe: `sudo sed -i 's/^freigeben =.*/freigeben = ubuntu labwc/' /etc/querencia/greetd/sitzungen.conf`, Neustart | Liste „Querencia Desktop“ **und** „Ubuntu“, weiter kein „labwc“; `auswahl.txt`: `ubuntu.desktop freigegeben`, `labwc.desktop labwc-nie` |
| G9 | Benutzerliste, Passwortfeld: Zeichen `y`, `z`, `ö` tippen und sichtbar machen (Auge) | Belegung wie `/etc/default/keyboard` (bei `de`: y/z richtig) |
| G10 | Rechtsklick auf den Hintergrund, `Alt+Tab`, `Alt+F2`, `Strg+Alt+T`, `Super` | nichts geschieht (kein Menü, kein Terminal) |
| G11 | Anmelden mit Sitzung „Ubuntu“ (nach G8b) | GNOME startet vollständig (Dock, Oben-Leiste); im Terminal `echo $XDG_SESSION_TYPE $XDG_CURRENT_DESKTOP $XDG_SESSION_DESKTOP $DESKTOP_SESSION` → `wayland ubuntu:GNOME ubuntu ubuntu`; `echo $XDG_CONFIG_DIRS` enthält `/etc/xdg/xdg-ubuntu`; `gsettings get org.gnome.desktop.interface gtk-theme` und `icon-theme` → Yaru-Werte wie unter GDM; `loginctl show-session $XDG_SESSION_ID -p Type -p Class` → `Type=wayland`, `Class=user` |
| G11a | Bildschirmsperre in GNOME (`Super+L`, Menü oben rechts) | **bekannte Grenze:** ohne laufenden GDM legt gnome-shell keine Bildschirmsperre an (Meldung „Die Sperrung des Bildschirms erfordert den GNOME Display-Manager“); deshalb ist GNOME ohne Freigabe nicht in der Liste (G8). Ergebnis festhalten |
| G12 | in GNOME abmelden | Querencia-Anmeldebildschirm erscheint wieder (kein schwarzer Bildschirm), „Ubuntu“ und der Benutzer sind vorbelegt |
| G12a | Freigabe zurücknehmen: `sudo sed -i 's/^freigeben =.*/freigeben =/' /etc/querencia/greetd/sitzungen.conf`, Neustart | nur „Querencia Desktop“, vorgewählt, obwohl zuletzt „Ubuntu“ gewählt war (`/var/lib/querencia-anmeldung/state.toml`) |
| G13 | Anmelden mit „Querencia Desktop“ | Panel, Desktop, Hintergrund wie gewohnt; `echo $XDG_CURRENT_DESKTOP $XDG_SESSION_DESKTOP $DESKTOP_SESSION` → `X-Querencia querencia querencia` (wie unter GDM) |
| G14 | in Querencia abmelden und **sofort** wieder anmelden (unter 10 s) | Sitzung kommt vollständig (Gegenprobe zum schwarzen Bildschirm nach schneller Neuanmeldung, unter greetd) |
| G15 | Protokolle: `sudo tail -50 /var/log/querencia-anmeldung/log; journalctl -b -u querencia-anmeldung --no-pager \| tail -30` | keine `ERROR`-Zeilen außer bekannten Hinweisen; Hintergrund geladen (keine glycin-Fehler) |
| G16 | Knopf „Neu starten“ im Anmeldebildschirm | System startet neu, Querencia-Anmeldebildschirm erscheint wieder |
| G17 | Zurück zu GDM: `sudo dpkg-reconfigure querencia-anmeldung`, `gdm3` wählen (alternativ `sudo QUERENCIA_ANMELDUNG=nein dpkg-reconfigure querencia-anmeldung`) | wie 0.3: `/usr/sbin/gdm3`, `…/gdm3.service`; die laufende Anmeldung bleibt |
| G18 | Neustart | GDM erscheint; Anmeldung an Ubuntu und an Querencia Desktop |
| G19 | wieder umschalten: `sudo QUERENCIA_ANMELDUNG=ja dpkg-reconfigure querencia-anmeldung` | Ausgabe „… ist jetzt querencia-anmeldung“ |
| G20 | `sudo apt purge -y querencia-anmeldung` | Ausgabe „Standard-Anmeldedienst ist wieder gdm3“; wie 0.3: `/usr/sbin/gdm3`, `…/gdm3.service`; `/etc/querencia/greetd`, `/var/lib/querencia-anmeldung`, `/var/log/querencia-anmeldung` weg; `sudo debconf-show querencia-anmeldung` leer |
| G21 | Neustart | GDM erscheint; greetd ist noch installiert, aber nicht display-manager (`readlink …display-manager.service` → gdm3) |

## S Server ohne Display-Manager

| Nr. | Schritt | Erwartung |
|---|---|---|
| S1 | Paketsatz und `querencia-anmeldung` zusammen installieren (`apt-get install ./*.deb`) | Ausgabe „Standard-Anmeldedienst ist jetzt querencia-anmeldung“ |
| S2 | wie 0.3 | `/usr/sbin/querencia-anmeldung`, `…/querencia-anmeldung.service` |
| S3 | Neustart | Querencia-Anmeldebildschirm auf Konsole 7 wie G7; nur Sitzung „Querencia Desktop“, vorgewählt (auch wenn `labwc.desktop` installiert ist) |
| S4 | `Strg+Alt+F1` | Textanmeldung auf tty1 weiter vorhanden; `Strg+Alt+F7` zurück zum Anmeldebildschirm |
| S5 | Anmelden mit „Querencia Desktop“, abmelden, sofort wieder anmelden | wie G13, G14 |
| S6 | `sudo apt remove -y querencia-anmeldung` | Ausgabe „Kein grafischer Anmeldedienst mehr eingetragen …“; `readlink …display-manager.service` leer |
| S7 | Neustart | Textanmeldung auf tty1 (kein schwarzer Bildschirm, kein greetd mit `agreety`) |
| S8 | `sudo apt purge -y querencia-anmeldung` | Ordner wie G20 weg |

## Ü Sprache und Info-Zeile (ab 0.1.2, Ü7–Ü9 ab 0.1.3, Ü8 neu ab 0.1.4, Ü10 ab 0.1.5, beide Wege)

Systemsprache Deutsch: `/etc/default/locale` mit `LANG=de_DE.UTF-8`, die
Locale erzeugt (`locale -a` zeigt `de_DE.utf8`). Unter Ubuntu 26.04 ist
`/etc/default/locale` ein Link auf `/etc/locale.conf`: Sprache nur mit
`localectl set-locale` ändern, nicht die Datei ersetzen.

| Nr. | Schritt | Erwartung |
|---|---|---|
| Ü1 | Anmeldebildschirm ansehen | „Benutzer:“, „Sitzung:“, „Anmelden“, „Neu starten“, „Ausschalten“; Tooltip am Stift-Knopf „Benutzernamen eingeben“ |
| Ü2 | „Anmelden“ mit gewähltem Benutzer | Feld „Passwort:“, Knöpfe „Abbrechen“ und „Anmelden“ |
| Ü3 | falsches Passwort | Meldung „Falsches Passwort. Bitte erneut versuchen.“; im Protokoll `Error from greetd: … AUTH_ERR` |
| Ü4 | Uhr | Datum und Zeit wie im Panel, z. B. „22.10.2026 02:54“ |
| Ü5 | `printf 'Alpha 2.1\n' \| sudo tee /usr/share/querencia/version` (nur ohne Metapaket ab Alpha 2.1), Anmeldebildschirm neu (`sudo systemctl restart display-manager` von tty1 aus) | Grußtext „Querencia Desktop Alpha 2.1“; ohne Datei nur „Querencia Desktop“ |
| Ü6 | Gegenprobe Englisch: `sudo localectl set-locale LANG=en_US.UTF-8`, Anmeldebildschirm neu; danach `sudo localectl set-locale LANG=de_DE.UTF-8` | „User:“, „Login“, „Reboot“, „Power Off“, „Wrong password. Please try again.“; Uhr „10/22/2026 02:54“; Sitzung aus Ü7 „Test session“, Meldung aus Ü8 englisch; nirgends ein deutscher Text |
| Ü7 | Sitzungsname (ab 0.1.3): `printf '[Desktop Entry]\nName=Test session\nName[de]=Testsitzung\nExec=/bin/false\nType=Application\n' \| sudo tee /usr/local/share/wayland-sessions/probe.desktop`, `freigeben = probe` in `sitzungen.conf`, Anmeldebildschirm neu; danach Datei löschen, Freigabe zurücknehmen | Sitzungsliste „Querencia Desktop“ und „Testsitzung“; `auswahl.txt`: `probe.desktop freigegeben` |
| Ü8 | Abgelaufenes Passwort (ab 0.1.4): `sudo passwd -e probe`, anmelden mit dem alten Passwort; dann `Strg+Alt+F1`, als `probe` anmelden, altes und zweimal neues Passwort, abmelden, `Strg+Alt+F7`, mit dem neuen Passwort anmelden | „Ihr Passwort ist abgelaufen. Bitte wählen Sie ein neues.“ und „Dazu an der Textkonsole anmelden (Strg+Alt+F1); Strg+Alt+F7 führt hierher zurück.“, nach 10 s noch sichtbar; kein „NEW_AUTHTOK_REQD“; auf tty1 fragt `login` nach dem neuen Passwort; danach Anmeldung am Anmeldebildschirm. Englisch (Ü6): „Your password has expired. Please choose a new one.“ |
| Ü9 | GTK-Texte: `dpkg -l language-pack-gnome-de-base`; Zeiger auf das Auge im Passwortfeld | mit dem Paket „Text anzeigen“; ohne bleibt es „Show Text“ (Grenze, `docs/uebersetzung.md`) |
| Ü10 | Italienisch (ab 0.1.5; Spanisch, Französisch entsprechend): `sudo localectl set-locale LANG=it_IT.UTF-8` (Locale erzeugt, `locale -a` zeigt `it_IT.utf8`), Anmeldebildschirm neu; falsches Passwort; Ü8 mit `passwd -e`; danach Sprache zurück | „Utente:“, „Sessione:“, „Accedi“, „Riavvia“, „Spegni“, Tooltip „Inserire il nome utente“; Feld „Password:“, „Annulla“; „Password errata. Riprovare.“; Uhr „27/10/2026 22:30“; abgelaufen: „La password è scaduta. Sceglierne una nuova.“ und „Per farlo, accedere alla console testuale (Ctrl+Alt+F1); Ctrl+Alt+F7 riporta qui.“; nirgends ein englischer Text außer GTK ohne `language-pack-gnome-it-base` (Ü9) |

## Belege und Rückmeldung

- Bildschirmfotos `G7`, `G8`, `G8b`, `G11`, `G11a`, `G12`, `G12a`, `G18`, `S3`, `Ü1`–`Ü9`; Befehlsausgaben
  der übrigen Punkte; `/var/log/querencia-anmeldung/log` und
  `journalctl -b -u querencia-anmeldung` bei jedem FAIL.
- Seit 0.1.2 übersetzt ein DEP-3-Patch die sichtbaren Texte von ReGreet,
  seit 0.1.3 auch die Meldungen von PAM (`docs/uebersetzung.md`); englisch
  bleiben nur PAM-Meldungen mit Zahlen und der Fehlercode hinter
  „Anmeldung fehlgeschlagen:“ (seit 0.1.4 nicht mehr bei abgelaufenem
  Passwort). Vor der VM gibt es die isolierten Proben
  `tests/sprache-probe.sh` (Fotos, ohne greetd und PAM) und
  `tests/passwort-probe.sh` (echtes greetd und PAM, Wegwerf-Benutzer).
- Nach der Prüfung die VM auf den Ausgangssnapshot zurücksetzen.
