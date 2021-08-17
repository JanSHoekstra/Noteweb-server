# frozen_string_literal: true

require 'uri'

require_relative 'helper'


class Note

  def initialize(id, title, description)
    @id = id
    @title = title
    @description = description
  end

  attr_reader :id
  attr_accessor :title, :description
end
