DEB_DOWNLOAD="https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-4%2Bubuntu22.04_all.deb"
AGENT_CONFIG="/etc/zabbix/zabbix_agent2.conf"
PSKNAME=""

read -p "Enter zabbix server: " ZABBIX_SERVER
read -p "Enter local hostname: " AGENT_HOSTNAME

read -n 1 -r -p "Continue [y/N]: "
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
        exit 1
fi

items=($(echo ${AGENT_HOSTNAME^^} | tr " " "\n"))
for i in "${items[@]}"
do
        [ ${#i} -le 5 ] && PSKNAME=${PSKNAME}$i || PSKNAME=${PSKNAME}${i::1}
done

wget -O /tmp/zabbix.deb $DEB_DOWNLOAD
dpkg -i /tmp/zabbix.deb
rm -f /tmp/zabbix.deb

apt update
apt install -y zabbix-agent2 zabbix-agent2-plugin-*

sed -i "s/^Server=.*$/Server=${ZABBIX_SERVER}/" $AGENT_CONFIG
sed -i "s/^ServerActive=.*$/ServerActive=${ZABBIX_SERVER}/" $AGENT_CONFIG
sed -i "s/^Hostname=.*$/Hostname=${AGENT_HOSTNAME}/" $AGENT_CONFIG

sed -i "s/^# TLSConnect=/TLSConnect=/" $AGENT_CONFIG
sed -i "s/^TLSConnect=.*$/TLSConnect=psk/" $AGENT_CONFIG

sed -i "s/^# TLSAccept=/TLSAccept=/" $AGENT_CONFIG
sed -i "s/^TLSAccept=.*$/TLSAccept=psk/" $AGENT_CONFIG

sed -i "s/^# TLSPSKIdentity=/TLSPSKIdentity=/" $AGENT_CONFIG
sed -i "s/^TLSPSKIdentity=.*$/TLSPSKIdentity=PSK ${PSKNAME}/" $AGENT_CONFIG

sed -i "s/^# TLSPSKFile=/TLSPSKFile=/" $AGENT_CONFIG
sed -i "s|^TLSPSKFile=.*$|TLSPSKFile=${AGENT_CONFIG}.psk|" $AGENT_CONFIG

systemctl restart zabbix-agent2.service
systemctl enable zabbix-agent2.service

echo
echo "Success!!!"
echo
echo "Zabbix Server: $ZABBIX_SERVER"
echo "Agent Hostname: $AGENT_HOSTNAME"
echo "PSK Identity: PSK $PSKNAME"
echo "PSK Content:"
cat ${AGENT_CONFIG}.psk
