# Übersetzung des Anmeldebildschirms

Seit 0.1.2 zeigt der Anmeldebildschirm seine Texte in der Systemsprache.
Mitgeliefert ist Deutsch, Quelltext ist Englisch. Seit 0.1.3 durchgehend:
bei `de_DE` alles deutsch, bei `en_US` alles englisch, auch Sitzungsnamen
und Meldungen von PAM (`tests/sprache-texte.txt` listet die erwarteten
Texte beider Sprachen).

| Text | Quelle | Deutsch kommt aus |
|---|---|---|
| Beschriftungen, Knöpfe, Tooltips, eigene Fehlermeldungen | ReGreet (Patch, `tr`) | `po/de.po` |
| Uhr | ReGreet (Patch, Uhr nach `LC_TIME`) | Zeitsprache des Systems |
| Eingabeaufforderungen und Meldungen von PAM | greetd (ohne Sprache) | `po/de.po`, sonst Katalog `Linux-PAM` (`language-pack-de-base`) |
| Sitzungsnamen | `Name[de]` usw. der Sitzungsdatei | `sitzung-starten`, `sitzungen-auswahl` |
| Tooltip am Auge, Hinweis Feststelltaste, Kontextmenü der Eingabefelder | GTK selbst | Katalog `gtk40` (`language-pack-gnome-de-base`) |
| Grußtext „Querencia Desktop Alpha …“, Benutzername | Name und Ausgabe, Konto | in beiden Sprachen gleich |

## Der Patch an ReGreet

ReGreet 0.5.0 hat keine Übersetzungen; seine Texte stehen englisch im
Quelltext. Das Paket wendet deshalb einen einzigen DEP-3-Patch an:
`querencia-packaging/querencia-anmeldung/debian/patches/0001-gettext-uhr-nach-lc-time.patch`
(Quellformat `3.0 (quilt)`). So entschieden am
22.10.2026; vorher galt „ReGreet nicht patchen“.

| Datei in ReGreet | Änderung |
|---|---|
| `src/gui/mod.rs` | `tr(msgid)` = `glib::dgettext(Some("querencia-anmeldung"), msgid)`; `tr_pam(msgid)` für Texte von PAM: erst `tr`, dann `dgettext(Some("Linux-PAM"), msgid)` (seit 0.1.3) |
| `src/gui/templates.rs` | Beschriftungen, Knöpfe und Tooltips über `tr` |
| `src/gui/model.rs` | Eingabeaufforderungen, Info- und Fehlermeldungen von PAM über `tr_pam` (Meldungen seit 0.1.3), eigene Fehlermeldungen über `tr`; abgelehntes Passwort (`AUTH_ERR`) als „Wrong password. Please try again.“ statt „Login failed: Pam_authenticate: AUTH_ERR“; abgelaufenes Passwort (`NEW_AUTHTOK_REQD`, seit 0.1.4) als zweizeilige Meldung mit Hinweis auf die Textkonsole, eine Minute sichtbar |
| `src/gui/widget/clock.rs` | Sprache der Uhr aus `LC_ALL`, `LC_TIME`, `LANG` |

glib kommt mit gtk4 und relm4: keine neue Crate, `Cargo.lock` bleibt
unverändert. GTK ruft beim Start `setlocale(LC_ALL, "")` auf; ohne
`bindtextdomain` sucht gettext den Katalog im Standardordner
`/usr/share/locale/<sprache>/LC_MESSAGES/querencia-anmeldung.mo`. Fehlt
ein Text im Katalog, bleibt er englisch.

Warum die Uhr englisch war: ReGreet nimmt die Sprache der Uhr aus
`sys-locale`, das `LC_TIME` nicht kennt und `de-DE` liefert; chronos
`Locale` erwartet `de_DE`, also fiel die Uhr auf `en_US` zurück.

## Katalog und Prüfung

- `po/de.po` (Domäne `querencia-anmeldung`), installiert als
  `/usr/share/locale/de/LC_MESSAGES/querencia-anmeldung.mo` (`msgfmt -c`
  in `debian/rules`).
- `tests/uebersetzung-pruefen.sh <regreet-quellbaum>` sucht alle
  `tr("…")` im gepatchten Quellbaum und prüft, dass jeder Text in
  `po/de.po` übersetzt ist; läuft beim Paketbau nach dem Patch.
  `debian/rules` prüft außerdem, dass ein Text des Patches im Binary
  steht.
