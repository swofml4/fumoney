module SimulationLib
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
    return asset_returns_shifted
  end

  def run_one_path(current_simulation,path_number, asset_types_map, correlation_matrix)
    #start with a collection of standard normal numbers with mu of 0 and sigma of 1
    #this allows shaping of the results by asset correlations
    #after adjusted for correlations, we will adjust the sigma and mu
    gen = Rubystats::NormalDistribution.new(0,1)
    asset_types = AssetType.all
    
    ruin_flag = 0.0 #this will be 0 or 1 so the simulation can sum the return values and get the num of times we hit zero
    portfolio_ending_value = 0.0
    portfolio_return_value = 0.0

    years_to_sim = current_simulation.last_simulation_age-current_simulation.starting_age
    current_path = current_simulation.paths.new(:path_title => path_number.to_s, :path_type => 'mc sim')
    last_portfolio = current_path.path_portfolios.new(:year => 0)
    #build the asset type map which will assign asset types to 0..N in a manner we can use consistently
    #get the correlation matrix <do these steps in the run and pass them as variables to path

    #multistep process to build asset returns. we create every year for every asset, which will be passed
    #year by year to the one year process. That process will pull asset returns as needed
    asset_returns_raw = Matrix.build(years_to_sim,asset_types.count) { gen.rng }
    
    asset_returns_shifted = build_adjusted_from_correlation_matrix(asset_returns_raw,asset_types_map,correlation_matrix)

    current_simulation.starting_assets.each do |starting_asset|
      last_portfolio.path_assets.new(:ending_amount => starting_asset.amount, 
        :asset_type_id => starting_asset.asset_type_id, :starting_amount => starting_asset.amount, :return_amount => 0, 
        :contributions_or_draw_amount => 0, :rebalance_amount => 0)
    end
    for years_out in 1..(years_to_sim)
      #refactor to run all years in fewer transactions
      # last_portfolio = run_one_year(current_simulation, current_path, last_portfolio, 
   #      years_out, asset_returns_shifted.row(years_out-1), asset_types_map)
      asset_returns = asset_returns_shifted.row(years_out-1)
      current_portfolio = current_path.path_portfolios.new(:year => years_out)
      portfolio_ending_value = 0.0
      portfolio_return_value = 0.0
      #calculate returns from last year's porfolio
      last_portfolio.path_assets.each do |asset|
        current_asset = current_portfolio.path_assets.new(:starting_amount => asset.ending_amount, 
          :asset_type_id => asset.asset_type_id)
        puts "~~~~~~~~~~~~~~~~~~starting amount: " + asset.ending_amount.to_s
        puts "~~~~~~~~~~~~~~~~~~year: " + years_out.to_s
        current_asset.return_amount = current_asset.starting_amount * asset_returns[asset_types_map[asset.asset_type_id][:order]] - current_asset.starting_amount
        
        portfolio_return_value += current_asset.return_amount + current_asset.starting_amount
      end

      #perform rebalancing and adds/draws
      if current_simulation.rebalance_flag == true
        #force everything back to rebalance amount
        current_simulation.target_allocations.each do |target_allocation|
          # tmp_asset = current_portfolio.path_assets.find_by(:asset_type_id => target_allocation.asset_type_id)
          tmp_asset = current_portfolio.path_assets.detect{|obj| obj.asset_type_id == target_allocation.asset_type_id}
          if tmp_asset.nil?          
            puts '~~~~~~~~~~~~~~~~~~ This should never happen now that I fixed starting assets'
            tmp_asset = current_portfolio.path_assets.new(:starting_amount => 0.0, 
              :asset_type_id => target_allocation.asset_type_id, :return_amount => 0.0)
          end
          tmp_asset.rebalance_amount = portfolio_return_value * target_allocation.allocation / 100.0 - tmp_asset.return_amount - tmp_asset.starting_amount
          if current_simulation.starting_age + years_out < current_simulation.retirement_age
            tmp_asset.contributions_or_draw_amount = 
              current_simulation.annual_contribution * (1.0 + current_simulation.contribution_growth/100.0)**years_out * target_allocation.allocation / 100.0
          else
            tmp_asset.contributions_or_draw_amount =  (-1.0) * current_simulation.retirement_draw * 
              (1 + current_simulation.retirement_draw_growth/100.0)**(years_out - current_simulation.retirement_age + current_simulation.starting_age) * 
              target_allocation.allocation / 100.0
          end
          tmp_asset.ending_amount = tmp_asset.contributions_or_draw_amount + tmp_asset.rebalance_amount + 
            tmp_asset.return_amount + tmp_asset.starting_amount
          if tmp_asset.ending_amount < 0
            tmp_asset.ending_amount = 0
          end
          portfolio_ending_value += tmp_asset.ending_amount
        end
      else
        #not rebalancing, allocate based on portfolio value
        current_portfolio.path_assets.each do |asset|
          asset.rebalance_amount = 0.0
          if current_simulation.starting_age + years_out < current_simulation.retirement_age
            asset.contributions_or_draw_amount = 
              current_simulation.annual_contribution * (1.0 + current_simulation.contribution_growth/100.0)**years_out * 
              (asset.starting_amount + asset.return_amount) / portfolio_return_value
          else
          	if portfolio_return_value == 0
          		asset.contributions_or_draw_amount = 0
          	else
	            asset.contributions_or_draw_amount =  (-1.0) * current_simulation.retirement_draw * 
	              (1 + current_simulation.retirement_draw_growth/100.0)**(years_out - current_simulation.retirement_age + current_simulation.starting_age) * 
	              (asset.starting_amount + asset.return_amount) / portfolio_return_value
	        end
          end
          asset.ending_amount = asset.contributions_or_draw_amount + asset.rebalance_amount + 
            asset.return_amount + asset.starting_amount
          if asset.ending_amount < 0
            asset.ending_amount = 0
          end
          portfolio_ending_value += asset.ending_amount
        end
      end
      
      if portfolio_ending_value == 0
        ruin_flag = 1.0
      end
      last_portfolio = current_portfolio
    end
    ActiveRecord::Base.transaction do
      current_path.save
    end
    return ruin_flag
  end
end