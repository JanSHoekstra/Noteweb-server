  def add_note(note, parentID)
    @notes[note.id] = note
  end

  def del_note(id)
    @notes.delete(id)
  end
