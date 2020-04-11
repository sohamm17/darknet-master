#!/bin/bash
set -e
set -o xtrace

HM=/home/common_shared/PAStime
LEN=$1

$HM/darknet-master/darknet folder_classify $HM/darknet-master/cfg/tiny.cfg\
 $HM/darknet-master/tiny.weights $HM/darknet-master/data/coco/converted1/\
 10 65 345 627 4446 1 345 627 &
sleep 2
