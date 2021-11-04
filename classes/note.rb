# frozen_string_literal: true

require 'uri'
require 'json'
require_relative 'helper'

class Note
  def initialize(title, description)
    @title = title
    @description = description

    #@parents = []
    #@children = []
  end

  def as_json(options={})
    {
      title: @title,
      description: @description
    }
  end

  def to_json(*options)
    as_json(*options).to_json(*options)
  end

  attr_reader :id
  attr_accessor :title, :description
end
