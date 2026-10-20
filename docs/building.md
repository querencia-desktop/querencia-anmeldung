# Paket bauen

Das Debian-Paket entsteht mit den Werkzeugen von `querencia-packaging`
(ohne debhelper, Cargo-Vendoring, `--remap-path-prefix`, Bau-Platz). Der
Quellbaum des Pakets:

| Ordner im Quellbaum | Archiv | Quelle |
|---|---|---|
| `./` | `querencia-anmeldung_<ver>.orig.tar.xz` | ReGreet, Commit des Tags `0.5.0` aus dem Spiegel `upstream/regreet.git` (Zeile in `quellen.conf`) |
| `querencia/` | `…orig-querencia.tar.xz` | dieses Repository, Commit aus `querencia-anmeldung/komponenten.conf` |
| `cargo-vendor/` | `…orig-cargo-vendor.tar.xz` | alle Crates aus ReGreets `Cargo.lock` (`cargo vendor --locked`) |
| `debian/` | `…debian.tar.xz` | `querencia-packaging/querencia-anmeldung/debian/` |

## Spiegel anlegen

Einmalig, dann nur für neue Upstream-Fassungen auffrischen:

```bash
cd ~/projects/querencia-anmeldung && git clone --bare https://github.com/rharish101/ReGreet.git upstream/regreet.git
```

Vor dem Eintrag eines neuen Tags den Commit gegen GitHub prüfen:

```bash
git ls-remote https://github.com/rharish101/ReGreet.git 'refs/tags/0.5.0*'
```

## Bauen

Erst die Änderungen dieses Repositorys committen und den Commit in
`querencia-packaging/querencia-anmeldung/komponenten.conf` eintragen, dann:

```bash
bash werkzeuge/paket-bauen.sh
```

Eine neue Fassung neben der vorigen bauen (die vorige `.deb` bleibt als
Rückfall liegen), mit dem Packaging-Worktree der Fassung:

```bash
QUERENCIA_PACKAGING=~/projects/querencia-packaging-wt-anm2 QUERENCIA_ANMELDUNG_AUSGABE=~/projects/querencia-anmeldung/build/0.1.1 bash werkzeuge/paket-bauen.sh
```

Das Skript ruft `orig-erzeugen.sh` (Archive, Vendoring, `debian/copyright`)
und `paket-bauen.sh` des Packaging-Checkouts mit
`QUERENCIA_AUSGABE=build/` auf. Ergebnis:

- `build/debs/querencia-anmeldung_<ver>_amd64.deb` und `build/debs/SHA256SUMS`
- `build/bau/querencia-anmeldung/` (`.dsc`, `.changes`, `.buildinfo`)
- `build/orig/` (Archive), `build/cargo-home/` (Crate-Zwischenspeicher)
- `build/nachweis/logs/`, `build/nachweis/lizenzen/querencia-anmeldung-crates.tsv`

Die Pfade, die ReGreet beim Bau übernimmt, stehen in `debian/rules`
(`GREETD_CONFIG_DIR=/etc/querencia/greetd`,
`STATE_DIR=/var/lib/querencia-anmeldung`,
`LOG_DIR=/var/log/querencia-anmeldung`,
`SESSION_DIRS=/run/querencia-anmeldung/wayland-sessions`, die Liste von
`sitzungen-auswahl`); der Bau prüft, dass sie im Binary stehen.

## Prüfen

```bash
cd ~/projects/querencia-packaging-wt-anm1 && bash werkzeuge/pakete-pruefen.sh ~/projects/querencia-anmeldung/build/debs/*.deb
```

```bash
lintian -i -I --show-overrides ~/projects/querencia-anmeldung/build/debs/*.deb
```

```bash
cd ~/projects/querencia-packaging-wt-anm1 && bash tests/anmeldung-umschalten.sh
```

Die Funktion am Bildschirm prüft nur eine Test-VM:
`docs/pruefung-anmeldung.md`.
