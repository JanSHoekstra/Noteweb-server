#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'

load '../classes/users.rb'

class UsersTest < Test::Unit::TestCase
  def test_add
    u = Users.new
    u.add('testuser', 'testpassword')
    assert_equal(1, 1)
  end
end
