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
    [ $# -gt 0 ] && args=$@ || args=`otable`
    [ $? -eq 0 ] && ocmd 'select * from {} limit 10' $args
}
function odesc() {
    [ $# -gt 0 ] && args=$@ || args=`otable`
    [ $? -eq 0 ] && ocmd "desc {}" $args
}
function ocount() {
    [ $# -gt 0 ] && args=$@ || args=`otable`
    [ $? -eq 0 ] && ocmd 'count {}' $args
}
function ofields() {
    [ $# -gt 0 ] && args=$@ || args=`otable`
    [ $? -eq 0 ] && odesc $args | sed -e '1,/Field/d' -e '/+/d' | tr '|' ' ' | trim | grep .
}
function odownload() {
    postfix_list=(.`date +%F` .`date +%F.%T` .`date +%s` .txt .data .dat .csv)
    table=`otable` \
        && fields=(`ofields $table | fzf --header='Fields to download:' | awk '{print $1}'`) && [ ! -z "$fields" ] \
        && postfix=`echo ${(j:\n:)postfix_list} | fzf --header='Choose a postfix:'` \
        && threads=`seq 1 16 | fzf --header='Threads count:'` \
        && odpscmd -e "tunnel download ${table} ${table}${postfix} -cn ${(j:,:)fields} -threads ${threads}"
}
