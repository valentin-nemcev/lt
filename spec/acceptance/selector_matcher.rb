module Capybara
  module Node
    module Matchers

      def does_not_match_selector?(*args)
        wait_until do
          parent.all(*args).all? do |node|
            self.native != node.native
          end or raise ExpectationNotMet
        end
      rescue Capybara::ExpectationNotMet
        return false
      rescue ::Selenium::WebDriver::Error::StaleElementReferenceError
        return true
      end

      def matches_selector?(*args)
        wait_until do
          parent.all(*args).any? do |node|
            self.native == node.native
          end or raise ExpectationNotMet
        end
      rescue Capybara::ExpectationNotMet
        return false
      rescue ::Selenium::WebDriver::Error::StaleElementReferenceError
        return false
      end

    end
  end
end

module Capybara
  module RSpecMatchers
    class MatchesSelector
      attr_reader :actual

      def initialize(*args)
        @args = args
      end

      def matches?(actual)
        @actual = wrap(actual)
        @actual.matches_selector?(*@args)
      end

      def does_not_match?(actual)
        @actual = wrap(actual)
        @actual.does_not_match_selector?(*@args)
      end

      def failure_message_for_should
        "expected #{selector_name} to match #{actual.inspect}"
      end

      def failure_message_for_should_not
        "expected #{selector_name} to not match #{actual.inspect}"
      end

      def description
        "matches #{selector_name}"
      end

      def selector_name
        name = "#{normalized.name} #{normalized.locator.inspect}"
        if normalized.options[:text]
          name << " with text #{normalized.options[:text].inspect}"
        end
        name
      end

      def wrap(actual)
        if actual.respond_to?("matches_selector?")
          actual
        else
          Capybara.string(actual.to_s)
        end
      end

      def normalized
        @normalized ||= Capybara::Selector.normalize(*@args)
      end
    end

    def match_selector(*args)
      MatchesSelector.new(*args)
    end

  end
end
