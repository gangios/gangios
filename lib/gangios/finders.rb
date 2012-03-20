module Gangios
  module Finders
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Define

      # define each
      def define_each(klass = nil, tag = nil)
        # get klass:Class from classname:String
        classname = self.to_s.chop
        if self.to_s.include? 'Summary' then
          klass = classname.to_class(Gangios::Base::Summary)
        else
          klass = classname.to_class(Gangios::Base)
        end

        tag = classname.split('::').last.upcase unless tag
        re_define_method :each do |options = {}, &block|
          @data.elements.each tag do |data|
            block.call klass.new :data => data
          end
        end
      end

      def define_all(request, xpath)
        # get klass:Class from classname:String
        classname = self.to_s + 's'
        if self.to_s.include? 'Summary' then
          klass = classname.to_class(Gangios::Base::Summary)
        else
          klass = classname.to_class(Gangios::Base)
        end

        re_define_class_method :all do |options = {}|
          klass.new GMetad.get_data request, xpath, options
        end
      end
    end
  end
end