function ocmd() {
    [ $# -lt 1 ] && return 1
    [ $# -gt 1 ] && args=${@:2} || tb='{}'
    echo "$args" | sed "s/'/\\\'/g" | xargs -i{} sh -c "odpscmd -e \"$1\" 2>/tmp/ocmd.stderr | grep . && echo"
}
function oupdate() {
    ocmd 'show tables' | grep . | cut -d : -f 2 > ~/.odps-tables
}
function otable() {
    ([ -f ~/.odps-tables ] || oupdate) && fzf --prompt="Table: " < ~/.odps-tables
}
function opartition() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && ocmd 'show partitions {}' $tb | sed "s/=\(.*\)/='\1'/g" | grep . | fzf --tac --prompt="Partition: "
}

function otdesc() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && ocmd "desc {}" $tb
}
function opdesc() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && pt=`opartition $tb` \
        && ocmd "desc $tb partition({})" $pt
}

function otcount() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && ocmd 'count {}' $tb
}
function opcount() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && pt=`opartition $tb` \
        && ocmd "count $tb partition({})" $pt
}

function __extract_size() {
    grep -Eo "Size: [0-9]+" | grep -Eo "[0-9]+" | numfmt --to=iec --suffix=B --round=nearest
}

function otsize() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && otdesc $tb | __extract_size
}
function opsize() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && pt=`opartition $tb` \
        && ocmd "desc $tb partition({})" $pt | __extract_size
}

function otpeek() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && ocmd 'select * from {} limit 10' $tb
}
function ofields() {
    [ $# -gt 0 ] && tb=$@ || tb=`otable`
    [ $? -eq 0 ] && otdesc $tb | sed -e '1,/Field/d' -e '/+/d' | tr '|' ' ' | trim | grep .
}
function otdownload() {
    postfix_list=(.`date +%F` .`date +%F.%T` .`date +%s` .txt .data .dat .csv)
    table=`otable` \
        && fields=(`ofields $table | fzf -m --prompt='Fields: ' | awk '{print $1}'`) && [ ! -z "$fields" ] \
        && filename=`echo $table | fzf --prompt='Filename: ' --print-query \
                | awk '$0~/^:/ || NR==2 {print $0}' | head -1 | sed 's/^://'` && [[ -n $filename ]] \
        && postfix=`echo ${(j:\n:)postfix_list} | fzf --prompt='Postfix: ' --print-query \
                | awk '$0~/^:/ || NR==2 {print $0}' | head -1 | sed 's/^://'` \
        && threads=`seq 1 16 | fzf --prompt='Threads: '` \
        && cmd="tunnel download $table $filename$postfix -cn ${(j:,:)fields} -threads $threads" \
        && odpscmd -e "$cmd"
}
function opdownload() {
    postfix_list=(.`date +%F` .`date +%F.%T` .`date +%s` .txt .data .dat .csv)
    table=`otable` \
        && partition=`opartition $table` \
        && fields=(`ofields $table | fzf -m --prompt='Fields: ' | awk '{print $1}'`) && [ ! -z "$fields" ] \
        && filename=`echo $table | fzf --prompt='Filename: ' --print-query \
                | awk '$0~/^:/ || NR==2 {print $0}' | head -1 | sed 's/^://'` && [[ -n $filename ]] \
        && postfix=`echo ${(j:\n:)postfix_list} | fzf --prompt='Postfix: ' --print-query \
                | awk '$0~/^:/ || NR==2 {print $0}' | head -1 | sed 's/^://'` \
        && threads=`seq 1 16 | fzf --prompt='Threads: '` \
        && cmd="tunnel download $table/$partition $filename$postfix -cn ${(j:,:)fields} -threads $threads" \
        && odpscmd -e "$cmd"
}
