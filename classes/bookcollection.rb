# frozen_string_literal: true

# Book Collection, owned by one user
class BookCollection
  def initialize(name, books = [])
    @name = name.to_s
    @books = books.uniq
  end

  def to_hash
    Hash[instance_variables.map { |var| [var.to_s[1..-1], instance_variable_get(var)] }]
  end

  def add(book_id)
    @books.add(book_id)
  end

  def del(book_id)
    @books.delete(book_id)
  end

  def chname(name)
    @name = name
  end

  attr_reader :books, :name
end
