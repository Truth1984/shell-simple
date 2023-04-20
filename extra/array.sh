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
    local -n print_data=$1;
    if ! [[ -z $2 ]]; then
        for i in "${!print_data[@]}"; do printf '[%s]: %s\n' "$i" "${print_data[$i]}"; done; 
    else
        i=0;
        while [ $i -lt ${print_data["__length__"]} ]; do
            printf "${print_data[$i]} "
            ((i++));
        done
        echo
    fi;
}

# (declare -A Object, declare -A Object)
mapSwap() {
    local -n mapswap_data=$1;
    local -n mapswap_data2=$2;
    declare -A mapswap_data3
    
    for i in "${!mapswap_data[@]}"; do mapswap_data3[$i]=${mapswap_data[$i]}; done;
    unset mapswap_data && declare -gA $1
    for i in "${!mapswap_data2[@]}"; do mapswap_data[$i]=${mapswap_data2[$i]}; done;
    unset mapswap_data2 && declare -gA $2
    for i in "${!mapswap_data3[@]}"; do mapswap_data2[$i]=${mapswap_data3[$i]}; done;
}

mapPrint(){
    local -n mapprint_data
    for i in "${!mapprint_data[@]}"; do printf "[%s]=%s\n" "$i" "${mapprint_data[$i]}" ; done
}