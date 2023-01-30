#!/usr/bin/with-contenv bashio

ERR_LINE=0

set -e

LE_UPDATE="0"

TOKENAPI=''
DOMAIN=''
SUBDOMAIN=''
WAIT_TIME=60
VIEWPING=true

SUBDOMAINID="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}1" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .record_id")";
LAST_MY_IP="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .content")";
MY_IP=''
RESULT_CHANGE_STATE=''

TOKENAPI=$(bashio::config 'token')
DOMAIN=$(bashio::config 'domain')
SUBDOMAIN=$(bashio::config 'subdomain')
WAIT_TIME=$(bashio::config 'seconds')
log_level=$(bashio::string.lower "$(bashio::config log_level)")

bashio::log.level "$log_level"

bashio::log.info "Starting"
bashio::log.debug  "TOKENAPI: ***"
bashio::log.debug  "DOMAIN: ${DOMAIN}"
bashio::log.debug  "SUBDOMAIN: ${SUBDOMAIN}"
bashio::log.debug  "WAIT_TIME: ${WAIT_TIME}"
bashio::log.debug  "VIEWPING: ${VIEWPING}"
bashio::log.debug  "log_level: ${log_level}"


function GetLastMyIP() {
	LAST_MY_IP="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .content")";
}

function GetMyIp() {
	MY_IP="$(curl -s "https://api.myip.com/" | jq -r ".ip")";
	

	bashio::log.debug "Recive ip: ${MY_IP}"
}

function ChangeMyIP() {
	RESULT_CHANGE_STATE="$(curl -H "PddToken: ${TOKENAPI}" -d "domain=${DOMAIN}&record_id=${SUBDOMAINID}&subdomain=${SUBDOMAIN}&ttl=60&content=$1" -s  "https://pddimp.yandex.ru/api2/admin/dns/edit" | jq -r ".success")";
	
	bashio::log.warning "Change ip state: ${RESULT_CHANGE_STATE}"
}

function CheckMyIP() {
	ERR_LINE=50
	GetLastMyIP
	
	ERR_LINE=51
	GetMyIp

	ERR_LINE=52
	if [ "$MY_IP" != "$LAST_MY_IP" ] && [ -n "$MY_IP" ] && [ -n "$LAST_MY_IP" ];
	then
		ERR_LINE=53
		bashio::log.info "My ip chenged: ${MY_IP}"
		
		ERR_LINE=54
		ChangeMyIP $MY_IP
		
		ERR_LINE=55
		if [ "$RESULT_CHANGE_STATE" = "ok" ]
		then
			ERR_LINE=56
			LAST_MY_IP=$MY_IP;
			
			ERR_LINE=57
			bashio::log.info "Change ip is ok"
		else
			ERR_LINE=58
			bashio::log.error "Error update record"
		fi
		
		ERR_LINE=59
		LE_UPDATE="$(date +%s)"
	fi
}

# Run duckdns
while true; do
{
	ERR_LINE=1
	
	if [ -z "$SUBDOMAINID" ]
	then
		ERR_LINE=2
		
		SUBDOMAINID="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .record_id")";
	else
	
		ERR_LINE=3
		now="$(date +%s)"
		
		ERR_LINE=4
		if [ $((now - LE_UPDATE)) > "$WAIT_TIME" ]
		then

			ERR_LINE=5
			
			CheckMyIP

			ERR_LINE=6
			LE_UPDATE="$(date +%s)"
			
			# ERR_LINE=7
			# bashio::log.debug "ping"
		fi
		
		ERR_LINE=9
		sleep "$WAIT_TIME";
	
	fi
} || {
	bashio::log.error "(${ERR_LINE}) Unknown error"
}
sleep "5";
done