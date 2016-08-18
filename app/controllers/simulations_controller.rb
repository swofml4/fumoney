

class SimulationsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_simulation, only: [:show, :edit, :update, :destroy]
  before_action :set_cache_headers

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
        format.html { redirect_to simulations_manage_path, notice: 'Simulation is running, check back in a bit to see if it has completed' }
        format.json { render :results, status: :created, location: @simulation }

        @simulation.starting_assets.each do |starting_asset|
          if starting_asset.amount.nil?
            starting_asset.destroy
          elsif starting_asset.amount == 0
            starting_asset.destroy
          end
        end

        asset_types = AssetType.all
        asset_types_map = Hash.new
        i = 0
        asset_types.each do |asset_type|
          asset_types_map[asset_type.id] = {:order => i, :mu => 1.00 + asset_type.historical_average_return / 100.00, 
            :sigma => asset_type.historical_std_deviation / 100.00}
          i += 1
        end
        correlation_matrix = build_correlation_matrix(@simulation,asset_types_map)
        @simulation.number_of_paths.times do |i|
          run_one_path(@simulation, i, asset_types_map, correlation_matrix)
        end
        @simulation.simulation_status = 'completed'
        @simulation.save
      else
        format.html { redirect_to simulations_build_simulation_path, notice: 'Simulation not started due to invalid parameters.'  }
        format.json { render json: @simulation.errors, status: :unprocessable_entity }
      end
    end
  end

  def manage
  	@simulations = Simulation.all
  end

def results2
	@chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title({ :text=>"Combination chart"})
      f.options[:xAxis][:categories] = ['Apples', 'Oranges', 'Pears', 'Bananas', 'Plums']
      f.labels(:items=>[:html=>"Total fruit consumption", :style=>{:left=>"40px", :top=>"8px", :color=>"black"} ])      
      f.series(:type=> 'column',:name=> 'Jane',:data=> [3, 2, 1, 3, 4])
      f.series(:type=> 'column',:name=> 'John',:data=> [2, 3, 5, 7, 6])
      f.series(:type=> 'column', :name=> 'Joe',:data=> [4, 3, 3, 9, 0])
      f.series(:type=> 'spline',:name=> 'Average', :data=> [3, 2.67, 3, 6.33, 3.33])
    end
      @h = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text => "Population vs GDP For 5 Big Countries [2009]")
        f.xAxis(:categories => ["United States", "Japan", "China", "Germany", "France"])
        f.series(:name => "GDP in Billions", :yAxis => 0, :data => [14119, 5068, 4985, 3339, 2656])
        f.series(:name => "Population in Millions", :yAxis => 1, :data => [310, 127, 1340, 81, 65])

        f.yAxis [
          {:title => {:text => "GDP in Billions", :margin => 70} },
          {:title => {:text => "Population in Millions"}, :opposite => true},
        ]

        f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
        f.chart({:defaultSeriesType=>"column"})
      end
      	gen = Rubystats::NormalDistribution.new(50, 15)
 		gen.rng               # a single random sample
 		rnd_data = gen.rng(100)          # 100 random samples
 		@rngchart = LazyHighCharts::HighChart.new('graph') do |f|
 			f.title({ :text=>"Random Data chart"})
 			f.options[:xAxis][:categories] = (20..119).to_a
 			f.options[:xAxis][:title] = "Age"
 			f.series(:type=> 'spline',:name=> 'Return', :data=> rnd_data)
 		end
end

def results
  graph_log = false
  @simulations = Simulation.all
  if params[:simulation].nil?
    @simulation = Simulation.new
  else
    @ruin_paths = 0.0
    @simulation = Simulation.find(params[:simulation][:id])
    years_to_sim = @simulation.last_simulation_age-@simulation.starting_age
    money = Array.new(@simulation.number_of_paths){Array.new(years_to_sim+1)}
    median_money = Array.new(years_to_sim)
    percentile_up50 = Array.new(years_to_sim)
    percentile_up90 = Array.new(years_to_sim)
    percentile_down50 = Array.new(years_to_sim)
    percentile_down90 = Array.new(years_to_sim)
    temp_money = 0.0
    @simulation.paths.each do |path|
      path.path_portfolios.each do |portfolio|
        portfolio.path_assets.each do |asset|
          temp_money = temp_money + asset.ending_amount
        end
        if temp_money == 0 and graph_log
          temp_money = 0.001
        end
        money[path.path_title.to_i-1][portfolio.year] = temp_money
        temp_money = 0.0
      end
      if money[path.path_title.to_i-1].min <= 0.001
        @ruin_paths = @ruin_paths + 1
      end
    end
    money_transpose = money.transpose
    for k in 0..(years_to_sim)
      median_money[k] = 0.0
      stats = DescriptiveStatistics::Stats.new(money_transpose[k])
      percentile_up50[k] = stats.value_from_percentile(75)
      percentile_up90[k] = stats.value_from_percentile(95)
      median_money[k] = stats.median
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
      f.series(:type=> 'spline', :name=>'25th Percentile', :data=> percentile_down50,:showInLegend=>true, :enableMouseTracking=>true)
      f.series(:type=> 'spline', :name=>'10th Percentile', :data=> percentile_down90,:showInLegend=>true, :enableMouseTracking=>true)
    end
    @ruin_chance = (@ruin_paths / @simulation.paths.count * 100)
  end
