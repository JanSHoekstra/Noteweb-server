#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'

load '../classes/users.rb'

class UsersTest < Test::Unit::TestCase
  def test_register_login
    u = Users.new
    u.add('testuser', 'testpassword')
    assert_equal(true, u.login('testuser', 'testpassword'))
    assert_equal(false, u.login('faketestuser', 'testpassword'))
    assert_equal(false, u.login('testuser', 'faketestpassword'))
  end
end
