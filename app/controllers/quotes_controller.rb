class QuotesController < ApplicationController
  def index
    @quotes = Quote.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @quotes }
    end
  end

  def next_random
    @quote = Quote.find_random(:after => params['after'])

    respond_to do |format|
      format.json { render json: @quote }
    end
  end

  def show
    @quote = Quote.find(params[:id])

    respond_to do |format|
      format.json { render json: @quote }
    end
  end

  def create
    @quote = Quote.new(params[:quote])

    respond_to do |format|
      if @quote.save
        format.json { render json: @quote, status: :created, location: @quote }
      else
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @quote = Quote.find(params[:id])

    respond_to do |format|
      if @quote.update_attributes(params[:quote])
        format.json { render json: @quote, status: :ok }
      else
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @quote = Quote.find(params[:id])
    @quote.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end
end
