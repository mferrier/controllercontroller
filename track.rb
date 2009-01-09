class Track
  def initialize(ref)
    @ref = ref
  end
  
  def ref
    @ref
  end
  
  def title
    ref.name.get
  end
  
  def artist
    ref.artist.get
  end
  
  def album
    ref.album.get
  end
  
  def time
    ref.time.get
  end
  
  def duration
    ref.duration.get
  end
  
  def description
    "#{artist} - #{title}"
  end
  
  def library_index
    ref.index.get
  end
end