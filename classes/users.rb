# frozen_string_literal: true

require 'json'
require 'rufus-scheduler'
require 'bcrypt'

# User class
class Users
  def initialize
    # Here we are initialising the variables.
    @users_path = 'db/users.json'
    # Create empty json file if there is none
    File.new(@users_path, 'w').puts('{}') unless File.exist?(@users_path)
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

  # Adds a user with name and pass (is encrypted) to the DB
  def add(name, pass)
    return false if exists?(name)

    encrypted_pass = BCrypt::Password.create(pass)
    @users[name] = [encrypted_pass, encrypted_pass.salt]
    @changed_since_last_write = true
  end

  def login(name, pass)
    if exists?(name)
      return BCrypt::Password.new(@users[name][0]) == pass
    end
  end
end
