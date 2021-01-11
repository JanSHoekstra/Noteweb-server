# Reading App Server
This is the server used for communication with the reading app that is built [here](https://www.github.com/tr4wzified/socialreadingapp).

## Installation
Run`bundle install` in the repo. Ruby 2.5.5+ is required. Also make sure to have `curl` installed via your favorite package manager or grab it from [here](https://curl.se/windows/) for Windows.

Download the repository (or clone it if you have Git: `git clone https://www.github.com/tr4wzified/SocialReadingAppServer`).

## Running the server
Run `ruby main.rb` in the repository directory. Access it on `127.0.0.1:2048`.

## Running the unit tests
Run `ruby run_tests.rb` in the repository directory.

## Running the fuzzer
Run `ruby fuzzer/fuzzaday.rb` in the repository directory. Make sure to start up the server itself before attempting to run this one.
