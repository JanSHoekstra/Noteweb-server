# frozen_string_literal: true

require 'httparty'

# Book object containing information about books
class Book
  def value_of(array, value)
    array.nil? || array[value].nil? ? '' : array[value]
  end

  def uri_to_json(uri)
    JSON.parse(HTTParty.get(URI(uri)).to_s) ? JSON.parse(HTTParty.get(URI(uri)).to_s) : ''
  rescue JSON::ParserError => e
    puts e
    ''
  end

  def set_goodreads_key
    goodreads_path = 'db/goodreads.json'
    if File.exist?(goodreads_path)
      goodreads_key = (JSON.parse(File.open(goodreads_path).read))['apikey']
    else
      puts 'Goodreads key not found! Please enter it below:'
      goodreads_key = gets.chomp
      Dir.mkdir('db') unless Dir.exist?('db')
      File.open(goodreads_path, 'w') { |f| f.write("{\"apikey\": \"#{goodreads_key}\"}") }
    end
    return goodreads_key
  end

  def get_rating(goodreads_key)
    # 'curl -X GET -F 'key=<key>' -F 'isbns=0824985990' -F 'format=json' https://www.goodreads.com/book/review_counts.json'
    unless @isbn == ''
      query = {
        'key': goodreads_key,
        'isbns': @isbn,
        'format': 'json'
      }
      goodreads_data = JSON.parse(HTTParty.get('https://www.goodreads.com/book/review_counts.json', :query => query).to_s)
      @rating = value_of(goodreads_data['books'][0], 'average_rating').to_f
    end
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
    @isbn = (value_of(book_data, 'isbn_10'))[0]
    get_rating(set_goodreads_key)
  end

  attr_reader :id, :title, :author_id, :author, :description, :subjects, :publish_date, :amazon_id, :amazon_link, :author_wiki, :book_wiki, :rating

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
