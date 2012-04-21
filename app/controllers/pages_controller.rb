class PagesController < ApplicationController

  def main
    @tasks = TaskMapper.fetch_all for_user: current_user
    @quote = current_user.quotes.find_random
  end

end
