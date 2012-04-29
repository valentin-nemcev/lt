class PagesController < ApplicationController

  def main
    @tasks = Task::Mapper.fetch_all for_user: current_user
    @quote = current_user.quotes.find_random
  end

end
