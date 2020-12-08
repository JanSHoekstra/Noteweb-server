# frozen_string_literal: true

require 'httparty'
load 'classes/helper.rb'

# Book object containing information about books
class Book
  def set_goodreads_key
    goodreads_path = 'db/goodreads.json'

    if File.exist?(goodreads_path)
      return (JSON.parse(File.open(goodreads_path).read))['apikey']
    end

    puts 'Goodreads key not found! Please enter it below:'
    goodreads_key = gets.chomp
    Dir.mkdir('db') unless Dir.exist?('db')
    File.open(goodreads_path, 'w') { |f| f.write("{\"apikey\": \"#{goodreads_key}\"}") }
    goodreads_key
  end

  def get_rating(goodreads_key)
    # 'curl -X GET -F 'key=<key>' -F 'isbns=0824985990' -F 'format=json' https://www.goodreads.com/book/review_counts.json'
    return '' if @isbn == '' || @isbn.nil?

    query = {
      'key': goodreads_key,
      'isbns': @isbn,
      'format': 'json'
    }
    # 'No ISBNs specified.'
    reviews = HTTParty.get('https://www.goodreads.com/book/review_counts.json', query: query)
    goodreads_data = JSON.parse(reviews.to_s)
    value_of(goodreads_data['books'][0], 'average_rating').to_f
  end

  def get_wiki(search)
    wiki_data = uri_to_json("https://en.wikipedia.org/w/api.php?action=opensearch&search=#{search}")
    value_of(value_of(wiki_data, 3), 0)
  end

  def author_data(work_data)
    authors = value_of(work_data, 'authors')
    if authors && authors[0] && (authors[0]['key'] || authors[0]['author']['key'])
      author_data = uri_to_json("https://openlibrary.org/authors/#{authors[0]['key']}.json")
      author_data || uri_to_json("https://openlibrary.org/authors/#{authors[0]['author']['key']}.json")
    else ''
    end
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
    @author_wiki = get_wiki(@author)
    @book_wiki = get_wiki(@title)
    @isbn = value_of(value_of(book_data, 'isbn_10'), 0)
    @rating = get_rating(set_goodreads_key)

    # Getting author depends on the way it's stored in openlibrary
    author_data_var = author_data(work_data)
    @author = value_of(author_data_var, 'name')
    @author = value_of(work_data, 'by_statement') if @author == ''
    # remove /authors/ from /authors/<author_id>
    @author_id = value_of(author_data_var, 'key').delete('/authors/')
  end

  attr_reader :id, :title, :author_id, :author, :description, :subjects,
    :publish_date, :amazon_id, :amazon_link, :author_wiki, :book_wiki, :rating, :isbn

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
