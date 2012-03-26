def flush
  $stdout.flush
end

# For debug
$debug = $stdout if $debug.kind_of? TrueClass
def debug info, linefeed = false, color = nil
  if $debug then
    color = :red if linefeed
    case color  
    when :red
      color = '31;1'
    when :green
      color = '32;1'
    when :yellow
      color = '33;1'
    when :blue
      color = '34;1'
    when :purple
      color = '35;1'
    when :sky
      color = '36;1'
    else 
      color = '34;1'
    end

    $debug << "\n" if linefeed
    $debug << "\e[#{color}m#{info.to_s}\e[0m\n"
    $debug.flush
  end
end 

class Extra
end

class Custom
end

class String
  # convert String to Class
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
      if method_defined? name then
        undef_method name
        debug "Method #{self}.#{name} exists, undef!"
      end
      define_method name, &block
      debug "Define method #{self}.#{name}"
    end

    # Define the method. Will not def the method if it exists or simply
    def safe_define_method(name, &block)
      if method_defined? name then
        debug "Method #{self}.#{name} exists, return!"
        return
      end
      define_method name, &block
      debug "Define method #{self}.#{name}"
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
        if method_defined? name then
          undef_method name
          debug "Class method #{self}.#{name} exists, undef!"
        end
        define_method name, &block
        debug "Define class method #{self}.#{name}"
      end
    end

    def safe_define_class_method(name, &block)
      #klass = self.to_s
      metaclass.instance_eval do
        if method_defined? name then
          debug "Class method #{self}.#{name} exists, return!"
          return
        end
        define_method name, &block
        debug "Define class method #{self}.#{name}"
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