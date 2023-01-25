#!/usr/bin/with-contenv bashio

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir

DEBUGING=0

# Let's encrypt
LE_UPDATE="0"

TOKENAPI=''
DOMAIN=''
SUBDOMAIN=''
WAIT_TIME=60
VIEWPING=1

SUBDOMAINID="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}1" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .record_id")";
LAST_MY_IP="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .content")";
MY_IP=''
RESULT_CHANGE_STATE=''


if [ $DEBUGING != 1 ] 
then
	TOKENAPI=$(bashio::config 'token')
	DOMAIN=$(bashio::config 'domain')
	SUBDOMAIN=$(bashio::config 'subdomain')
	WAIT_TIME=$(bashio::config 'seconds')
	VIEWPING=$(bashio::config 'debug')
fi

if [ $DEBUGING != 1 ] 
then 
	bashio::log.debug "Starting"
	bashio::log.info  "TOKENAPI: ${TOKENAPI}"
	bashio::log.info  "DOMAIN: ${DOMAIN}"
	bashio::log.info  "SUBDOMAIN: ${SUBDOMAIN}"
	bashio::log.info  "WAIT_TIME: ${WAIT_TIME}"
fi

function GetLastMyIP() {
	LAST_MY_IP="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .content")";
}

function GetMyIp() {
	MY_IP="$(curl -s "https://api.myip.com/" | jq -r ".ip")";
	
	if [ $DEBUGING != 1 ] 
	then 
		bashio::log.debug "Recive ip: ${MY_IP}"
	fi
}

function ChangeMyIP() {
	RESULT_CHANGE_STATE="$(curl -H "PddToken: ${TOKENAPI}" -d "domain=${DOMAIN}&record_id=${SUBDOMAINID}&subdomain=${SUBDOMAIN}&ttl=60&content=$1" -s  "https://pddimp.yandex.ru/api2/admin/dns/edit" | jq -r ".success")";
	
	if [ $DEBUGING != 1 ] 
	then 
		bashio::log.debug "Change ip state: ${RESULT_CHANGE_STATE}"
	fi
}

function CheckMyIP() {
	GetLastMyIP
	GetMyIp


	if [ "$MY_IP" != "$LAST_MY_IP" ] && [ -n "$MY_IP" ] && [ -n "$LAST_MY_IP" ];
	then
		if [ $DEBUGING != 1 ] 
		then
			bashio::log.info "My ip chenged: ${MY_IP}"
		else
			echo "My ip chenged: ${MY_IP}"
		fi
		
		ChangeMyIP $MY_IP
		
		if [ "$RESULT_CHANGE_STATE" = "ok" ]
		then
			LAST_MY_IP=$MY_IP;
			
			if [ "$DEBUGING" != "1" ] 
			then
				bashio::log.info "Change ip is ok"
			else
				echo 'Change ip is ok'
			fi
		else
			if [ "$DEBUGING" != "1" ] 
			then
				bashio::log.warning "Error update record"
			else
				echo 'Error update record'
			fi
		fi
		
		LE_UPDATE="$(date +%s)"
	fi
}

# Run duckdns
while true; do
	if [ -z "$SUBDOMAINID" ]
	then
		SUBDOMAINID="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .record_id")";
		
		continue
	fi

	now="$(date +%s)"

	if [ $((now - LE_UPDATE)) > "$WAIT_TIME" ]
	then

			CheckMyIP

			LE_UPDATE="$(date +%s)"
	fi
	
	sleep '10';
done