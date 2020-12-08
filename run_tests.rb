#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require_relative 'classes/users.rb'
require_relative 'classes/helper.rb'
require_relative 'classes/book.rb'

class UnitTest < Test::Unit::TestCase
  # Test to check if requirements for passwords are working correctly when signing up for an account
  def test_meets_requirements
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))
    assert_equal(false, u.add('testuser', 'Testp4ssword123!'))
    assert_equal(false, u.add('BrrrTester', 'slechtww'))
  end

  # Test to check if a registered user can succesfully log in, and unregistered users are blocked.
  def test_login
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))

    assert_equal(true, u.login('testuser', 'Testp4ssword123!'))
    assert_equal(false, u.login('faketestuser', 'testpassword'))
    assert_equal(false, u.login('testuser', 'faketestpassword'))
  end

  # Test to check if using the same password does not result in the same string of data being saved to the DB - this should not be the case as a random salt is added before encryption
  def test_salting_diff_same_pass
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))
    assert_equal(true, u.add('anotherTestUser', 'Testp4ssword123!'))

    assert_equal(false, u.users['testuser'][0] == u.users['anotherTestUser'][0])
  end

  # Test to validate if there's book data being returned from the OpenLibrary DB.
  def test_validate_book_data
    b = Book.new('OL11077267W')
    assert_equal(true, b.title == 'Record to test what happens when you put a space at the endof a line')
    # include checks for author etc
  end


  # Test to validate if the value_of method is functioning as intended
  def test_value_of
    test1 = nil
    test2 = ''

    assert_equal('', value_of(test1, 0))
    assert_equal('', value_of(test2, 0))
  end
end
