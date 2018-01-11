# Takes a dirtied LibraryEntry and generates a list of LibraryEvents for the changes
class LibraryEventService
  # The change values to store in the event
  CHANGES_FOR_EVENT ||= {
    rated: %i[rating],
    progressed: %i[progress reconsume_count volumes_owned time_spent],
    updated: %i[status reconsume_count],
    reacted: %i[media_reaction_id],
    annotated: %i[notes]
  }.freeze

  # @param library_entry [LibraryEntry] the dirty LibraryEntry to figure out events for
  def initialize(entry)
    @entry = entry
  end

  # @return [Array<LibraryEvent>] a list of (unsaved) LibraryEvents generated by this changeset
  def events
    return [] if @entry.imported
    [rated_event, progressed_event, updated_event, reacted_event, annotated_event].compact!
  end

  def create_events!
    LibraryEvent.transaction { events.map(&:save!) }
  end

  private

  def rated_event
    event_for(:rated) if @entry.rating_changed?
  end

  def progressed_event
    if @entry.progress_changed? || @entry.reconsume_count_changed? || @entry.volumes_owned_changed?
      event_for(:progressed)
    end
  end

  def updated_event
    event_for(:updated) if @entry.status_changed?
  end

  def reacted_event
    event_for(:reacted) if @entry.media_reaction_id_changed?
  end

  def annotated_event
    event_for(:annotated) if @entry.notes_changed?
  end

  def event_for(kind)
    LibraryEvent.new(
      kind: kind,
      changed_data: @entry.changes.slice(CHANGES_FOR_EVENT[kind]),
      library_entry_id: @entry.id,
      anime_id: @entry.anime_id,
      manga_id: @entry.manga_id,
      drama_id: @entry.drama_id,
      user_id: @entry.user_id
    )
  end
end