- Seit 0.1.3 prüft `tests/uebersetzung-pruefen.sh` außerdem, dass keine
  sichtbaren Texte ohne `tr` im Quellbaum stehen (Beschriftungen in
  `templates.rs`, Anzeigetexte in `model.rs`), dass alle Texte von PAM
  über `tr_pam` gehen und dass die erwarteten Texte aus
  `tests/sprache-texte.txt` stimmen (eigener Katalog genau; Linux-PAM und
  GTK nur, wenn deren Kataloge und die Locale `de_DE` auf dem Prüfrechner
  liegen, sonst SKIP).
- `tests/passwort-probe.sh` (seit 0.1.4) prüft den Weg über greetd und
  PAM: echtes greetd und der PAM-Dienst `greetd` des Systems mit einem
  Wegwerf-Benutzer (`useradd`, zufälliges Passwort, `chage -d 0`) unter
  einem Overlay auf `/etc` in einem Benutzer-Namensraum mit
  untergeordneten IDs (`unshare --map-auto`). Statt einer Konsole bekommt
  greetd ein pty und die Vorladebibliothek `tests/vt-attrappe.c`
  (VT-Aufrufe und `mlockall` wirkungslos). Ein Mitschnitt zwischen ReGreet
  und greetd (`tests/passwort-probe-ipc.py`) schreibt das Protokoll nach
  `ipc-<sprache>.txt`, Antworten ohne Inhalt; PAM schreibt in
  `syslog-<sprache>.txt` statt ins Journal.
- `tests/sprache-probe.sh` fotografiert den Anmeldebildschirm isoliert:
  das gebaute ReGreet im Demo-Modus in einem kopflosen labwc, in einem
  eigenen Benutzer- und Mount-Namensraum (Katalog, Sitzungen und ein
  Schein-Benutzer nur dort sichtbar, nichts am System geändert). Mit
  `ohne-gtk-katalog` wie ein System ohne `language-pack-gnome-de-base`.
- Neue Texte im Patch: in `po/de.po` eintragen, sonst scheitert der Bau.

## Sprache, Uhr, Info-Zeile

- Sprache: `anmeldung-starten` übernimmt `LANG`, `LANGUAGE` und `LC_*`
  aus `/etc/default/locale`; fehlt die Datei, gilt die Umgebung des
  Dienstes. Die Locale muss erzeugt sein (`locale -a`).
- Uhr: `format = "%x %H:%M"` in `regreet.toml`; `%x` ist das Datum der
  Zeitsprache, deutsch „22.10.2026 02:54“ wie im Panel, englisch (USA)
  „10/22/2026 02:54“.
- PAM: greetd ruft kein `setlocale` auf, deshalb kommen Aufforderungen und
  Meldungen von `pam_unix` immer englisch („Password:“ oder die Meldung,
  dass das Passwort sofort zu ändern ist). ReGreet übersetzt sie mit
  `tr_pam`: erst `po/de.po` (kurze Aufforderungen wie „Neues Passwort:“),
  dann der Katalog `Linux-PAM` des Systems (unter Ubuntu in
  `language-pack-de-base`, das jedes deutsche System hat). Meldungen mit
  Zahlen („… in 3 days“) bleiben englisch, ebenso der technische Teil von
  „Anmeldung fehlgeschlagen: Pam_acct_mgmt: …“ (Fehlercode von greetd)
  für seltene Fälle wie ein abgelaufenes Konto (`ACCT_EXPIRED`).
- Abgelaufenes Passwort (seit 0.1.4, nach `chage -d 0`, `passwd -e` oder
  überschrittener Höchstdauer): greetd 0.10.3 kann kein Passwort ändern;
  es ruft `pam_chauthtok` nicht auf (`nm -D /usr/sbin/greetd`). Gemessen
  mit `tests/passwort-probe.sh` laufen nach dem richtigen Passwort zwei
  Nachrichten: erst die Meldung von PAM („You are required to change your
  password immediately (administrator enforced).“, Typ `error`), ReGreet
  bestätigt sie leer, dann beendet greetd die Anmeldung mit `error`/
  `auth_error` „pam_acct_mgmt: NEW_AUTHTOK_REQD“. Die zweite Nachricht
  überschrieb die übersetzte erste sofort. Seit 0.1.4 zeigt ReGreet dafür
  „Ihr Passwort ist abgelaufen. Bitte wählen Sie ein neues.“ und darunter
  „Dazu an der Textkonsole anmelden (Strg+Alt+F1); Strg+Alt+F7 führt
  hierher zurück.“ (englisch „Your password has expired. Please choose a
  new one.“ / „To do so, log in on the text console (Ctrl+Alt+F1);
  Ctrl+Alt+F7 brings you back here.“), eine Minute lang. Auf tty1 läuft
  `getty@tty1` (`config/greetd/config.toml`); `login` fragt dort nach dem
  alten und zweimal nach dem neuen Passwort. Einen Wechsel im
  Anmeldebildschirm selbst gäbe es nur mit einem greetd, das nach
  `NEW_AUTHTOK_REQD` `pam_chauthtok` aufruft; greetd ist ein Paket der
  Distribution und wird nicht gepatcht.
