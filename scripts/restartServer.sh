#!/bin/bash

rubycheck=$(ps -e | grep -i ruby | wc -l)
if [ $rubycheck -eq 1 ]
then
        echo "Server has been restarted."
        pid=$(ps -e | grep -i ruby | { read a _; echo "$a"; })
        kill $pid
        ruby /home/henkdevries/socialreadingappserver/main.rb -p &
        disown -a
else
        echo "Server was not running, has been started now."
        ruby /home/henkdevries/socialreadingappserver/main.rb -p &
        disown -a
fi

