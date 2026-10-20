# Standard-Anmeldedienst wählen

Beim Systemstart läuft genau ein Display-Manager: der, auf den
`/etc/systemd/system/display-manager.service` zeigt. Debian und Ubuntu
halten ihn zusätzlich in `/etc/X11/default-display-manager` (Pfad des
Programms) und in der gemeinsamen debconf-Frage
`shared/default-x-display-manager` fest, die gdm3, lightdm, sddm und die
Querencia Anmeldung gemeinsam besitzen. Die Querencia Anmeldung folgt
diesem Verfahren; ihr Programm ist `/usr/sbin/querencia-anmeldung`, ihr
Dienst `querencia-anmeldung.service`.

**Kein laufender Display-Manager wird angehalten.** Jeder Wechsel wirkt
nach dem nächsten Neustart; wer angemeldet ist, bleibt angemeldet.

## Bei der Installation

| Ausgangslage | Ergebnis |
|---|---|
| kein Display-Manager eingerichtet (Server, frisches System) | Querencia Anmeldung wird Standard |
| GDM (oder lightdm, sddm) ist Standard, Installation mit Rückfrage | debconf fragt, GDM ist vorbelegt |
| GDM ist Standard, Installation ohne Rückfrage (`noninteractive`) | GDM bleibt |
| `QUERENCIA_ANMELDUNG=ja` gesetzt | Querencia Anmeldung wird Standard |
| `QUERENCIA_ANMELDUNG=nein` gesetzt | nichts wird umgestellt |
| von Hand eingerichteter Dienst ohne debconf-Eintrag (z. B. `greetd.service` mit eigener Konfiguration) | bleibt; Hinweis auf `dpkg-reconfigure` |
| `display-manager.service` maskiert (`/dev/null`) | nichts wird umgestellt |

Aktualisierungen des Pakets stellen nie um.

Die Umgebungsvariable reicht `sudo` weiter, wenn sie im Befehl steht:

```bash
sudo QUERENCIA_ANMELDUNG=ja apt install ./querencia-anmeldung_0.1.0-1_amd64.deb
```

## Wechseln

Zur Querencia Anmeldung oder zurück (Frage mit allen installierten
Display-Managern, vorbelegt mit dem aktiven):

```bash
sudo dpkg-reconfigure querencia-anmeldung
```

`sudo dpkg-reconfigure gdm3` stellt dieselbe Frage; beide Wege sind
gleichwertig. Ohne Frage:

```bash
sudo QUERENCIA_ANMELDUNG=ja dpkg-reconfigure querencia-anmeldung
```

```bash
sudo QUERENCIA_ANMELDUNG=nein dpkg-reconfigure querencia-anmeldung
```

`=nein` schaltet auf den Display-Manager zurück, der vor der Querencia
Anmeldung aktiv war; gibt es keinen anderen, startet das System mit der
Textanmeldung.

Prüfen, was nach dem Neustart startet:

```bash
cat /etc/X11/default-display-manager; readlink /etc/systemd/system/display-manager.service
```

## Entfernen

`apt remove querencia-anmeldung` trägt den Display-Manager wieder ein, der
vor der ersten Übernahme aktiv war (gemerkt in debconf), wenn er noch
installiert ist – also z. B. GDM. Sonst fragt debconf nach einem anderen
installierten Display-Manager; gibt es keinen, startet das System mit der
Textanmeldung. `apt purge` entfernt zusätzlich Zustand
(`/var/lib/querencia-anmeldung`), Protokoll (`/var/log/querencia-anmeldung`),
die Konfiguration unter `/etc/querencia/greetd` und die debconf-Einträge.

Wer beim Entfernen über die Querencia Anmeldung angemeldet ist, bleibt es;
nach dem Abmelden fehlt der Anmeldebildschirm bis zum Neustart. Deshalb
nach dem Entfernen neu starten.

## Umstieg von einem von Hand eingerichteten greetd

Lief greetd schon mit eigener Konfiguration (`greetd.service` als
display-manager, z. B. ReGreet unter `/usr/local/bin`), bleibt das bei der
Installation so. Umschalten mit `sudo dpkg-reconfigure querencia-anmeldung`;
beim Entfernen der Querencia Anmeldung wird der vorherige Link auf
`greetd.service` wiederhergestellt. Die alte Konfiguration in
`/etc/greetd/` wird nie verändert.
