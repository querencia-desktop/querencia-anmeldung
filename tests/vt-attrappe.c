/* SPDX-License-Identifier: GPL-3.0-or-later */
/* Vorladebibliothek für tests/passwort-probe.sh: täuscht greetd eine
 * virtuelle Konsole vor. Ein Benutzer-Namensraum darf keine VT schalten;
 * deshalb liefern hier alle VT- und KD-Aufrufe (ioctl-Typ 'V' und 'K')
 * Erfolg, VT_GETSTATE und VT_OPENQRY melden VT 7. TIOCSCTTY auf der
 * Ersatz-Konsole (einem pty) darf scheitern. Alles andere geht an libc.
 * mlockall (greetd hält damit Passwörter aus dem Auslagerungsspeicher)
 * ist hier wirkungslos: ohne CAP_IPC_LOCK im ersten Namensraum gilt
 * RLIMIT_MEMLOCK (meist 8 MiB), und PAM-Module ließen sich danach nicht
 * mehr laden (mmap EAGAIN, pam_open_session: MODULE_UNKNOWN). */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <linux/vt.h>
#include <linux/kd.h>
#include <stdarg.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

int mlockall(int flags)
{
    (void)flags;
    return 0;
}

int ioctl(int fd, unsigned long req, ...)
{
    static int (*echt)(int, unsigned long, ...);
    va_list ap;
    void *arg;

    va_start(ap, req);
    arg = va_arg(ap, void *);
    va_end(ap);
    if (!echt)
        echt = (int (*)(int, unsigned long, ...))dlsym(RTLD_NEXT, "ioctl");
    switch ((req >> 8) & 0xff) {
    case 'V':
        if (req == VT_GETSTATE && arg)
            ((struct vt_stat *)arg)->v_active = 7;
        if (req == VT_OPENQRY && arg)
            *(int *)arg = 7;
        return 0;
    case 'K':
        if (req == KDGETMODE && arg)
            *(int *)arg = KD_TEXT;
        return 0;
    }
    if (req == TIOCSCTTY) {
        echt(fd, req, arg);
        return 0;
    }
    return echt(fd, req, arg);
}
