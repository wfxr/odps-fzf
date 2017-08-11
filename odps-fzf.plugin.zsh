function ocmd() {
    [ $# -lt 1 ] && return 1
    [ $# -gt 1 ] && args=${@:2} || args='{}'
    echo $args | xargs -i{} odpscmd -e "$1" 2>/tmp/ocmd.stderr | grep .
}
function oupdate() {
    ocmd 'show tables' | grep . | cut -d : -f 2 > ~/.odps-tables
}
function otable() {
    ([ -f ~/.odps-tables ] || oupdate) && fzf < ~/.odps-tables
}
function opeek() {
    [ $# -eq 0 ] && args=`otable` || args=$@
    ocmd 'select * from {} limit 10' $args
}
function odesc() {
    [ $# -eq 0 ] && args=`otable` || args=$@
    ocmd "desc {}" $args
}
function ocount() {
    [ $# -eq 0 ] && args=`otable` || args=$@
    ocmd 'count {}' $args
}
function ofields() {
    [ $# -eq 0 ] && args=`otable` || args=$@
    odesc $args | sed -e '1,/Field/d' -e '/+/d' | tr '|' ' ' | grep .
}
function odownload() {
    table=`otable`
    [ $? -ne 0 ] && return -1
    fields=`ofields $table | fzf --header='Fields to download:' | awk '{print $1}' 2>/dev/null`
    [ $? -ne 0 ] && return -1
    postfix_list=(.`date +%F` .`date +%F.%T` .`date +%s` .txt .data .dat .csv)
    postfix=`echo ${(j:\n:)postfix_list} | fzf --header='Choose a postfix:'`
    [ $? -ne 0 ] && return -1
    threads=`seq 1 16 | fzf --header='Threads count:'`
    [ $? -ne 0 ] && return -1
    odpscmd -e "tunnel download ${table} ${table}${postfix} -cn ${fields} -threads ${threads}"
}
