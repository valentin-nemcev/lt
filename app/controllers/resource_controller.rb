class ResourceController < ApplicationController

  def scope
    resource_name.to_s.classify.constantize
  end

  def model
    @model ||= scope
  end

  def set_collection collection
    instance_variable_set("@#{resource_name.to_s.pluralize}", collection)
  end

  def collection
    instance_variable_get("@#{resource_name.to_s.pluralize}")
  end

  def set_resource resource
    instance_variable_set("@#{resource_name.to_s}", resource)
  end

  def resource
    instance_variable_get("@#{resource_name.to_s}")
  end


  def with_resource
    set_resource model.find(params[:id])

    yield resource

    respond_to do |format|
      format.json { render json: resource }
    end
  end


  def index
    set_collection model.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: collection }
    end
  end

  def show
    set_resource model.find(params[:id])

    respond_to do |format|
      format.json { render json: resource }
    end
  end

  def create
    set_resource model.new(params[resource_name])

    respond_to do |format|
      if resource.save
        format.json { render json: resource, status: :created, location: resource }
      else
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    set_resource model.find(params[:id])

    respond_to do |format|
      if resource.update_attributes(params[resource_name])
        format.json { render json: resource, status: :ok }
      else
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    set_resource model.find(params[:id])
    resource.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

end
