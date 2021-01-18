# frozen_string_literal: true

require 'uri'

require_relative 'helper'

# Book object containing information about books
class Book

  def initialize(openlibrary_id, isbn = false)
    if isbn
      populate_book_data_isbn(openlibrary_id)
      populate_author_data(populate_work_data(@id))
    else
    populate_book_data(openlibrary_id)
    populate_author_data(populate_work_data(openlibrary_id))
    end
  end

  # Retrieve rating via Goodreads
  def get_rating(goodreads_key)
    return '' if @isbn.nil? || @isbn == '' || goodreads_key.nil? || goodreads_key == ''

    query = {
      'key': goodreads_key,
      'isbns': @isbn,
      'format': 'json'
    }

    goodreads_data = uri_to_json('https://www.goodreads.com/book/review_counts.json', query)
    value_of(value_of(value_of(goodreads_data, 'books'), 0), 'average_rating').to_f
  end

  $wiki_cache = {}
  def get_wiki(search)
    return '' if search.nil? || search == ''

    search = search.encode(Encoding.find('ASCII'), invalid: :replace, undef: :replace, replace: '', universal_newline: true).downcase

    current_time = Time.now
    return $wiki_cache[search][0] unless $wiki_cache[search].nil? || (current_time - $wiki_cache[search][1]) > 86_400

    query = { 'action': 'opensearch', 'search': search }
    wiki_data = uri_to_json('https://en.wikipedia.org/w/api.php', query)
    $wiki_cache[search] = [value_of(value_of(wiki_data, 3), 0), current_time]
    return $wiki_cache[search][0]
  end

  def author_data(work_data)
    authors = value_of(work_data, 'authors')
    if authors && authors[0]
      if !authors[0]['key'].nil? && authors[0]['key'] != ''
        uri_to_json("https://openlibrary.org/#{authors[0]['key']}.json")
      elsif !authors[0]['author'].nil? && authors[0]['author'] != ''
        uri_to_json("https://openlibrary.org/#{authors[0]['author']['key']}.json")
      end
    else ''
    end
  end

  def populate_work_data(openlibrary_id)
    work_data = nil
    if !@work_id.nil? && @work_id != ''
      work_data = uri_to_json("https://openlibrary.org/works/#{@work_id}.json")
    else
      work_data = uri_to_json("https://openlibrary.org/works/#{openlibrary_id}.json")
    end
    @title = value_of(work_data, 'title')
    @subjects = value_of(work_data, 'subjects') if @subjects.nil? || @subjects == ''
    @description = value_of(work_data, 'description') if @description.nil? || @description == ''
    @description = value_of(value_of(work_data, 'description'), 'value') if @description.nil? || @description == ''
    @publish_date = value_of(work_data, 'publish_date') if @publish_date.nil? || @publish_date == ''
    if @amazon_id.nil? || @amazon_id == ''
      @amazon_id = value_of(value_of(work_data, 'identifiers'), 'amazon').to_s.delete '["]'
      @amazon_link = @amazon_id == '' ? '' : "https://www.amazon.com/dp/#{@amazon_id}"
    end
    @cover_id = value_of(value_of(work_data, 'covers'), 0)
    @book_wiki = get_wiki(@title)

    # Checking for lower than 0 because OpenLibrary seems to use -1 sometimes for books with no covers? Weird API quirk. Example: /works/OL20759146W
    if @cover_id != '' && !@cover_id.negative?
      cover_request = Typhoeus::Request.new("https://covers.openlibrary.org/b/id/#{@cover_id}-S.jpg", params: { 'default': false }, followlocation: true, ssl_verifypeer: false)
      cover_request.on_headers do |response|
        if response.success?
          @cover_img_small = "https://covers.openlibrary.org/b/id/#{@cover_id}-S.jpg"
          @cover_img_medium = "https://covers.openlibrary.org/b/id/#{@cover_id}-M.jpg"
          @cover_img_large = "https://covers.openlibrary.org/b/id/#{@cover_id}-L.jpg"
        else
          @cover_img_small = ''
          @cover_img_medium = ''
          @cover_img_large = ''
        end
      end
      cover_request.run
    else
      @cover_img_small = ''
      @cover_img_medium = ''
      @cover_img_large = ''
    end
    return work_data
  end

  def populate_book_data(openlibrary_id)
    book_data = uri_to_json("https://openlibrary.org/books/#{openlibrary_id}.json")
    @subjects = value_of(book_data, 'subjects')
    @isbn = value_of(value_of(book_data, 'isbn_10'), 0)
    @isbn = value_of(value_of(book_data, 'isbn_13'), 0) if @isbn.nil? || @isbn == ''
    @number_of_pages = value_of(book_data, 'number_of_pages')
    @number_of_pages = value_of(value_of(book_data, 'notes'), 'number_of_pages') if @number_of_pages.nil? || @number_of_pages == ''
    @rating = get_rating(set_goodreads_key)
    @id = openlibrary_id
    @work_id = value_of(value_of(value_of(book_data, 'works'), 0), 'key').delete('/works/')
    @publish_date = value_of(book_data, 'publish_date')
    if value_of(value_of(book_data, 'source_records'), 0).include?('amazon:')
      @amazon_id = (value_of(value_of(book_data, 'source_records'), 0).delete 'amazon:')
      @amazon_link = (@amazon_id == '' ? '' : "https://www.amazon.com/dp/#{@amazon_id}")
    end
    if @amazon_id.nil? || @amazon_id == ''
      @amazon_id = value_of(value_of(book_data, 'identifiers'), 'amazon').to_s.delete '["]'
      @amazon_link = @amazon_id == '' ? '' : "https://www.amazon.com/dp/#{@amazon_id}"
    end
    @description = value_of(value_of(book_data, 'description'), 'value') if @description == '' || @description.nil?
    @description = value_of(book_data, 'description') if @description == '' || @description.nil?
  end

  def populate_book_data_isbn(isbn)
    book_data = uri_to_json("https://openlibrary.org/isbn/#{isbn}.json")
    @isbn = isbn
    @subjects = value_of(book_data, 'subjects')
    @number_of_pages = value_of(book_data, 'number_of_pages')
    @number_of_pages = value_of(value_of(book_data, 'notes'), 'number_of_pages') if @number_of_pages.nil? || @number_of_pages == ''
    @rating = get_rating(set_goodreads_key)
    @id = value_of(book_data, 'key').delete('/books/')
    @work_id = value_of(value_of(value_of(book_data, 'works'), 0), 'key').delete('/works/')
    @publish_date = value_of(book_data, 'publish_date')
    if value_of(value_of(book_data, 'source_records'), 0).include?('amazon:')
      @amazon_id = (value_of(value_of(book_data, 'source_records'), 0).delete 'amazon:')
      @amazon_link = (@amazon_id == '' ? '' : "https://www.amazon.com/dp/#{amazon_id}")
    end
    if @amazon_id.nil? || @amazon_id == ''
      @amazon_id = value_of(value_of(book_data, 'identifiers'), 'amazon').to_s.delete '["]'
      @amazon_link = @amazon_id == '' ? '' : "https://www.amazon.com/dp/#{@amazon_id}"
    end
    @description = value_of(value_of(book_data, 'description'), 'value') if @description == '' || @description.nil?
    @description = value_of(book_data, 'description') if @description == '' || @description.nil?
  end

  def populate_author_data(work_data)
    author_data_var = author_data(work_data)
    @author = value_of(author_data_var, 'name')
    @author = value_of(work_data, 'by_statement') if @author == ''

    # remove /authors/ from /authors/<author_id>
    @author_id = value_of(author_data_var, 'key').delete('/authors/')
    @author_wiki = get_wiki(@author)
  end


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
    puts "Cover Image Small: #{@cover_img_small}"
    puts "Cover Image Medium: #{@cover_img_medium}"
    puts "Cover Image Large: #{@cover_img_large}"
  end

  def to_hash
    Hash[instance_variables.map { |var| [var.to_s[1..-1], instance_variable_get(var)] }]
  end

  def cover?
    return @cover_img_small != ''
  end

  attr_reader :id, :title, :author_id, :author, :description, :subjects,
              :publish_date, :amazon_id, :amazon_link, :author_wiki, :book_wiki, :rating, :isbn,
              :cover_id, :cover_img_small, :cover_img_medium, :cover_img_large, :author_img_small,
              :author_img_medium, :author_img_large, :number_of_pages

  private :populate_book_data, :populate_work_data, :populate_author_data, :author_data, :get_wiki, :get_rating
end