end

def results3
	sim_count = 100
	years_to_sim = 70
	starting_money = 100000
	cumm_returns = Array.new(years_to_sim)
	money = Array.new(sim_count){Array.new(years_to_sim)}
	average_money = Array.new(years_to_sim)
	gen = Rubystats::NormalDistribution.new(1.09,0.15)
	for i in 0..(sim_count-1)
		rnd_data = gen.rng(years_to_sim)
		for j in 0..(years_to_sim-1)
			if j == 0
				cumm_returns[j] = rnd_data[j]
			else
				cumm_returns[j] = cumm_returns[j-1] * rnd_data[j]
			end
			if cumm_returns[j] < 0
				cumm_returns = 0
			end
			money[i][j] = (starting_money * cumm_returns[j]).round
		end
	end
	for k in 0..(years_to_sim-1)
		average_money[k] = 0
		for m in 0..(sim_count-1)
			average_money[k] = average_money[k] + money[m][k]
		end
		average_money[k] = (average_money[k] / sim_count).round
	end

	@rngchart = LazyHighCharts::HighChart.new('graph') do |f|
 		f.title({ :text=>"Random Stock Returns from $100k"})
 		f.yAxis({title: {text: "Portfolio Value", margin: 10}})
 		f.xAxis({title: {text: "Age", margin: 10}})
 		f.options[:yAxis][:type]='logarithmic'
 		f.options[:xAxis][:categories] = (30..100).to_a
 		for i in 0..(sim_count-1)
			f.series(:type=> 'spline', :name=>"path #{i}", :data=> money[i],:showInLegend=>false, :enableMouseTracking=>false, :color=>'#CCCCCC')
		end
		f.series(:type=> 'spline', :name=>"average portfolio", :data=> average_money,:showInLegend=>true, :enableMouseTracking=>true)
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
      :retirement_draw_growth, :risk_of_ruin, :simulation_status, :correlation_collection_id,
      {starting_assets_attributes: [:id, :amount, :asset_type_id, :_destroy]})
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

