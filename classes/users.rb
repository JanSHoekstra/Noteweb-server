# frozen_string_literal: true

require 'json'
require 'rufus-scheduler'

# User class
class Users
  def initialize
    # Here we are initialising the variables .
    @users_path = 'db/users.json'
    @users = JSON.parse(File.open(@users_path).read)
    @scheduler = Rufus::Scheduler.new
    @changed_since_last_write = false
  end

  def write_users_to_file
    return unless @changed_since_last_write

    File.write(@users_path, JSON.pretty_generate(@users))
    puts 'Writing $users to file.'
    @changed_since_last_write = false
  end

  def write_every(timeframe)
    @scheduler.every timeframe do
      write_users_to_file
    end
  end

  def exists?(name)
    @users.key?(name)
  end

  def add(name, pass)
    @users[name] = [pass, 'salt']
    @changed_since_last_write = true
  end
end
