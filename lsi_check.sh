#!/usr/bin/env bash
# requared packages: sshpass, mailutils
# ./lsi_check.sh '1/0 0/1' 2|n esxi|linux ip LOGIN 'pass'

VIRT_DRIVES=( $1 )
NUMBER_VIRT_DRIVES="$2"
CMD_VERSION="$3"
HOST="$4"
LOGIN="$5"
SSH_PASS="$6"
CHECK_INET="8.8.8.8"
MAIL_FROM="lsi-script@domain.ru"
MAIL_DEST="admin1@domain.ru,admin1@domain.ru"

# - #
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CURDATE="$(date +%d-%m-%Y)"
LOGFILE="${HOST}.log"

# Задаем функции утилиты logger;
function logger () {
    echo -e "[$(date "+%H:%M:%S")]: $1" >> "${SCRIPT_DIR}/$LOGFILE"
}

logger_exit () {
    logger "--- $CURDATE - END: $HOST ---" ; echo >> "$SCRIPT_DIR/$LOGFILE" ; exit 1
}

# Очистка логов;
find "${SCRIPT_DIR}" -maxdepth 1 -name "$LOGFILE" -size +1M -exec rm -f {} \;

logger "--- $CURDATE - START: $HOST ---"

# Отправка почты;
send_mail () {
    if ! ping -c 3 "$CHECK_INET" > /dev/null; then
        logger "[-] [@send_mail] Have Internet Problems!" ; logger_exit
    else
        echo -e "${mail_body}" | mail -s "LSI - Raid: $HOST" -r "$MAIL_FROM" "$MAIL_DEST"
    fi
}

# Проверка доступности хостов + SSH Commands;
if ! ping -c 3 "$HOST" > /dev/null; then
    mail_body="[-] HOST: $HOST, unreachable."
    logger "${mail_body}"
    send_mail ; logger_exit
else
    if [ "$CMD_VERSION" = "esxi" ]; then
        cmd_VIRT_DRIVES="/opt/lsi/storcli/storcli /c0 /vall show"
    elif [ "$CMD_VERSION" = "linux" ]; then
        cmd_VIRT_DRIVES="/opt/MegaRAID/storcli/storcli64 /c0 /vall show"
    fi
    state_VIRT_DRIVES="$(sshpass -p "${SSH_PASS}" ssh "$LOGIN"@"$HOST" "${cmd_VIRT_DRIVES}")"
fi
# - #

# Получить значения необходимых параметров;
get_state () {
    cur_vds="$(echo "${state_VIRT_DRIVES}" | grep "${v_drive}" | awk '{print $2,$3,$11}')"
    read -r type state name <<< "$cur_vds"
    if [ -z $type ]; then type=":empty:" ; fi ; if [ -z $state ]; then state=":empty:" ; fi ; if [ -z $name ]; then name=":empty:" ; fi
}

# Проверка полученных значений;
check_state () {
    con_state="Condition [$type], virtual drive [$v_drive], name [$name]"
    if [ "$state" != "Optl" ]; then
        false_con_state="[-] ${con_state} - BAD :("
        logger "${false_con_state}"
        mail_body+="${false_con_state}\n"
    else
        true_con_state="[+] ${con_state} - Good!"
        logger "${true_con_state}"
        mail_body+="${true_con_state}\n"
    fi
}

interation="0"
for v_drive in "${VIRT_DRIVES[@]}"; do
    get_state
    check_state
    interation=$[ $interation + 1 ]
done

# Отправка логов на почту;
if [ "$NUMBER_VIRT_DRIVES" = "$interation" ]; then
    send_mail
fi

logger_exit