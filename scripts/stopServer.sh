#!/bin/bash

rubycheck=$(ps -e | grep -i ruby | wc -l)
if [ $rubycheck -eq 1 ]
then
        echo "Server has been stopped."
        pid=$(ps -e | grep -i ruby | { read a _; echo "$a"; })
        kill $pid
else
        echo "Server was not running."
fi