#Custom functions to run simulations
  def build_correlation_matrix(current_simulation, asset_types_map)
    #@correlation_matrix = Matrix[[1.0,0.8,0.2],[0.8,1.0,0.4],[0.2,0.4,1.0]]
    asset_count = asset_types_map.length
    #we default matrix to 1, as diagonals will not be explicitly defined (they are always 1)
    #if a correlation isnt defined, we assume a correlation of 1
    correlation_matrix = Matrix.build(asset_count, asset_count) { 1.00 }
    #overriding matrix [] being private. I get they have reasons, but for my use, so stupid
    current_simulation.correlation_collection.correlations.each do |correlation|
      correlation_matrix.send(:[]=,asset_types_map[correlation.asset_type1_id][:order], 
        asset_types_map[correlation.asset_type2_id][:order], correlation.correlation_amount / 100.00)
    end
    puts '~~~~~~~~~~~~~~~~CORRELATION MATRIX'
    puts correlation_matrix
    return correlation_matrix
  end

  def build_adjusted_from_correlation_matrix(asset_returns_raw, asset_types_map, correlation_matrix)
    #assume a cholesky decomp isnt possible, so we will do an eigensystem decomp
    v, d, v_inv = correlation_matrix.eigensystem
    #so, this is stupid, but something from sciruby broke fractional exponents
    #fortunately, on a diagonal matrix, this is trivial to do in a loop manually, which is what I am doing
    #@d will always be diagnoal from an eigensystem
    sqrt_d = Matrix.build(correlation_matrix.row_count,correlation_matrix.row_count) {0.00}
    for i in 0..(d.row_count-1)
      sqrt_d.send(:[]=,i, i,d[i,i] ** 0.5)
    end
    #correlate the random results
    asset_returns_correlated = (v * sqrt_d * asset_returns_raw.transpose).transpose
    #sigma mu shift results
    sigma_shift = Matrix.build(correlation_matrix.row_count,correlation_matrix.row_count) {0.00}
    for i in 0..(d.row_count-1)
      sigma_shift.send(:[]=,i, i,asset_types_map[asset_types_map.keys[i]][:sigma])
    end
    mu_shift = Matrix.build(asset_returns_raw.row_count ,asset_returns_raw.column_count) {0.00}
    for i in 0..(mu_shift.column_count-1)
      for j in 0..(mu_shift.row_count-1)
        mu_shift.send(:[]=,j, i,asset_types_map[asset_types_map.keys[i]][:mu])
      end
    end
    asset_returns_sigma_shifted = (asset_returns_correlated * sigma_shift)
    asset_returns_shifted = asset_returns_sigma_shifted + mu_shift
    #puts '~~~~~~~~~~~~~~~~~~~~~~~~~RAW RETURNS'
    #puts asset_returns_raw.to_a.map(&:inspect)
    #puts '~~~~~~~~~~~~~~~~~~~~~~~~~Corr RETURNS'
    #puts asset_returns_correlated.to_a.map(&:inspect)
    #puts '~~~~~~~~~~~~~~~~~~~~~~~~~Sigma Shift RETURNS'
    #puts asset_returns_sigma_shifted.to_a.map(&:inspect)
    #puts '~~~~~~~~~~~~~~~~~~~~~~~~~Shift RETURNS'
    #puts asset_returns_shifted.to_a.map(&:inspect)
    #puts '~~~~~~~~~~~~~~~~~~~~~~~~~MU'
    #puts mu_shift.to_a.map(&:inspect)
    #puts '~~~~~~~~~~~~~~~~~~~~~~~~~SigMA'
    #puts sigma_shift.to_a.map(&:inspect)
    return asset_returns_shifted
  end

  def run_one_path(current_simulation,path_number, asset_types_map, correlation_matrix)
    #start with a collection of standard normal numbers with mu of 0 and sigma of 1
    #this allows shaping of the results by asset correlations
    #after adjusted for correlations, we will adjust the sigma and mu
		gen = Rubystats::NormalDistribution.new(0,1)
    asset_types = AssetType.all
    
    
		years_to_sim = current_simulation.last_simulation_age-current_simulation.starting_age
		current_path = current_simulation.paths.create(:path_title => path_number.to_s, :path_type => 'mc sim')
		last_portfolio = current_path.path_portfolios.create(:year => 0)

    #build the asset type map which will assign asset types to 0..N in a manner we can use consistently
    #get the correlation matrix <do these steps in the run and pass them as variables to path

    #multistep process to build asset returns. we create every year for every asset, which will be passed
    #year by year to the one year process. That process will pull asset returns as needed
    asset_returns_raw = Matrix.build(years_to_sim,asset_types.count) { gen.rng }
    
    asset_returns_shifted = build_adjusted_from_correlation_matrix(asset_returns_raw,asset_types_map,correlation_matrix)

    current_simulation.starting_assets.each do |starting_asset|
      last_portfolio.path_assets.create(:ending_amount => starting_asset.amount, 
        :asset_type_id => starting_asset.asset_type_id, :starting_amount => starting_asset.amount, :return_amount => 0, 
        :contributions_or_draw_amount => 0, :rebalance_amount => 0)
    end
		for years_out in 1..(years_to_sim)
			last_portfolio = run_one_year(current_simulation, current_path, last_portfolio, 
        years_out, asset_returns_shifted.row(years_out-1), asset_types_map)
		end
  end

	#build the portfolio object and then the assets objects
	#simulate the returns for each and update the post return results
	#check if we should be doing adds or draws and do those based on target allocation
	#if we still have need, rebalance
	#save and return the current portfolio
	def run_one_year(current_simulation, current_path, last_portfolio, years_out, asset_returns, asset_types_map)
		current_portfolio = current_path.path_portfolios.create(:year => years_out)
		last_portfolio.path_assets.each do |asset|
			current_asset = current_portfolio.path_assets.create(:starting_amount => asset.ending_amount, :asset_type_id => asset.asset_type_id)
#This is wrong, need to link into an asset type map
      current_asset.return_amount = current_asset.starting_amount * asset_returns[asset_types_map[asset.asset_type_id][:order]]
      if current_asset.return_amount < 0 then
        current_asset.return_amount = 0
      end
#contributions and draws - gen 1 will do a pure pro rata, future will do these to align to target allocations
      if current_simulation.starting_age + years_out < current_simulation.retirement_age
        current_asset.contributions_or_draw_amount = current_asset.return_amount + 
          current_simulation.annual_contribution * (1 + current_simulation.contribution_growth/100)**years_out / current_simulation.starting_assets.count
      else
        current_asset.contributions_or_draw_amount = current_asset.return_amount - 
          current_simulation.retirement_draw * (1 + current_simulation.retirement_draw_growth/100)**(years_out - current_simulation.retirement_age + current_simulation.starting_age) /
          current_simulation.starting_assets.count
      end
      if current_asset.contributions_or_draw_amount < 0 then
        current_asset.contributions_or_draw_amount = 0
      end
#rebalancing todo
      current_asset.rebalance_amount = current_asset.contributions_or_draw_amount
#final ending balance for asset
      current_asset.ending_amount = current_asset.rebalance_amount
      current_asset.save
      #need to add to a matrix the portfolio return profile
			#later will need to simulate all the returns and then correlate them
		end
    return current_portfolio
		#create another loop to go through the assets and calc their return amount and the % off from target
	end

	def build_summary_paths(current_simulation)
	end


end
