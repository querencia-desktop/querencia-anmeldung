# Herkunft von ReGreet

## Quelle

| | |
|---|---|
| Projekt | ReGreet – „Clean and customizable greeter for greetd“ |
| Repository | https://github.com/rharish101/ReGreet |
| Version | **0.5.0** (`Cargo.toml`), Tag `0.5.0` |
| Tag-Objekt | `3b8e262f4aecd1d80660f89b3829fccf71242bdb` (annotiert, Harish Rajagopal, 17.07.2026) |
| Commit | `290e6f8d65b7034c5b63bc950a20bcf8277ebe5f` „Bump version“ |
| Abgleich | `git ls-remote https://github.com/rharish101/ReGreet.git 'refs/tags/0.5.0*'` am 20.10.2026: beide Werte gleich |
| Rust | Edition 2024, `rust-version = "1.85"`; Bau mit rustc 1.93.1 der Distribution |
| Abhängigkeiten | GTK 4 (≥ 4.16 wegen glycin), glycin 3.0.8 (Bilder; zur Laufzeit `glycin-loaders`), relm4 0.10, greetd_ipc 0.10, zbus 5 |

## Lizenz

ReGreet ist REUSE-konform:

| Dateien | Lizenz |
|---|---|
| Quelltext (`src/`), `regreet.sample.toml`, `LICENSE` | GPL-3.0-or-later, „The ReGreet Authors“ |
| `src/gui/model.rs`, `README.md` | GPL-3.0-or-later AND MIT (zusätzlich 2021 Maximilian Moser) |
| `Cargo.toml`, `Cargo.lock`, `.gitignore`, `.pre-commit-config.yaml`, `systemd-tmpfiles.conf`, `.github/` | 0BSD |

GPL-3.0-or-later passt zur Lizenz der Querencia-Programme; MIT und 0BSD sind damit verträglich. Die Rust-Abhängigkeiten
listet `debian/copyright` des Pakets (aus den vendorten `Cargo.toml`).

## Der Bau vom 14.10.2026 (Entwicklungs-VM)

Der bisherige Anmeldebildschirm der Entwicklungs-VM nutzt
`/usr/local/bin/regreet` (11 030 200 Byte, 14.10. 16:26). Gemessen am
20.10.:

- `regreet --version` meldet `regreet 0.5.0`.
- Die Arbeitskopie `~/src/ReGreet` (flacher Klon von GitHub, 14.10. 15:29)
  steht auf Tag `0.5.0` = `290e6f8d`, ohne lokale Änderungen
  (`git status` leer).
- `~/src/ReGreet/target/release/regreet` (14.10. 15:32) ist
  **byte-gleich** mit `/usr/local/bin/regreet`
  (SHA256 `6b2baeb1b928b67f5ad8830c616f7705f617e15068f58c8f653298c255186c1c`).
- Gebaut wurde ohne Bauvariablen (das Binary liest
  `/etc/greetd/regreet.toml`, Zustand in `/var/lib/regreet`, Protokoll in
  `/var/log/regreet`, wie die Upstream-Vorgaben). Ein Bauskript oder eine
  Paketierung gibt es nicht; nach den Zeitstempeln wurde das Binary um
  16:26 nach `/usr/local/bin` kopiert (Eigentümer root).

Das Paket nimmt dieselbe Upstream-Version als Quelle (nicht das Binary
von der Entwicklungs-VM); Unterschiede sind nur die Bauvariablen (eigene Pfade)
und die Debian-Bauflags (Härtung, `--remap-path-prefix`).
