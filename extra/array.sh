#!/usr/bin/env bash

## usage: declare -A arr; array arr 1 2 3; arrayPrint arr;

# (declare -A Object, ...data) : ref 
array() {
    local -n data=$1;
    data["__type__"]="Array";
    data["__length__"]=0;
    data["__name__"]=$1;
    arrayAdd $@
}

# (declare -A Object, index) : ref 
arrayGet() {
    local -n data=$1;
    echo ${data[$2]}
}

# (declare -A Object, ...data) : ref 
arrayAdd() {
    local -n data=$1;
    for i in ${@:2:$#}; do
        index=${data["__length__"]}
        data[$index]=$i;
        ((data["__length__"]++));
    done;
}

arrayLength() {
    local -n data=$1;
    echo ${data["__length__"]}
}

# (declare -A Object, string) : -1 / index 
arrayIndexOf() {
    local -n data=$1;
    index=-1;
    i=0;
    while [ $i -lt ${data["__length__"]} ]; do
        if [ $2 = ${data[$i]} ]; then index=$i; break; fi;
        ((i++));
    done
    echo $index;
}

# (declare -A Object, function(value):string ) 
arrayCallback() {
    local -n data=$1;
    i=0;
    while [ $i -lt ${data["__length__"]} ]; do
        data[$i]=$($2 ${data[$i]});
        ((i++));
    done
}

# (declare -A Object, full?)
arrayPrint() {
    local -n data=$1;
    if ! [[ -z $2 ]]; then
        for i in "${!data[@]}"; do printf '[%s]: %s\n' "$i" "${data[$i]}"; done; 
    else
        i=0;
        while [ $i -lt ${data["__length__"]} ]; do
            printf "${data[$i]} "
            ((i++));
        done
        echo
    fi;
}
