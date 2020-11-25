# frozen_string_literal: true

require 'httparty'

# Book object containing information about books
class Book
  def value_of(array, value)
    array.nil? || array[value].nil? ? '' : array[value]
  end

  def value_of_two(array, value, value2)
    array.nil? || array[value].nil? || array[value][value2].nil? ? '' : array[value][value2]
  end

  def initialize(ol_id)
    # Raw data
    uri = URI("https://openlibrary.org/works/#{ol_id}.json")
    work_data = JSON.parse(HTTParty.get(uri).to_s)

    uri = URI("https://openlibrary.org/books/#{ol_id}.json")
    book_data = JSON.parse(HTTParty.get(uri).to_s)

    # OpenLibrary ID
    @id = ol_id

    @title = value_of(work_data, 'title')
    @description = value_of(work_data['description'], 'value')
    @subjects = value_of(book_data, 'subjects')
    @publish_date = value_of(work_data, 'publish_date')

    # Author
    if work_data['authors']
      begin
        uri = URI("https://openlibrary.org#{work_data['authors'][0]['key']}.json")
        author_data = JSON.parse(HTTParty.get(uri).to_s)
      rescue
        uri = URI("https://openlibrary.org#{work_data['authors'][0]['author']['key']}.json")
        author_data = JSON.parse(HTTParty.get(uri).to_s)
      end
      @author = value_of(author_data, 'name')
      # remove /authors/ from /authors/<author_id>
      @author_id = author_data['key'].delete('/authors/')
    else
      @author = value_of(work_data, 'by_statement')
    end

    # Amazon link
    @amazon_id = value_of(value_of(work_data, 'identifiers'), 'amazon').to_s.delete '["]'
    if @amazon_id != ''
      @amazon_link = "https://www.amazon.com/dp/#{amazon_id}"
    else
      @amazon_link = ''
    end
  end

  attr_reader :id, :title, :author_id, :author, :description, :subjects, :publish_date, :amazon_id, :amazon_link

  def print_details
    puts "Id: #{@id}"
    puts "Title: #{@title}"
    puts "Description: #{@description}"
    puts "Author: #{@author}"
    puts "Author ID: #{@author_id}"
    puts "Subjects: #{@subjects}"
    puts "Publish Date: #{@publish_date}"
    puts "Amazon ID: #{@amazon_id}"
    puts "Amazon Link: #{@amazon_link}"
  end

  def to_hash
    Hash[instance_variables.map { |var| [var.to_s[1..-1], instance_variable_get(var)] }]
  end

end
