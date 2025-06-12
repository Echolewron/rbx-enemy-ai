local pathfind_module = require(script.PathfindingModule)
local target_control_module = require(script.PlayerTargetScript.TargetControlModule)
local attack_module = require(script.AttackModule)
local spawn_module = require(script.SpawnModule)
local settings_module = require(script.SETTINGS)

local path_folder = workspace.Pathway -- Folder containing all nodes

local order_table = {} -- Sorted table with nodes

wait(3)

-- Sorts and stores nodes in order table
for _, node in pairs(path_folder:GetChildren()) do
	local node_order = node:FindFirstChild("Order") and node.Order.Value
	
	if node_order then
		order_table[node_order] = node
		node.Transparency = 1
	end
end


local enemies = {} -- contains all enemy characters

-- Spawns enemy at specified position
local spawn_locations = {} -- Previous spawn locations
for i = 1, #order_table do
	
	local this_node = order_table[i]
	local skip_spawn = false
	
	-- Checks if this node is too close to any previous spawn locations
	for _, spawn_pos in pairs(spawn_locations) do
		if (this_node.Position - spawn_pos).Magnitude <= spawn_module.min_distance then
			skip_spawn = true
			break
		end
	end
	
	-- Does not spawn at this node if it is too close to previous spawn location
	if skip_spawn then
		continue
	end
	
	
	table.insert(spawn_locations, spawn_module.SpawnEnemy(this_node.Position))
end


local function HigherRankEnemiesWithin(enemy : Model) : boolean
	
	for _, near_enemies in pairs(enemies) do
		if near_enemies:GetAttribute("ID") > enemy:GetAttribute("ID") and (near_enemies.PrimaryPart.Position - enemy.PrimaryPart.Position).Magnitude < 20 then
			return true
		end
	end
	
	return false
end


-- Each enemy goes to the next node

for _, this_enemy in pairs(workspace.Enemies:GetChildren()) do
	local targets_detected
	
	-- Patrolling
	local patrol_connection
	patrol_connection = this_enemy:GetAttributeChangedSignal("PathID"):Connect(function()
		
		-- Does not patrol if enemy is not in patroling mode
		if this_enemy:GetAttribute("Action") ~= "Patroling" then
			return
		end
		
		-- Unique id of current path, or its state
		local path_id = this_enemy:GetAttribute("PathID")
		
		local next_node
		if path_id == "Finished" then -- Next node if finished walking to target node
			next_node = this_enemy:GetAttribute("CurrentNode") % #order_table + 1
			
		elseif path_id == "Continue" then -- Continue walking to target node if walking was paused
			next_node = this_enemy:GetAttribute("CurrentNode")
		else
			return
		end
		
		this_enemy:SetAttribute("CurrentNode", next_node)
		
		-- Pathfind walking to the next node
		pathfind_module.CharacterMoveToGoal(this_enemy, order_table[next_node].Position)
	end)
	
	-- Initial "push" that activates enemy walking loop
	this_enemy:SetAttribute("PathID", "Finished")
	
	
	-- Target detection
	spawn(function()
		while wait(1) do
			
			if this_enemy:GetAttribute("Action") ~= "Patroling" then
				return
			end
			
			-- List of players that are detected by the enemy
			targets_detected = target_control_module.DetectTarget(this_enemy)
			
			-- Enemy begin attack mode whenever players are detected
			if #targets_detected > 0 then
				pathfind_module.Cancel(this_enemy)
				attack_module.ActivateAttack(this_enemy, targets_detected)
			end
			
			-- Waits until another enemy in front of self is far enough
			while HigherRankEnemiesWithin(this_enemy) do
				pathfind_module.Cancel(this_enemy)
				wait(2)
			end
			
			--[[
			elseif this_enemy:GetAttribute("PathID") == "Canceled" then
				wait(2)
				this_enemy:SetAttribute("PathID", "Continue")
			end
			]]
			
			
		end
	end)
end