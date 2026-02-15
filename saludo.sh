#!/bin/bash
#Tomamos las horas y minutos del dia y los pasamos a minutos en ($A)
#if then elif else if

HORALOCAL=$(date +%R)
HORA=$(date +%H)
MINUTOS=$(date +%M)


let A=10#$HORA*60+$MINUTOS

if [[ $A -ge 420 && $A -le 779 ]]
then
    echo "Buenos días"
elif [[ $A -ge 780 && $A -le 1269 ]]
then
    echo "Buenas tardes"
else
    echo "Buenas noches"
fi
