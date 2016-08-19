class SimulationRunner
	extend SimulationLib

	@queue = :simulation_runner_queue

	def self.perform(simulation_id)
		sim = Simulation.find(simulation_id)
		ruin_path_count = 0.0
		#clean up if they sent us some crap
        #might get rid of this
        sim.starting_assets.each do |starting_asset|
          if starting_asset.amount.nil?
            starting_asset.destroy
          elsif starting_asset.amount == 0
            starting_asset.destroy
          end
        end

        #ensure that rebalancing is 100 based and create any assets they dont currently have that we will be
        #rebalancing into
        if sim.rebalance_flag == true
          total_rebalance_allocation = 0.0
          sim.target_allocations.each do |target_allocation|
            total_rebalance_allocation += target_allocation.allocation
          end
          if total_rebalance_allocation != 100
            sim.target_allocations.each do |target_allocation|
              target_allocation.allocation = target_allocation.allocation * 100 / total_rebalance_allocation
              target_allocation.save
            end
          end
          #check that all starting assets exist for targetting
          sim.target_allocations.each do |target_allocation|
            tmp_asset = sim.starting_assets.find_by(:asset_type_id => target_allocation.asset_type_id)
            if tmp_asset.nil?
              sim.starting_assets.create(:asset_type_id => target_allocation.asset_type_id, :amount => 0.0)
            end
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
        #space test
        correlation_matrix = build_correlation_matrix(sim,asset_types_map)
        sim.number_of_paths.times do |i|
          ruin_path_count += run_one_path(sim, i, asset_types_map, correlation_matrix)
          sim.simulation_status = (100.0 * i / sim.number_of_paths).round.to_s + '%'
          sim.save
        end
        sim.simulation_status = 'completed'
        sim.risk_of_ruin = ruin_path_count * 100.0 / sim.number_of_paths
        sim.save
	end
end