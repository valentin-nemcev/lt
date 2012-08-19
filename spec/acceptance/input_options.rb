module Capybara
  module Node
    class Element
      def set_option(option)
        option = find :css, "[value='#{option}']",
          message: "option #{option.inspect} not found"
        if option.tag_name == 'option'
          option.select_option
        else
          option.set true
        end
      end

      def option_set
        all(:css, "[value]").select do |o|
          o.checked? || o.selected?
        end.first.try{ |o| o['value'] }
      end

      def options
        all(:css, '[value]').map{ |o| o['value'] }
      end
    end
  end
end
