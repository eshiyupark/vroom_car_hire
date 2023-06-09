class VehiclesController < ApplicationController
  skip_before_action :authenticate_user!, only: :index
  before_action :set_user, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]

  def index
    @vehicles = policy_scope(Vehicle)
    if params.key?(:location)
      location = params[:location]
      vehicle = params[:vehicle]
      @vehicles = Vehicle.search_by_location_make_model("#{location} #{vehicle}") if params[:location] != "" || params[:vehicle] != ""
      @vehicles = @vehicles.search_by_transmission("automatic") if params[:automatic] == "1" && params[:manual] == nil
      @vehicles = @vehicles.search_by_transmission("manual") if params[:manual] == "1" && params[:automatic] == nil
    end

    # Geocoder logic below
    @markers = @vehicles.geocoded.map do |vehicle|
      {
        lat: vehicle.latitude,
        lng: vehicle.longitude,
        info_window_html: render_to_string(partial: "info_window", locals: {vehicle: vehicle}),
        marker_html: render_to_string(partial: "marker", locals: {vehicle: vehicle})
      }
    end
  end

  def new
    @vehicle = Vehicle.new
    authorize @vehicle
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)
    authorize @vehicle
    @vehicle.user = current_user

    respond_to do |format|
      if @vehicle.save
        format.html { redirect_to my_vehicles_path }
        format.json # Follow the classic Rails flow and look for a create.json view
      else
        format.html { render "my_vehicles/index", status: :unprocessable_entity }
        format.json # Follow the classic Rails flow and look for a create.json view
      end
    end
    # if @vehicle.save
    #   redirect_to vehicles_path
    # else
    #   render :new, status:
    #   :unprocessable_entity
    # end
  end

  def show
    authorize @vehicle
  end

  def edit
    authorize @vehicle
  end

  def update
    authorize @vehicle
    @vehicle.update(vehicle_params)
    redirect_to my_vehicles_path
  end

  def destroy
    authorize @vehicle
    @vehicle.destroy
    redirect_to my_vehicles_path, status: :see_other
  end

  private

  def set_user
    @user = current_user
  end

  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:make, :model, :year, :number_of_passengers, :transmission, :price_per_day, :location, :description, :user_id)
  end
end
