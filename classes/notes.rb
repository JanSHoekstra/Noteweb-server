# frozen_string_literal: true

require 'moneta'

class Notes

  def initialize
    @notes = Moneta.new(:GDBM, file: 'db/Noteweb--notes.db')
  end

  def add_note(note)
    #id = Time.now.to_f
    id = 0
    #unless @notes.key?(id)
      @notes[id] = note
    #end
  end

  def get_all_notes()
    @notes
  end

  def get_note(id)
    @notes[id]
  end

  def edit_note(id, note)
    @notes[id] = note
  end

  def del_note(id)
    @notes.delete(id)
  end

  def exist?(id)
    @notes.key?(id)
  end
end
