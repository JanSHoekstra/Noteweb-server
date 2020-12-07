#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require_relative 'classes/users.rb'
require_relative 'classes/helper.rb'
require_relative 'classes/book.rb'

class UnitTest < Test::Unit::TestCase
  def test_meets_requirements
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))
    assert_equal(false, u.add('testuser', 'Testp4ssword123!'))
    assert_equal(false, u.add('BrrrTester', 'slechtww'))
  end

  def test_login
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))

    assert_equal(true, u.login('testuser', 'Testp4ssword123!'))
    assert_equal(false, u.login('faketestuser', 'testpassword'))
    assert_equal(false, u.login('testuser', 'faketestpassword'))
  end

  def test_validate_book_data
    b = Book.new('OL11077267W')
    assert_equal(true, b.title == 'Record to test what happens when you put a space at the endof a line')
    # include checks for author etc
  end

  def test_value_of
    test1 = nil
    test2 = ''

    assert_equal('', value_of(test1, 0))
    assert_equal('', value_of(test2, 0))
  end
end
