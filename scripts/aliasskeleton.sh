#!/bin/bash
#Usage: ./aliasskeleton.sh day_num uname start end desk
uname=$2
day_num=$1
start_time=$3
end_time=$4
desk=$5

./ns_assign_shift.pl -d $uname -t 'term year'  -n $day_num -s $start_time -e $end_time -l $desk
