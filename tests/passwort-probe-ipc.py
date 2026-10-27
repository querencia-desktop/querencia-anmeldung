# SPDX-License-Identifier: GPL-3.0-or-later
# Mitschnitt des greetd-Protokolls für tests/passwort-probe.sh: lauscht auf
# <eigener-socket>, reicht jede Nachricht an <greetd-socket> weiter und
# schreibt sie als JSON-Zeile nach <log>. Antworten des Greeters auf
# Abfragen (post_auth_message_response) erscheinen ohne Inhalt; "gleich"
# sagt nur, ob die Antwort dem Wegwerf-Passwort in /mnt/passwort entspricht.
import json
import os
import socket
import struct
import sys
import threading

EIGEN, GREETD, LOG = sys.argv[1:4]
schreiben = threading.Lock()


def lesen(s, n):
    daten = b""
    while len(daten) < n:
        stueck = s.recv(n - len(daten))
        if not stueck:
            raise EOFError
        daten += stueck
    return daten


def notieren(richtung, nachricht):
    if nachricht.get("type") == "post_auth_message_response":
        r = nachricht.get("response")
        try:
            gleich = r == open("/mnt/passwort", encoding="utf-8").read().strip() if r else None
        except OSError:
            gleich = None
        nachricht = dict(nachricht, response="<verborgen>" if r else None, gleich=gleich)
    with schreiben, open(LOG, "a", encoding="utf-8") as f:
        f.write(f"{richtung} {json.dumps(nachricht, ensure_ascii=False)}\n")


def weiter(von, nach, richtung):
    try:
        while True:
            kopf = lesen(von, 4)
            rumpf = lesen(von, struct.unpack("=I", kopf)[0])
            notieren(richtung, json.loads(rumpf))
            nach.sendall(kopf + rumpf)
    except (EOFError, OSError):
        pass
    for s in (von, nach):
        try:
            s.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass


server = socket.socket(socket.AF_UNIX)
server.bind(EIGEN)
os.chmod(EIGEN, 0o600)
server.listen()
while True:
    greeter, _ = server.accept()
    zu_greetd = socket.socket(socket.AF_UNIX)
    zu_greetd.connect(GREETD)
    threading.Thread(target=weiter, args=(greeter, zu_greetd, "greeter->greetd"), daemon=True).start()
    threading.Thread(target=weiter, args=(zu_greetd, greeter, "greetd->greeter"), daemon=True).start()
