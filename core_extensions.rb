class Numeric
  def at_least(x)
    self < x ? x : self
  end
  
  def at_most(x)
    self > x ? x : self
  end
end

class String
  def snip(snip_at = 50, suffix = "...")
    if length > snip_at
      self[0..(snip_at-1)] + suffix
    else
      self
    end
  end
end