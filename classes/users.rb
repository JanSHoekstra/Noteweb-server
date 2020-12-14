# frozen_string_literal: true

require 'json'
require 'rufus-scheduler'
require 'bcrypt'
require_relative 'bookcollection.rb'

# User class
class Users
  def initialize
    # Here we are initialising the variables.
    @users_path = 'db/users.json'
j   # Create empty json in db directory if those do not exist yet
    Dir.mkdir('db') unless Dir.exist?('db')
    File.open(@users_path, 'w') { |f| f.write('{}') } unless File.exist?(@users_path)
    @users = JSON.parse(File.open(@users_path).read)
    # For Windows, because Windows doesn't include timezones for whatever reason.
    ENV['TZ'] = 'Europe/Amsterdam'
    @scheduler = Rufus::Scheduler.new
    @changed_since_last_write = false
  end

  # Writes the users in memory to disk
  def write_users_to_file
    return unless @changed_since_last_write

    File.write(@users_path, JSON.pretty_generate(@users))
    puts "Time: #{Time.now} - Writing $users to file."
    @changed_since_last_write = false
  end

  # Specifies how often the users in memory should be written to disk
  def write_every(timeframe)
    @scheduler.every timeframe do
      write_users_to_file
    end
  end

  def exists?(name)
    @users.key?(name)
  end

  # Minimum 9 characters, maximum 64
  # Minimum 1 English uppercase + lowercase letter
  # Minimum 1 digit
  # Minimum 1 of these special characters - @$!%*?&
  # Must not include username
  def meets_requirements?(name, pass)
    pass.match?(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{9,64}$/) && !pass.include?(name)
  end

  # Adds a user with name and pass (is encrypted) to the DB
  def add(name, pass)
    return false if exists?(name) || !meets_requirements?(name, pass)

    encrypted_pass = BCrypt::Password.create(pass)
    @users[name] = [encrypted_pass, []]
    @changed_since_last_write = true
  end

  def del(name)
    @users.delete(name)
    @changed_since_last_write = true
  end

  def login(name, pass)
    exists?(name) && BCrypt::Password.new(@users[name][0]) == pass
  end

  def chpass(name, old_pass, new_pass)
    return false if !meets_requirements?(name, new_pass) || !login(name, old_pass)

    encrypted_pass = BCrypt::Password.create(new_pass)
    @users[name][0] = encrypted_pass
    @changed_since_last_write = true
  end

  def add_collection(name, collection_name, books = [])
    @users[name][1].each do |bc|
      return false if bc['name'] == collection_name
    end
    bc = BookCollection.new(collection_name, books.uniq)
    @users[name][1].push(bc.to_hash)
    @changed_since_last_write = true
  end

  def del_collection(name, collection_name)
    @users[name][1].each_with_index do |bc, i|
      if bc['name'] == collection_name
        @users[name][1].delete_at(i)
        @changed_since_last_write = true
      end
    end
  end

  def chname_collection(name, collection_name, new_collection_name)
    @users[name][1].each do |bc|
      bc['name'] = new_collection_name if collection_name == bc['name']
      @changed_since_last_write = true
    end
  end

  def get_collection(name, collection_name)
    @users[name][1].each do |bc|
      return bc if collection_name == bc['name']
    end
  end

  def add_book_to_collection(name, collection_name, book_id)
    @users[name][1].each do |bc|
      if collection_name == bc['name']
        return false if bc['books'].include?(book_id)

        bc['books'].push(book_id.to_s)
        @changed_since_last_write = true
      end
    end
  end

  def del_book_from_collection(name, collection_name, book_id)
    @users[name][1].each do |bc|
      if collection_name == bc['name']
        bc['books'].delete(book_id.to_s)
        @changed_since_last_write = true
      end
    end
  end

  attr_reader :users
end
