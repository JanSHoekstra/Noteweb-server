# frozen_string_literal: true

require 'httparty'

require_relative 'helper'

# Book object containing information about books
class Book

  # Retrieve rating via Goodreads
  def get_rating(goodreads_key)
    return '' if @isbn == '' || @isbn.nil?

    query = {
      'key': goodreads_key,
      'isbns': @isbn,
      'format': 'json'
    }
    reviews = HTTParty.get('https://www.goodreads.com/book/review_counts.json', query: query)
    goodreads_data = JSON.parse(reviews.to_s)
    value_of(goodreads_data['books'][0], 'average_rating').to_f
  end

  def get_wiki(search)
    return '' if search.nil? || search == ''
    wiki_data = uri_to_json("https://en.wikipedia.org/w/api.php?action=opensearch&search=#{search.encode(Encoding.find('ASCII'), {:invalid => :replace, :undef => :replace, :replace => '', :universal_newline => true}).inspect}")
    value_of(value_of(wiki_data, 3), 0)
  end

  def author_data(work_data)
    authors = value_of(work_data, 'authors')
    if authors && authors[0] && (authors[0]['key'] || authors[0]['author']['key'])
      author_data = uri_to_json("https://openlibrary.org/#{authors[0]['key']}.json")
      author_data ||= uri_to_json("https://openlibrary.org/#{authors[0]['author']['key']}.json")
    else ''
    end
  end

  def populate_work_data(openlibrary_id)
    work_data = uri_to_json("https://openlibrary.org/works/#{openlibrary_id}.json")
    populate_author_data(work_data)
    @title = value_of(work_data, 'title')
    @description = value_of(work_data['description'], 'value')
    @publish_date = value_of(work_data, 'publish_date')
    @amazon_id = value_of(value_of(work_data, 'identifiers'), 'amazon').to_s.delete '["]'
    @amazon_link = @amazon_id == '' ? '' : "https://www.amazon.com/dp/#{amazon_id}"
    return work_data
  end

  def populate_book_data(openlibrary_id)
    book_data = uri_to_json("https://openlibrary.org/books/#{openlibrary_id}.json")
    @subjects = value_of(book_data, 'subjects')
    @isbn = value_of(value_of(book_data, 'isbn_10'), 0)
    @number_of_pages = value_of(value_of(book_data, 'notes'), 'number_of_pages')
    @rating = get_rating(set_goodreads_key)
    @id = openlibrary_id
  end

  def populate_author_data(work_data)
    author_data_var = author_data(work_data)
    @author = value_of(author_data_var, 'name')
    @author = value_of(work_data, 'by_statement') if @author == ''

    # remove /authors/ from /authors/<author_id>
    @author_id = value_of(author_data_var, 'key').delete('/authors/')
    @author_wiki = get_wiki(@author)
    @book_wiki = get_wiki(@title)
    @cover_id = value_of(value_of(work_data, 'covers'), 0)
    if @cover_id == ''
      @cover_img_small = ''
      @cover_img_medium = ''
      @cover_img_large = ''
    else
      @cover_img_small = "https://covers.openlibrary.org/b/id/#{@cover_id}-S.jpg"
      @cover_img_medium = "https://covers.openlibrary.org/b/id/#{@cover_id}-M.jpg"
      @cover_img_large = "https://covers.openlibrary.org/b/id/#{@cover_id}-L.jpg"
    end

    if @author_id == ''
      @author_img_small = ''
      @author_img_medium = ''
      @author_img_large = ''
    else
      @author_img_small = "https://covers.openlibrary.org/b/olid/#{@author_id}-S.jpg"
      @author_img_medium = "https://covers.openlibrary.org/b/olid/#{@author_id}-M.jpg"
      @author_img_large = "https://covers.openlibrary.org/b/olid/#{@author_id}-L.jpg"
    end
  end
  def initialize(openlibrary_id)
    populate_book_data(openlibrary_id)
    populate_author_data(populate_work_data(openlibrary_id))
  end

  attr_reader :id, :title, :author_id, :author, :description, :subjects,
              :publish_date, :amazon_id, :amazon_link, :author_wiki, :book_wiki, :rating, :isbn,
              :cover_id, :cover_img_small, :cover_img_medium, :cover_img_large, :author_img_small,
              :author_img_medium, :author_img_large, :number_of_pages

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
