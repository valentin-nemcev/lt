class PagesController < ApplicationController

  def main
    @quote = current_user.quotes.find_random
  end

end
