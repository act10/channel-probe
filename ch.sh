#!/usr/local/bin/bash
function writelog () {
    /bin/echo "`/bin/date +%d/%m/%Y" "%H":"%M` : $1  channel $2"|tee -a /var/log/channels-status.log
}
function pinghost() {
    /sbin/ping -S $1 -c 1 -t 5 $2 |/usr/bin/grep ttl -c > /dev/null 2>&1
}
IP_GW_1=192.168.200.1
IP_1=192.168.200.200
IP_GW_2=192.168.250.1
IP_2=192.168.250.200
rm /tmp/channel.on.1;rm /tmp/channel.on.2

if (netstat -rn|grep default|grep $IP_GW_1);then touch /tmp/channel.on.1;else touch /tmp/channel.on.2;fi

while [ true ]
do
# проверяем живой ли 1 канал
if ( pinghost $IP_1 $IP_GW_1 ) > 0;
  #и в случае если все нормально
    then writelog OK 1;
        #проверяем не включен ли бекапный
        if [ ! -f /tmp/channel.on.1 ];
            #если включен бекапный
            then
                #то поднимаем основной канал
                writelog SWITCH 1;
                /usr/local/bin/bash /etc/rc.fw.1;
                touch /tmp/channel.on.1;
                rm /tmp/channel.on.2;
            else
                #тут надо проверить, а не висит ли второй канал и если висит перенести пользователей на первый канал
                if ( pinghost $IP_2 $IP_GW_2 ) > 0;
                    then writelog OK 2;
                    else writelog FAILED 2;
                fi
        fi
#если  канал 1 не пингуется,
else  writelog FAILED 1;
        #то проверяем не включен ли уже бекапный канал
        if [ ! -f /tmp/channel.on.2 ];
            then
                #проверяем живой ли второй канал
                if ( pinghost $IP_2 $IP_GW_2 ) > 0;
                    then
                        #подниманием бекапный канал
                        writelog SWITCH 2;
                        /usr/local/bin/bash /etc/rc.fw.2;
                        touch /tmp/channel.on.2;
                        rm /tmp/channel.on.1;
                    else
                        # если бекапный канал тоже не пингуется
                        writelog FAILED 2;
                fi
        fi
fi
sleep 10
done
#eof
#screen -dmS channel-probe -e^Oa /root/bin/ch.sh
