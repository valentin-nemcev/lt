class PagesController < ApplicationController

  def main
    @tasks = current_user.tasks
    @quote = current_user.quotes.find_random
  end

end
