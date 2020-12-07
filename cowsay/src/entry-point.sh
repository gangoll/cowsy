#!/bin/sh

path=/src
base=$pwd
if [ ! -z $1 ] ;
then 
export PORT=$1
cd $path
npm start  
else
    npm start 
fi
cd $base
