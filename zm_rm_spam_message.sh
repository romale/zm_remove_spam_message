#!/bin/bash
#
# Author: aleromex@gmail.com
# Site: https://github.com/romale/zm_rm_spam_message
# Removes message from all Zimbra accounts
# 
# run it from zimbra user
#
# Example: cat /var/log/zimbra.log | zm_rm_spam_message.sh user@domain.com "subject"
#
# or
#
# Example: cat /var/log/zimbra.log | zm_rm_spam_message.sh user@domain.com

LOG_POSTFIX=`strings /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c10`
LOG_FILE="/tmp/zm_rm_spam_message.$LOG_POSTFIX.log"
COUNTER=0

if [ -z "$2" ]; then
    addr=$1
    ACCTS=$(grep -i ${addr}|grep ESMTP|grep "postfix/smtpd"|awk '{print $18}'|sed -e 's/to=<//g' -e 's/>//g'|sort |uniq</dev/stdin)
    echo $ACCTS
    echo `date +%Y%m%d-%H:%M:%S.%3N` "Search spam from $addr"
    for acct in $ACCTS ; do
	echo `date +%Y%m%d-%H:%M:%S.%3N` "Searching $acct"
	for msg in `/opt/zimbra/bin/zmmailbox -z -m "$acct" s -l 999 -t message "(in:junk OR in:inbox) AND from:$addr"|awk '{ if (NR!=1) {print}}' | grep -v -e Id -e "--" -e "^$" | awk '{ print $2 }'`
	do
    	    echo `date +%Y%m%d-%H:%M:%S.%3N` "Delete "$msg" from "$acct"" | tee >> $LOG_FILE
    	    let COUNTER+=1
    	    echo `date +%Y%m%d-%H:%M:%S.%3N` "Total found: $COUNTER"
    	    /opt/zimbra/bin/zmmailbox -z -m $acct moveMessage $msg "/Junk"
    	    # Use deleteMessage(dm) instead moveMessage(mm), otherwise POP3 users will see moved message
    	    /opt/zimbra/bin/zmmailbox -z -m $acct deleteMessage $msg
	done
    done
else
    addr=$1
    subject=$2
    ACCTS=$(grep -i ${addr}|grep ESMTP|grep "postfix/smtpd"|awk '{print $18}'|sed -e 's/to=<//g' -e 's/>//g'|sort |uniq</dev/stdin)
    echo $ACCTS
    echo `date +%Y%m%d-%H:%M:%S.%3N` "Search spam from: $addr with subject: $subject"
    for acct in $ACCTS ; do
	echo `date +%Y%m%d-%H:%M:%S.%3N` "Searching $acct  for Subject:  $subject"
	for msg in `/opt/zimbra/bin/zmmailbox -z -m "$acct" s -l 999 -t message "(in:junk OR in:inbox) AND from:$addr subject:$subject"|awk '{ if (NR!=1) {print}}' | grep -v -e Id -e "--" -e "^$" | awk '{ print $2 }'`
	do
    	    echo `date +%Y%m%d-%H:%M:%S.%3N` "Delete "$msg" from "$acct"" | tee >> $LOG_FILE
    	    let COUNTER+=1
    	    echo `date +%Y%m%d-%H:%M:%S.%3N` "Total found: $COUNTER"
    	    /opt/zimbra/bin/zmmailbox -z -m $acct moveMessage $msg "/Junk"
    	    # Use deleteMessage(dm) instead moveMessage(mm), otherwise POP3 users will see moved message
    	    /opt/zimbra/bin/zmmailbox -z -m $acct deleteMessage $msg
	done
    done
fi
echo `date +%Y%m%d-%H:%M:%S.%3N` "Total found: $COUNTER"
