class UIStatesController < ApplicationController

  def show
    state = ui_state_of params[:id]

    render json: state.state
  end

  def update
    state = ui_state_of params[:id]

    state.state = params[:state]
    state.save!

    render json: state.state
  end
end
