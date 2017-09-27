#!/bin/bash
# ${copyright}
# ------------------------------------------------------------------------------
if [ -n "$SPLUNK_URL" ]; then
    splunk_url=$SPLUNK_URL
fi

if [ -n "$HEC_TOKEN" ]; then
    hec_token=$HEC_TOKEN
fi

if [ ! $splunk_url ] || [ ! $hec_token ]; then
    printf "\033[31mMissing required arguments - SPLUNK_URL, HEC_PORT and HEC_TOKEN.\033[0m\n"
    exit 1;
fi

KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION)

# Detect OS / Distribution
if [ -f /etc/debian_version -o "$DISTRIBUTION" == "Debian" -o "$DISTRIBUTION" == "Ubuntu" ]; then
    OS="Debian"
elif [ -f /etc/redhat-release -o "$DISTRIBUTION" == "RedHat" -o "$DISTRIBUTION" == "CentOS" ]; then
    OS="RedHat"
else
    OS=$(uname -s)
fi

function update_conf {
    # Add custom plugin to collectd.conf
    echo -e "\n##############################################################################" >> /etc/collectd/collectd.conf
    echo -e "# Customization of Write HTTTP Plugin to connect to Splunk HEC                 #" >> /etc/collectd/collectd.conf
    echo -e "#----------------------------------------------------------------------------#" >> /etc/collectd/collectd.conf
    echo -e "# This plugin sends all metrics data from other plugins to Splunk via HEC.   #" >> /etc/collectd/collectd.conf
    echo -e "##############################################################################" >> /etc/collectd/collectd.conf
    echo -e "\nLoadPlugin write_http"  >> /etc/collectd/collectd.conf
    echo -e "\n<Plugin write_http>" >> /etc/collectd/collectd.conf
    echo -e "\n <Node \"node-http-1\">" >> /etc/collectd/collectd.conf
    echo -e "\n  URL \"$SPLUNK_URL\"" >> /etc/collectd/collectd.conf
    echo -e "\n  Header \"X-Splunk-Request-Channel: $HEC_TOKEN\"" >> /etc/collectd/collectd.conf
    echo -e "\n  Header \"Authorization: Splunk $HEC_TOKEN\"" >> /etc/collectd/collectd.conf
    echo -e "\n  Format \"JSON\"" >> /etc/collectd/collectd.conf
    echo -e "\n  Metrics true" >> /etc/collectd/collectd.conf
    echo -e "\n  StoreRates true" >> /etc/collectd/collectd.conf
    echo -e "\n  VerifyPeer false" >> /etc/collectd/collectd.conf
    echo -e "\n  VerifyHost false" >> /etc/collectd/collectd.conf
    echo -e "\n  BufferSize 1024" >> /etc/collectd/collectd.conf
    echo -e "\n </Node>" >> /etc/collectd/collectd.conf
    echo -e "\n</Plugin>" >> /etc/collectd/collectd.conf
}

if [ $OS = "Debian" ]; then
    # If version file exists already - this Splunk has been configured before
    __configured=false
    if [[ -f ${SPLUNK_HOME}/etc/collectd/collectd.log ]]; then
        __configured=true
    fi

    if [[ $__configured == "false" ]]; then
        echo -e "\033[34m\n* Updating configuration.\n\033[0m"
        update_conf
    fi

    echo -e "Running collectd..."
    chown root:docker /var/run/docker.sock 
    exec collectd -f
else
    echo -e "Not supported operating system: $OS. Nothing is installed."
fi


