# frozen_string_literal: true

require 'httparty'

# Book object containing information about books
class Book
  def initialize(ol_id)
    # Raw data
    uri = URI('https://openlibrary.org/works/' + ol_id + '.json')
    response = HTTParty.get(uri)
    @work_data = JSON.parse(response.to_s)

    uri = URI('https://openlibrary.org/books/' + ol_id + '.json')
    response = HTTParty.get(uri)
    @book_data = JSON.parse(response.to_s)

    # OpenLibrary ID
    @id = ol_id

    # Title
    @title = @work_data['title'] unless @work_data['title'].nil?

    # Author
    if @work_data['authors'].nil?
      @author = @work_data['by_statement'] unless @work_data['by_statement'].nil?
      @author = @book_data['contributions'][0].gsub(/\(.*\)/, '') if @author.nil? && !@book_data['contributions'].nil?
    else
      uri = URI('https://openlibrary.org' + @work_data['authors'][0]['author']['key'].to_s + '.json')
      response = HTTParty.get(uri)
      @author_data = JSON.parse(response.to_s)
      @author = @author_data['name']
      # remove /authors/ from /authors/<author_id>
      @author_id = @work_data['authors'][0]['author']['key'].delete('/authors/')
    end

    # Description
    @description = @work_data['description']['value'] unless @work_data['description'].nil?

    # Subjects
    @subjects = @book_data['subjects'] unless @book_data['subjects'].nil?

    # Publish Date
    @publish_date = @work_data['publish_date'] unless @work_data['publish_date'].nil?

    # Amazon link
    unless @work_data['identifiers'].nil? || @work_data['identifiers']['amazon'].nil?
      @amazon_id = @work_data['identifiers']['amazon'].to_s
      amazon_id.delete! '["]'
      @amazon_link = 'https://www.amazon.com/dp/' + amazon_id
    end
  end

  attr_reader :id
  attr_reader :title
  attr_reader :author_id
  attr_reader :author
  attr_reader :description
  attr_reader :subjects
  attr_reader :publish_date
  attr_reader :amazon_id
  attr_reader :amazon_link

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
end
