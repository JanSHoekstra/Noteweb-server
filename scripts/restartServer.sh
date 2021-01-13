#!/bin/bash

rubycheck=$(ps -e | grep -i ruby | wc -l)
if [ $rubycheck -eq 1 ]
then
        pid=$(ps -e | grep -i ruby | { read a _; echo "$a"; })
        kill $pid
        ruby /home/henkdevries/socialreadingappserver/main.rb &
        disown -a
else
        ruby /home/henkdevries/socialreadingappserver/main.rb &
        disown -a
fi

