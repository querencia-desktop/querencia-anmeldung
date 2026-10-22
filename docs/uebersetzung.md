# Übersetzung des Anmeldebildschirms

Seit 0.1.2 zeigt der Anmeldebildschirm seine Texte in der Systemsprache.
Mitgeliefert ist Deutsch, Quelltext ist Englisch.

## Der Patch an ReGreet

ReGreet 0.5.0 hat keine Übersetzungen; seine Texte stehen englisch im
Quelltext. Das Paket wendet deshalb einen einzigen DEP-3-Patch an:
`querencia-packaging/querencia-anmeldung/debian/patches/0001-gettext-uhr-nach-lc-time.patch`
(Quellformat `3.0 (quilt)`). Entschieden hat das die Startsession am
22.10.2026; vorher galt „ReGreet nicht patchen“.

| Datei in ReGreet | Änderung |
|---|---|
| `src/gui/mod.rs` | `tr(msgid)` = `glib::dgettext(Some("querencia-anmeldung"), msgid)` |
| `src/gui/templates.rs` | Beschriftungen, Knöpfe und Tooltips über `tr` |
| `src/gui/model.rs` | Eingabeaufforderungen von PAM und Fehlermeldungen über `tr`; abgelehntes Passwort (`AUTH_ERR`) als „Wrong password. Please try again.“ statt „Login failed: Pam_authenticate: AUTH_ERR“ |
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
- Neue Texte im Patch: in `po/de.po` eintragen, sonst scheitert der Bau.

## Sprache, Uhr, Info-Zeile

- Sprache: `anmeldung-starten` übernimmt `LANG`, `LANGUAGE` und `LC_*`
  aus `/etc/default/locale`; fehlt die Datei, gilt die Umgebung des
  Dienstes. Die Locale muss erzeugt sein (`locale -a`).
- Uhr: `format = "%x %H:%M"` in `regreet.toml`; `%x` ist das Datum der
  Zeitsprache, deutsch „22.10.2026 02:54“ wie im Panel, englisch (USA)
  „10/22/2026 02:54“.
- PAM: greetd setzt keine Sprache, deshalb kommen die Aufforderungen von
  `pam_unix` englisch („Password:“); `po/de.po` übersetzt die üblichen.
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
