# backup syslog
59 23 * * * /usr/local/adm/bin/log-backup.cron


$cat /usr/local/adm/bin/log-backup.cron
#!/bin/sh
#
#
# System log backup(archive) cron

umask 022
date=`/usr/bin/date +%y%m%d`
date_w=`/usr/bin/date +%w`

[ -x /usr/bin/gzip ] && GZIP="/usr/bin/gzip" || GZIP="/usr/local/bin/gzip"

### System log archive

        /usr/bin/mkdir -p /var/log/mail/OLD
        /usr/bin/mkdir -p /var/log/daemon/OLD
        /usr/bin/mkdir -p /var/log/auth/OLD
        /usr/bin/mkdir -p /var/log/sudo/OLD

        /usr/bin/find /var/log/mail -type f -mtime +186 -exec /bin/rm {} \;
        /usr/bin/cp /var/log/mail/mail.info   /var/log/mail/OLD/mail.info.$date
        /usr/bin/cp /var/log/mail/mail.notice /var/log/mail/OLD/mail.notice.$date
        $GZIP --best /var/log/mail/OLD/mail.info.$date
        $GZIP --best /var/log/mail/OLD/mail.notice.$date
        > /var/log/mail/mail.info
        > /var/log/mail/mail.notice

        /usr/bin/find /var/log/daemon -type f -mtime +186 -exec /bin/rm {} \;
        /usr/bin/cp /var/log/daemon/daemon.info   /var/log/daemon/OLD/daemon.info.$date
        /usr/bin/cp /var/log/daemon/daemon.notice /var/log/daemon/OLD/daemon.notice.$date
        $GZIP --best /var/log/daemon/OLD/daemon.info.$date
        $GZIP --best /var/log/daemon/OLD/daemon.notice.$date
        > /var/log/daemon/daemon.info
        > /var/log/daemon/daemon.notice

        /usr/bin/find /var/log/auth -type f -mtime +186 -exec /bin/rm {} \;
        /usr/bin/cp /var/log/auth/auth.info   /var/log/auth/OLD/auth.info.$date
        /usr/bin/cp /var/log/auth/auth.notice /var/log/auth/OLD/auth.notice.$date
        $GZIP --best /var/log/auth/OLD/auth.info.$date
        $GZIP --best /var/log/auth/OLD/auth.notice.$date
        > /var/log/auth/auth.info
        > /var/log/auth/auth.notice

        /usr/bin/refresh -s syslogd 1> /dev/null
        /usr/bin/find /var/log/sudo -type f -mtime +186 -exec /bin/rm {} \;
        /usr/bin/cp /var/log/sudo.log /var/log/sudo/OLD/sudo.log.$date
        $GZIP --best /var/log/sudo/OLD/sudo.log.$date
        > /var/log/sudo.log


### Cron log archive 

if [ `date +%d` = 11 ] ; then
        /usr/bin/mkdir -p /var/log/cron
        /usr/bin/find /var/log/cron -type f -mtime +186 -exec /bin/rm {} \;
        /usr/bin/cp /var/adm/cron/log  /var/log/cron/cron.log.$date
        $GZIP --best /var/log/cron/cron.log.$date
        > /var/adm/cron/log
fi

# root_history archive

HISTDIR=/var/log/sh_history
[[ ! -d $HISTDIR/OLD ]] && mkdir -m 1777 -p $HISTDIR/OLD
find $HISTDIR/OLD -type f -mtime +186 -exec /bin/rm {} \;
find $HISTDIR -type f \( -nouser -o -nogroup \) -exec chown root.system {} \;
find $HISTDIR/* -prune  -type f -size 0 -exec rm {} \;
for F in smit.log smit.script ; do for f in `ls -tr $HISTDIR/$F.*-root 2>/dev/null` ; do cat $f ; done >> $HISTDIR/$F ; done
for F in `find $HISTDIR/* -prune  \(  -name "*history" -o  -name "smit*" \) -type f -exec basename {} \;`
do
        cp -p $HISTDIR/$F $HISTDIR/OLD/$F.$date
        gzip --best $HISTDIR/OLD/$F.$date
        > $HISTDIR/$F
done
