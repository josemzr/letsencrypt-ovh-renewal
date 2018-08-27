#!/bin/bash
TARGET="domain.tld";

data=`echo | openssl s_client -connect "${TARGET}":443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed -e 's#notAfter=##'`

ssldate=`date -d "${data}" '+%s'`
nowdate=`date '+%s'`
diff="$((${ssldate}-${nowdate}))"

if test "${diff}" -lt "7";
	then
		echo "The certificate for "${TARGET}" has already expired."
		/opt/dehydrated/dehydrated -c -t dns-01 -k '/opt/dehydrated/hooks/ovh/hook.py' -d "${TARGET}"
		service openvpnas stop
		/usr/local/openvpn_as/scripts/confdba -mk cs.ca_bundle -v "`cat /opt/dehydrated/certs/"${TARGET}"/fullchain.pem`"
		/usr/local/openvpn_as/scripts/confdba -mk cs.priv_key -v "`cat /opt/dehydrated/certs/"${TARGET}"/privkey.pem`" > /dev/null
		/usr/local/openvpn_as/scripts/confdba -mk cs.cert -v "`cat /opt/dehydrated/certs/"${TARGET}"/cert.pem`"
		service openvpnas start   
	else
		echo "The certificate for "${TARGET}" will expire in $((${diff}/3600/24)) days."
        fi
