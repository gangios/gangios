class Extra
end

class String
  def to_class(parent)
    chain = self.split "::"
    klass = parent.const_get chain.shift
    return chain.size < 1 ? (klass.is_a?(Class) ? klass : nil) : chain.join("::").to_class(klass)
  rescue
    nil
  end
end