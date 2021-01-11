#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test/unit'
require_relative 'classes/users.rb'
require_relative 'classes/helper.rb'
require_relative 'classes/book.rb'

# Class containing all unit tests
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

  # Test to check if it's possible to remove registered users
  def test_del_user
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))

    assert_equal(true, u.del('testuser', 'Testp4ssword123!'))
  end

  # Test to check if changing passwords is possible on users
  def test_chpass
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))

    assert_equal(true, u.chpass('testuser', 'Testp4ssword123!', 'MyNewPassw0rd!'))

    assert_equal(false, u.login('testuser', 'Testp4ssword123!'))
    assert_equal(true, u.login('testuser', 'MyNewPassw0rd!'))
  end

  # Test to check if methods relating to book collections are working (CRUD)
  def test_book_collection
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))

    assert_equal(true, u.add_collection('testuser', 'New collection', ['OL26412312M']))
    assert_equal(false, u.add_book_to_collection('testuser', 'New collection', 'OL26412312M'))
    assert_equal(true, u.add_book_to_collection('testuser', 'New collection', 'OL18009471W'))

    assert_equal(true, u.chname_collection('testuser', 'New collection', 'Favorites'))

    assert_equal(true, u.del_collection('testuser', 'Favorites'))
  end

  # Test to validate if the value_of method is functioning as intended
  def test_value_of
    test1 = nil
    test2 = ''

    assert_equal('', value_of(test1, 0))
    assert_equal('', value_of(test2, 0))
  end

  # Test to validate if URIs can succesfully be parsed to JSON via the helper function
  def test_uri_to_json
    uri = 'http://ip.jsontest.com/'
    hash = uri_to_json(uri)
    assert_equal(false, value_of(hash, 'ip').nil?)
  end

  # Test to check if using the same password does not result in the same string of data being saved to the DB.
  # This should not be the case as a random salt is added before encryption.
  def test_salting_diff_same_pass
    u = Users.new
    assert_equal(true, u.add('testuser', 'Testp4ssword123!'))
    assert_equal(true, u.add('anotherTestUser', 'Testp4ssword123!'))

    assert_equal(false, u.users['testuser'][0] == u.users['anotherTestUser'][0])
  end

  # Test to validate if there's book data being returned from the OpenLibrary DB.
  def test_validate_book_data
    b = Book.new('OL26412312M')
    assert_equal(true, b.title == 'The bazaar of bad dreams')
    assert_equal(true, b.author == 'Stephen King')
    assert_equal(true, b.cover?)

    b = Book.new('OL145191W')
    assert_equal(true, b.title == 'Picasso')
    assert_equal(true, b.subjects.include?('Amsterdam (Netherlands)'))
    assert_equal(true, b.cover_img_small == 'https://covers.openlibrary.org/b/id/2238306-S.jpg')

    b = Book.new('OL8141930M')
    assert_equal(true, b.isbn.to_s == '0786806931')
    assert_equal(true, b.rating > 3.5 && b.rating < 5) if set_goodreads_key
    assert_equal(true, 'cover_id' == 544_129)
    assert_equal(true, b.publish_date == 'May 1, 2004')

    b = Book.new('OL24229110M')
    assert_equal(true, b.amazon_link == 'https://www.amazon.com/dp/0451149513')
  end

end
