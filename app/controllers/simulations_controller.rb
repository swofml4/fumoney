

class SimulationsController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!, except: [:index]
  before_action :set_simulation, only: [:show, :edit, :update, :destroy]
  before_action :set_cache_headers, only: [:results]

  def index
  end

  def build_simulation
  	@simulation = Simulation.new
    @asset_types = AssetType.all
    @correlation_collections = CorrelationCollection.all
  	@simulation.number_of_paths = 20
  	@simulation.last_simulation_age = 90
  	@simulation.retirement_draw_growth = 3
    #prefilled to make tests quicker
    @simulation.starting_age = 30
    @simulation.retirement_age = 60
    @simulation.annual_contribution = 10000
    @simulation.contribution_growth = 3
    @simulation.retirement_draw = 150000
  end

  def show
  end

  def sources #this is just a list of sources I used in building this
  end

  def matrix_test
    @correlation_matrix = Matrix[[1.0,0.8,0.2],[0.8,1.0,0.4],[0.2,0.4,1.0]]
    #@correlation_matrix = Matrix[[1,1,1],[1,1,1],[1,1,1]]
    @v, @d, @v_inv = @correlation_matrix.eigensystem
    @sqrt_d = Matrix.build(3,3) {0}
    for i in 0..(@d.column_count-1)
      @sqrt_d.send(:[]=,i, i,@d[i,i] ** 0.5)
    end
    @derrived_correlation_matrix = @v * @d * @v_inv
    gen = Rubystats::NormalDistribution.new(0.0,1.0)
    @normal_random = Matrix.build(100000,3) { gen.rng }
    @correlated_random = (@v * @sqrt_d * @normal_random.transpose).transpose
    ds = {'a'=>@correlated_random.column(0), 'b'=>@correlated_random.column(1),
      'c'=>@correlated_random.column(2)}.to_dataset
    @calculated_correlation_matrix = Statsample::Bivariate.correlation_matrix(ds)
  end

  def run_simulation
  	@simulation = Simulation.new(simulation_params)
  	@simulation.simulation_status = 'running'
    respond_to do |format|
      if @simulation.save
        #processing refactored into resque worker
        Resque.enqueue(SimulationRunner, @simulation.id)

        format.html { redirect_to simulations_manage_path, notice: 'Simulation is running, check back in a bit to see if it has completed' }
        format.json { render :results, status: :created, location: @simulation }
      else
        format.html { redirect_to simulations_build_simulation_path, notice: 'Simulation not started due to invalid parameters.'  }
        format.json { render json: @simulation.errors, status: :unprocessable_entity }
      end
    end
  end

  def manage
  	@simulations = Simulation.all.order(:id => :desc)
  end

  def results
    graph_log = false
    @simulations = Simulation.all.order(:id => :desc)
    if params[:simulation].nil?
      @simulation = Simulation.new
    else
      @simulation = Simulation.includes(paths: {path_portfolios: :path_assets}).find(params[:simulation][:id])
      years_to_sim = @simulation.last_simulation_age-@simulation.starting_age
      money = Array.new(@simulation.number_of_paths){Array.new(years_to_sim+1,0)}
      
      starting_assets = @simulation.starting_assets.all
      asset_types_map = Hash.new
      i = 0
      @simulation.starting_assets.each do |starting_asset|
        asset_types_map[starting_asset.asset_type_id] = {:order => i, :name => starting_asset.asset_type.name}
        i += 1
      end
      mean_asset_money = Array.new(asset_types_map.keys.count){Array.new(years_to_sim+1,0.0)}
      mean_asset_returns = Array.new(asset_types_map.keys.count){Array.new(years_to_sim+1,0.0)}

      median_money = Array.new(years_to_sim)
      mean_money = Array.new(years_to_sim)
      percentile_up50 = Array.new(years_to_sim)
      percentile_up90 = Array.new(years_to_sim)
      percentile_down50 = Array.new(years_to_sim)
      percentile_down90 = Array.new(years_to_sim)
      temp_money = 0.0
      @simulation.paths.each do |path|
        path.path_portfolios.each do |portfolio|
          portfolio.path_assets.each do |asset|
            temp_money = temp_money + asset.ending_amount
            mean_asset_money[asset_types_map[asset.asset_type_id][:order]][portfolio.year] += asset.ending_amount / @simulation.number_of_paths
            if asset.starting_amount == 0
              mean_asset_returns[asset_types_map[asset.asset_type_id][:order]][portfolio.year] += 0.0
            else
              mean_asset_returns[asset_types_map[asset.asset_type_id][:order]][portfolio.year] += 
                1.0 * asset.return_amount / asset.starting_amount / @simulation.number_of_paths
            end
          end
          if temp_money == 0 and graph_log
            temp_money = 0.001
          end
          money[path.path_title.to_i-1][portfolio.year] = temp_money
          temp_money = 0.0
        end
      end
      money_transpose = money.transpose
      for k in 0..(years_to_sim)
        median_money[k] = 0.0
        stats = DescriptiveStatistics::Stats.new(money_transpose[k])
        percentile_up50[k] = stats.value_from_percentile(75)
        percentile_up90[k] = stats.value_from_percentile(95)
        median_money[k] = stats.median
        mean_money[k] = stats.mean
        percentile_down50[k] = stats.value_from_percentile(25)
        percentile_down90[k] = stats.value_from_percentile(5)
      end

      @rngchart = LazyHighCharts::HighChart.new('graph') do |f|
        f.title({ :text=>@simulation.id.to_s + ': ' + @simulation.title})
        f.yAxis({title: {text: "Portfolio Value", margin: 10}})
        f.xAxis({title: {text: "Age", margin: 10}})
        if graph_log
          f.options[:yAxis][:type]='logarithmic'
        else
          f.options[:yAxis][:max]=median_money.max * 2
        end
        f.options[:xAxis][:categories] = (@simulation.starting_age..@simulation.last_simulation_age).to_a
        for i in 0..(@simulation.paths.count-1)
          f.series(:type=> 'spline', :name=>"path #{i}", :data=> money[i],:showInLegend=>false, :enableMouseTracking=>false, :color=>'#CCCCCC')
        end
        f.series(:type=> 'spline', :name=>'90th Percentile', :data=> percentile_up90,:showInLegend=>true, :enableMouseTracking=>true)
        f.series(:type=> 'spline', :name=>'75th Percentile', :data=> percentile_up50,:showInLegend=>true, :enableMouseTracking=>true)
        f.series(:type=> 'spline', :name=>'Median Portfolio', :data=> median_money,:showInLegend=>true, :enableMouseTracking=>true)
        f.series(:type=> 'spline', :name=>'Mean Portfolio', :data=> mean_money,:showInLegend=>true, :enableMouseTracking=>true)
        f.series(:type=> 'spline', :name=>'25th Percentile', :data=> percentile_down50,:showInLegend=>true, :enableMouseTracking=>true)
        f.series(:type=> 'spline', :name=>'10th Percentile', :data=> percentile_down90,:showInLegend=>true, :enableMouseTracking=>true)
      end

      @assetchart = LazyHighCharts::HighChart.new('graph') do |f|
        f.title({ :text=>'Mean Asset Ending Values'})
        f.yAxis({title: {text: "Portfolio Value", margin: 10}})
        f.xAxis({title: {text: "Age", margin: 10}})
        if graph_log
          f.options[:yAxis][:type]='logarithmic'
        end
        f.options[:xAxis][:categories] = (@simulation.starting_age..@simulation.last_simulation_age).to_a
        asset_types_map.each { |key,value|
          f.series(:type=> 'spline', :name=>value[:name], :data=> mean_asset_money[value[:order]],:showInLegend=>true, :enableMouseTracking=>true)
        }
      end

      @assetreturnchart = LazyHighCharts::HighChart.new('graph') do |f|
        f.title({ :text=>'Mean Asset Returns'})
        f.yAxis({title: {text: "Return Rate", margin: 10}})
        f.xAxis({title: {text: "Age", margin: 10}})
        if graph_log
          f.options[:yAxis][:type]='logarithmic'
        end
        f.options[:xAxis][:categories] = (@simulation.starting_age..@simulation.last_simulation_age).to_a
        asset_types_map.each { |key,value|
          f.series(:type=> 'spline', :name=>value[:name], :data=> mean_asset_returns[value[:order]],:showInLegend=>true, :enableMouseTracking=>true)
        }
      end
    end
  end

  def destroy
    @simulation.destroy
    respond_to do |format|
      format.html { redirect_to simulations_manage_url, notice: 'Simulation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  

private
# Use callbacks to share common setup or constraints between actions.
  def set_simulation
    @simulation = Simulation.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def simulation_params
    params.require(:simulation).permit(:id, :title, :number_of_paths, :starting_age, :retirement_age, 
      :last_simulation_age, :annual_contribution, :contribution_growth, :retirement_draw,
      :retirement_draw_growth, :risk_of_ruin, :simulation_status, :correlation_collection_id, :rebalance_flag,
      {starting_assets_attributes: [:id, :amount, :asset_type_id, :_destroy]},
      {target_allocations_attributes: [:id, :asset_type_id, :allocation, :_destroy]})
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end



# refactoring to reduce db transactions
	#build the portfolio object and then the assets objects
	#simulate the returns for each and update the post return results
	#check if we should be doing adds or draws and do those based on target allocation
	#if we still have need, rebalance
	#save and return the current portfolio
	def run_one_year(current_simulation, current_path, last_portfolio, years_out, asset_returns, asset_types_map)
# 		current_portfolio = current_path.path_portfolios.create(:year => years_out)
# 		last_portfolio.path_assets.each do |asset|
# 			current_asset = current_portfolio.path_assets.create(:starting_amount => asset.ending_amount, :asset_type_id => asset.asset_type_id)
# #This is wrong, need to link into an asset type map
#       current_asset.return_amount = current_asset.starting_amount * asset_returns[asset_types_map[asset.asset_type_id][:order]]
#       if current_asset.return_amount < 0 then
#         current_asset.return_amount = 0
#       end
# #contributions and draws - gen 1 will do a pure pro rata, future will do these to align to target allocations
#       if current_simulation.starting_age + years_out < current_simulation.retirement_age
#         current_asset.contributions_or_draw_amount = current_asset.return_amount + 
#           current_simulation.annual_contribution * (1 + current_simulation.contribution_growth/100)**years_out / current_simulation.starting_assets.count
#       else
#         current_asset.contributions_or_draw_amount = current_asset.return_amount - 
#           current_simulation.retirement_draw * (1 + current_simulation.retirement_draw_growth/100)**(years_out - current_simulation.retirement_age + current_simulation.starting_age) /
#           current_simulation.starting_assets.count
#       end
#       if current_asset.contributions_or_draw_amount < 0 then
#         current_asset.contributions_or_draw_amount = 0
#       end
# #rebalancing todo
#       current_asset.rebalance_amount = current_asset.contributions_or_draw_amount
# #final ending balance for asset
#       current_asset.ending_amount = current_asset.rebalance_amount
#       current_asset.save

# 		end
#     return current_portfolio
		#create another loop to go through the assets and calc their return amount and the % off from target
	end


  

	def build_summary_paths(current_simulation)
	end


end
