# frozen_string_literal: true

require 'httparty'

# Book object containing information about books
class Book
  def value_of(array, value)
    array.nil? || array[value].nil? ? '' : array[value]
  end

  def uri_to_json(uri)
    JSON.parse(HTTParty.get(URI(uri)).to_s)
  end


  def get_wiki(search)
    result = uri_to_json('https://en.wikipedia.org/w/api.php?action=opensearch&search=' + search)
    value_of(value_of(result, 3), 0)
  end

  def initialize(openlibrary_id)
    # Raw data
    work_data = uri_to_json("https://openlibrary.org/works/#{openlibrary_id}.json")
    book_data = uri_to_json("https://openlibrary.org/books/#{openlibrary_id}.json")
    @id = openlibrary_id
    @title = value_of(work_data, 'title')
    @description = value_of(work_data['description'], 'value')
    @subjects = value_of(book_data, 'subjects')
    @publish_date = value_of(work_data, 'publish_date')
    @amazon_id = value_of(value_of(work_data, 'identifiers'), 'amazon').to_s.delete '["]'
    @amazon_link = @amazon_id == '' ? '' : "https://www.amazon.com/dp/#{amazon_id}"

    # Getting author depends on the way it's stored in openlibrary
    if work_data['authors']
      begin
        author_data = uri_to_json("https://openlibrary.org#{work_data['authors'][0]['key']}.json")
      rescue
        author_data = uri_to_json("https://openlibrary.org#{work_data['authors'][0]['author']['key']}.json")
      end
      @author = value_of(author_data, 'name')
      # remove /authors/ from /authors/<author_id>
      @author_id = author_data['key'].delete('/authors/')
    else
      @author = value_of(work_data, 'by_statement')
    end

    @author_wiki = get_wiki(@author)
    @book_wiki = get_wiki(@title)
  end

  attr_reader :id, :title, :author_id, :author, :description, :subjects, :publish_date, :amazon_id, :amazon_link, :author_wiki, :book_wiki

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
