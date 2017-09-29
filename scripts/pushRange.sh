#!/bin/bash
#Usage: ./pushRange.sh day_num uname start end 'range' desk
uname=$2
day_num=$1
start_time=$3
end_time=$4
range_start=$5
range_end=$6
desk=$7

./ns_assign_shift.pl -d $uname -r "$range_start $range_end" -n $day_num -s $start_time -e $end_time -l $desk
