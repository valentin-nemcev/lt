class PagesController < ApplicationController

  def main
    @tasks = Task.all
    @quote = Quote.find_random
  end
end
