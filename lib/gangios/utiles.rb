class Extra
end

class String
  def to_class(parent = Object)
    chain = self.split "::"
    klass = parent.const_get chain.shift
    return chain.size < 1 ? (klass.is_a?(Class) ? klass : nil) : chain.join("::").to_class(klass)
  rescue
    nil
  end
end

module Gangios
  module Define
    # Redefine the method. Will undef the method if it exists or simply
    # just define it.
    def re_define_method(name, &block)
      undef_method(name) if method_defined?(name)
      define_method(name, &block)
    end

    # Returns the metaclass or eigenclass so that i can dynamically
    # add class methods to active record models
    def metaclass
      class << self;
        self
      end
    end

    # the most important part
    def re_define_class_method(name, &block)
      #klass = self.to_s
      metaclass.instance_eval do
        undef_method(name) if method_defined?(name)
        define_method(name, &block)
      end
    end

    # the most important part
    def alias_class_method(new_name, old_name)
      #klass = self.to_s
      metaclass.instance_eval do
        alias_method new_name, old_name
      end
    end
  end
end