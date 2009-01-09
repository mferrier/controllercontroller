class Numeric
  def at_least(x)
    self < x ? x : self
  end
  
  def at_most(x)
    self > x ? x : self
  end
end