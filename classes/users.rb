# frozen_string_literal: true

require 'bcrypt'
require 'moneta'

require_relative 'helper'

# User class
class Users

  def initialize
    @users = Moneta.new(:GDBM, file: 'db/Noteweb-user.db')
  end

  # Returns whether a user exists
  def exists?(name)
    @users.key?(name)
  end

  # Minimum 9 characters, maximum 64
  # Minimum 1 English uppercase + lowercase letter
  # Minimum 1 digit
  # Minimum 1 of these special characters - @$!%*?&
  # Must not include username
  # Username may only contain alphanumeric characters or single hyphens, and cannot begin or end with a hyphen.
  def meets_requirements?(name, pass)
    name.match?(/^([a-z\d]+-)*[a-z\d]+$/i) && pass.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{9,64}$/) && !pass.include?(name)
  end

  # Collection may only contain alphanumeric characters and spaces
  def collection_meets_requirements?(collection_name)
    collection_name.match?(/^[a-zA-Z0-9 ]*$/)
  end

  # Adds a user with name and pass (is encrypted) to the DB
  def add(name, pass)
    return false if exists?(name) || !meets_requirements?(name, pass)
    encrypted_pass = BCrypt::Password.create(pass)
    @users[name] = [encrypted_pass, []]
  end

  def del(name, pass)
    return false if !login(name, pass)
    @users.delete(name)
  end

  def login(name, pass)
    exists?(name) && BCrypt::Password.new(@users[name][0]) == pass
  end

  def chpass(name, old_pass, new_pass)
    return false if !meets_requirements?(name, new_pass) || !login(name, old_pass)

    encrypted_pass = BCrypt::Password.create(new_pass)
    @users[name][0] = encrypted_pass
  end

  attr_reader :users
end
