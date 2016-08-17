class CorrelationCollectionsController < ApplicationController
  before_action :set_correlation_collection, only: [:show, :edit, :update, :destroy]

  # GET /correlation_collections
  # GET /correlation_collections.json
  def index
    @correlation_collections = CorrelationCollection.all
  end

  # GET /correlation_collections/1
  # GET /correlation_collections/1.json
  def show
  end

  # GET /correlation_collections/new
  def new
    @correlation_collection = CorrelationCollection.new
    @asset_types = AssetType.all
  end

  # GET /correlation_collections/1/edit
  def edit
    @asset_types = AssetType.all
  end

  # POST /correlation_collections
  # POST /correlation_collections.json
  def create
    @correlation_collection = CorrelationCollection.new(correlation_collection_params)

    respond_to do |format|
      if @correlation_collection.save
        format.html { redirect_to @correlation_collection, notice: 'Correlation collection was successfully created.' }
        format.json { render :show, status: :created, location: @correlation_collection }
      else
        format.html { render :new }
        format.json { render json: @correlation_collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /correlation_collections/1
  # PATCH/PUT /correlation_collections/1.json
  def update
    respond_to do |format|
      if @correlation_collection.update(correlation_collection_params)
        format.html { redirect_to @correlation_collection, notice: 'Correlation collection was successfully updated.' }
        format.json { render :show, status: :ok, location: @correlation_collection }
      else
        format.html { render :edit }
        format.json { render json: @correlation_collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /correlation_collections/1
  # DELETE /correlation_collections/1.json
  def destroy
    @correlation_collection.destroy
    respond_to do |format|
      format.html { redirect_to correlation_collections_url, notice: 'Correlation collection was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_correlation_collection
      @correlation_collection = CorrelationCollection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def correlation_collection_params
      params.require(:correlation_collection).permit(:title,
        {correlations_attributes: [:id, :correlation_amount, :asset_type1_id, :asset_type2_id, :_destroy]})
    end
end
