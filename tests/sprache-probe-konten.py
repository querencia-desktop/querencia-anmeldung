# SPDX-License-Identifier: GPL-3.0-or-later
# Schein-AccountsService für tests/sprache-probe.sh: ein Benutzer
# "Querencia Probe" (probe, /bin/bash) auf dem Bus in
# DBUS_SYSTEM_BUS_ADDRESS. ReGreet liest daraus nur die Benutzerliste.
from gi.repository import Gio, GLib

XML = """
<node>
  <interface name="org.freedesktop.Accounts">
    <method name="ListCachedUsers"><arg type="ao" direction="out"/></method>
  </interface>
  <interface name="org.freedesktop.Accounts.User">
    <property name="RealName" type="s" access="read"/>
    <property name="UserName" type="s" access="read"/>
    <property name="Shell" type="s" access="read"/>
  </interface>
</node>
"""
KNOTEN = Gio.DBusNodeInfo.new_for_xml(XML)
BENUTZER = "/org/freedesktop/Accounts/User1000"
WERTE = {"RealName": "Querencia Probe", "UserName": "probe", "Shell": "/bin/bash"}


def methode(_verb, _sender, _pfad, _iface, name, _param, aufruf):
    if name == "ListCachedUsers":
        aufruf.return_value(GLib.Variant("(ao)", ([BENUTZER],)))


def eigenschaft(_verb, _sender, _pfad, _iface, name):
    return GLib.Variant("s", WERTE[name])


def verbunden(verb, _name):
    verb.register_object("/org/freedesktop/Accounts", KNOTEN.interfaces[0], methode, None, None)
    verb.register_object(BENUTZER, KNOTEN.interfaces[1], None, eigenschaft, None)


Gio.bus_own_name(Gio.BusType.SYSTEM, "org.freedesktop.Accounts", Gio.BusNameOwnerFlags.NONE,
                 verbunden, None, None)
GLib.MainLoop().run()
