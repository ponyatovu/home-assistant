#!/usr/bin/with-contenv bashio

source trycatch.sh

# Define custom exception types
export ERR_BAD=100
export ERR_WORSE=101
export ERR_CRITICAL=102

ERR_LINE=0


CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir

USE_LOGGER=0

# Let's encrypt
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


if [ $USE_LOGGER != 1 ] 
then
	TOKENAPI=$(bashio::config 'token')
	DOMAIN=$(bashio::config 'domain')
	SUBDOMAIN=$(bashio::config 'subdomain')
	WAIT_TIME=$(bashio::config 'seconds')
	VIEWPING=$(bashio::config 'debug')
fi

if [ $USE_LOGGER != 1 ] 
then 
	bashio::log.debug "Starting"
	bashio::log.info  "TOKENAPI: ${TOKENAPI}"
	bashio::log.info  "DOMAIN: ${DOMAIN}"
	bashio::log.info  "SUBDOMAIN: ${SUBDOMAIN}"
	bashio::log.info  "WAIT_TIME: ${WAIT_TIME}"
	bashio::log.info  "VIEWPING: ${VIEWPING}"
fi

function GetLastMyIP() {
	LAST_MY_IP="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .content")";
}

function GetMyIp() {
	MY_IP="$(curl -s "https://api.myip.com/" | jq -r ".ip")";
	
	if [ $USE_LOGGER != 1 ] 
	then 
		bashio::log.debug "Recive ip: ${MY_IP}"
	fi
}

function ChangeMyIP() {
	RESULT_CHANGE_STATE="$(curl -H "PddToken: ${TOKENAPI}" -d "domain=${DOMAIN}&record_id=${SUBDOMAINID}&subdomain=${SUBDOMAIN}&ttl=60&content=$1" -s  "https://pddimp.yandex.ru/api2/admin/dns/edit" | jq -r ".success")";
	
	if [ $USE_LOGGER != 1 ] 
	then 
		bashio::log.debug "Change ip state: ${RESULT_CHANGE_STATE}"
	fi
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
		if [ $USE_LOGGER != 1 ] 
		then
			bashio::log.info "My ip chenged: ${MY_IP}"
		else
			echo "My ip chenged: ${MY_IP}"
		fi
		
		ERR_LINE=54
		ChangeMyIP $MY_IP
		
		ERR_LINE=55
		if [ "$RESULT_CHANGE_STATE" = "ok" ]
		then
			ERR_LINE=56
			LAST_MY_IP=$MY_IP;
			
			ERR_LINE=57
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.info "Change ip is ok"
			else
				echo 'Change ip is ok'
			fi
		else
			ERR_LINE=58
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.warning "Error update record"
			else
				echo 'Error update record'
			fi
		fi
		
		ERR_LINE=59
		LE_UPDATE="$(date +%s)"
	fi
}

# Run duckdns
while true; do
try
(
	ERR_LINE=1
	
	if [ -z "$SUBDOMAINID" ]
	then
		ERR_LINE=2
		
		SUBDOMAINID="$(curl -H "PddToken: ${TOKENAPI}" -s "https://pddimp.yandex.ru/api2/admin/dns/list?domain=${DOMAIN}" | jq -r "select(has(\"records\")) | .records[] | select(.subdomain==\"$SUBDOMAIN\") | .record_id")";
		
		continue
	fi

	ERR_LINE=3
	now="$(date +%s)"
	
	ERR_LINE=4
	if [ $((now - LE_UPDATE)) > "$WAIT_TIME" ]
	then

		ERR_LINE=5
		
		CheckMyIP

		ERR_LINE=6
		LE_UPDATE="$(date +%s)"
		
		ERR_LINE=7
		if [ $VIEWPING != 0 ] 
		then
			ERR_LINE=8
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.info "${LE_UPDATE}"
			else
				echo "${LE_UPDATE}"
			fi
		fi
	fi
	
	ERR_LINE=9
	sleep "$WAIT_TIME";
)
catch || {
    case $exception_code in
        $ERR_BAD)
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.error "(${ERR_LINE}) This error is bad"
			else
				echo "(${ERR_LINE}) This error is bad"
			fi
        ;;
        $ERR_WORSE)
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.error "(${ERR_LINE}) This error is worse"
			else
				echo "(${ERR_LINE}) This error is worse"
			fi
        ;;
        $ERR_CRITICAL)
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.error "(${ERR_LINE}) This error is critical"
			else
				echo "(${ERR_LINE}) This error is critical"
			fi
        ;;
        *)
			if [ $USE_LOGGER != 1 ] 
			then
				bashio::log.error "(${ERR_LINE}) Unknown error: $exit_code"
			else
				echo "(${ERR_LINE}) Unknown error: $exit_code"
			fi
			
            # throw $exit_code    # re-throw an unhandled exception
        ;;
    esac
}
done