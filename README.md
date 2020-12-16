# Reading App Server
This is the server used for communication with the reading app that is built [here](https://www.github.com/tr4wzified/socialreadingapp).

## Requirements
### Server
The server requires the following packages:
- `sinatra`
- `sinatra-json`
- `sinatra-contrib`
- `openssl`
- `webrick`
- `bcrypt`
- `rufus-scheduler`
- `httparty`
- `addressable`
- `rack-throttle`
- `securerandom`
- `rack_encrypted_cookie`
- `slop`

### Windows-only
Windows has trouble with timezones when using rufus-scheduler, thus you should install the following package:
- `tzinfo-data`

### Fuzzer
If you want to run the fuzzer, it requires:
- `faraday`
- `faraday-cookie_jar`

### Unit Tests
You will need the unit testing package if you want to run them.
- `test-unit`

## Installation
Install the above packages with `gem install <package>`, assuming you have already installed Ruby (2.5.5+).

Download the repository (or clone it if you have Git: `git clone https://www.github.com/tr4wzified/SocialReadingAppServer`).

## Running the server
Run `ruby main.rb` in the repository directory. Access it on `127.0.0.1:2048`.

## Running the unit tests
Run `ruby run_tests.rb` in the repository directory.

## Running the fuzzer
Run `ruby fuzzer/fuzzaday.rb` in the repository directory.