- Sitzungsnamen (seit 0.1.3): `sitzung-starten --pruefen` nimmt `Name[…]`
  in der Sprache der Umgebung wie GLib (`LANGUAGE`, sonst `LC_ALL`,
  `LC_MESSAGES`, `LANG`; je Sprache `de_DE@mod`, `de_DE`, `de@mod`, `de`),
  sonst `Name`. `anmeldung-starten` setzt die Systemsprache **vor**
  `sitzungen-auswahl`, das den Namen in die erzeugte Sitzungsdatei
  schreibt (ReGreet liest nur `Name`). „Querencia Desktop“ ist ein Name und
  hat keine Übersetzung. Wechselt die Systemsprache, heißt eine übersetzte
  Sitzung anders; ihre gemerkte Wahl in `state.toml` gilt dann nicht mehr,
  und die Vorwahl nimmt „Querencia Desktop“.
- GTK-eigene Texte (Tooltip „Text anzeigen“ am Auge, Hinweis
  „Feststelltaste ist aktiviert“, Kontextmenü „Ausschneiden“ …) übersetzt
  GTK mit seinem Katalog `gtk40`, unter Ubuntu in
  `language-pack-gnome-de-base`. Fehlt das Paket (Server-Weg: dort kommt
  nur `language-pack-de-base`), bleiben diese Texte englisch – im ganzen
  Desktop, nicht nur hier. GTK-Dialoge folgen dem Sprachpaket des
  Systems (`language-pack-gnome-<xx>`); weder dieses Paket noch das
  Metapaket hängen davon ab (Entscheidung der Startsession vom
  26.10.2026: eine feste Abhängigkeit wäre deutschzentriert). Wer per apt
  installiert, hat die Sprachpakete seines Systems
  (`check-language-support -l de` nennt sie); das Abbild installiert das
  Paket der gewählten Sprache.
- Andere Systemsprachen als Deutsch und Englisch: Beschriftungen englisch
  (kein Katalog), Uhr, Sitzungsnamen und Meldungen von PAM in der
  Systemsprache, soweit es Übersetzungen gibt.
- Info-Zeile: `anmeldung-starten` hängt die Ausgabe aus
  `/usr/share/querencia/release` (`VERSION`) bzw. der ersten Zeile von
  `/usr/share/querencia/version` an den Grußtext („Querencia Desktop Alpha
  2.1“) und lässt ReGreet die Kopie `/run/querencia-anmeldung/regreet.toml`
  lesen. Fehlen beide Dateien (vor Alpha 2.1, ohne Metapaket), bleibt der
  Grußtext „Querencia Desktop“ und ReGreet liest `regreet.toml` direkt.
  Die Info-Zeile braucht keinen Patch.

## Upstream

gettext-Unterstützung lässt sich ReGreet vorschlagen; dann entfiele der
Patch. Der Patch ist dafür aber nicht direkt geeignet: Er nutzt die
Querencia-Domäne und hängt am Katalog dieses Pakets. Upstream bräuchte eine
eigene Domäne (`regreet`), einen `po/`-Ordner mit `.pot` im ReGreet-Repo,
die Installation der Kataloge (ReGreet hat kein Installationsskript, nur
`cargo build`) und ein `bindtextdomain` mit einstellbarem Ordner. Die
Korrektur der Uhr (`LC_TIME` vor `sys-locale`, `de-DE` → `de_DE`) ist
unabhängig davon ein eigener, kleiner Fehlerbericht wert. Eingereicht ist
nichts (`Forwarded: no`).
