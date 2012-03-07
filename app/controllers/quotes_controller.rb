class QuotesController < ResourceController

  def resource_name
    :quote
  end

  def next_random
    set_resource = model.find_random(:after => params['after'])

    respond_to do |format|
      format.json { render json: resource }
    end
  end

end
