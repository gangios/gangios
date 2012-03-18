module Gangios
  module Finders
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Redefine the method. Will undef the method if it exists or simply
      # just define it.
      def re_define_method(name, &block)
        undef_method(name) if method_defined?(name)
        define_method(name, &block)
      end

      # define each
      def define_each(klass, tag = nil)
        tag = klass.to_s.split('::').last.upcase unless tag
        re_define_method :each do |options = {}, &block|
          @data.elements.each tag do |data|
            block.call klass.new :data => data
          end
        end
      end
    end
  end
end