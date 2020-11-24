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

    # Description
    @description = @work_data['description']['value'] unless @work_data['description'].nil?
    # Author
    @author = @work_data['by_statement'] unless @work_data['by_statement'].nil?
    @author = @book_data['contributions'][0].gsub(/\(.*\)/, "") if @author.nil? && !@book_data['contributions'].nil?

    # Subjects
    @subjects = @book_data['subjects'] unless @book_data['subjects'].nil?

    # Publish Date
    @publish_date = @work_data['publish_date'] unless @work_data['publish_date'].nil?

    # Amazon link
    @amazon_id = @work_data['identifiers']['amazon'].to_s unless @work_data['identifiers']['amazon'].nil?
    amazon_id.delete! '["]' if @amazon_id
    @amazon_link = 'https://www.amazon.com/dp/' + amazon_id unless @amazon_id.nil?

  end
  attr_reader :id
  attr_reader :title
  attr_reader :description
  attr_reader :author
  attr_reader :subjects
  attr_reader :amazon_id
  attr_reader :amazon_link

  def print_details
    puts "Id: #{@id}"
    puts "Title: #{@title}"
    puts "Description: #{@description}"
    puts "Author: #{@author}"
    puts "Subjects: #{@subjects}"
    puts "Publish Date: #{@publish_date}"
    puts "Amazon ID: #{@amazon_id}"
    puts "Amazon Link: #{@amazon_link}"
  end
end
