#!/bin/ruby

require_relative 'helpers'
require 'cgi'

puts 'Fuzzing login...'

name_s = 'username'
pass_s = 'password'
100.times { test_login(mutate!(name_s), mutate!(pass_s)) }

puts 'Fuzzing register...'

name_s = 'username'
pass_s = 'password'
100.times { test_register(mutate!(name_s), mutate!(pass_s)) }

#puts 'Registring fuzzing account...'
#register('fuzzyfuzzbuzz','Passw0rd!')
puts 'Logging in...'
login('fuzzyfuzzbuzz','Passw0rd!')

puts 'Fuzzing /user/*'
name_s = 'fuzzyfuzzbuzz'
100.times { accountmgmt(CGI.escape(mutate!(name_s)), 'fuzzyfuzzbuzz' ) }

puts 'Fuzzing /user/*/bookcollections'
name_s = 'fuzzyfuzzbuzz'
100.times { accountmgmt("#{CGI.escape(mutate!(name_s))}/bookcollection", 'fuzzyfuzzbuzz/bookcollection') }

puts 'Fuzzing '


