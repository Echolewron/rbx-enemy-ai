local module = {}

local settings_module = require(script.Parent.SETTINGS)

module.Firerate = settings_module.WeaponFirerate
module.Damage = settings_module.WeaponDamage

local pathfind_module = require(script.Parent.PathfindingModule)
local query_module = require(script.Parent.QueryModule)
local raycast_module = require(script.Parent.RaycastModule)
local vector_module = require(script.Parent.VectorModule)
local table_module = require(script.Parent.TableModule)
local target_module = require(script.Parent.PlayerTargetScript.TargetControlModule)
local sound_module = require(script.Parent.SoundModule)

local tween = game:GetService("TweenService")

local cos = math.cos
local sin = math.sin
local pi = math.pi

local radius_step_size = 10
local radius_count = 3
local segment_count = 8

local segment_angle = 2 * pi / segment_count
local hide_bodyparts = {"LeftLowerArm", "RightLowerArm", "Head", "UpperTorso"}


function module.IsHidden(enemy_pos : Vector3, hide_from_list : {Player}) : boolean
	
	-- Checks if spot makes enemy invisible from players
	for _, target in pairs(hide_from_list) do
		local target_pos = target.Character.PrimaryPart.Position

		local obsturctions = raycast_module.Cubecast(target_pos, enemy_pos - Vector3.new(0, 1.25), Vector3.new(5, 2.5, 5), table_module.JoinTables({workspace.Pathway:GetChildren(), workspace.Enemies:GetChildren(), target.Character}))

		if #obsturctions < 9 then
			return false
		end
	end
	
	return true
end



function module.FindSafeSpot(enemy : Model, hide_from_list : {Player}) : Vector3?

	local enemy_pos = enemy.PrimaryPart.Position

	-- Enemy does not hide if it is already hidden
	if module.IsHidden(enemy_pos, hide_from_list) then
		return
	end


	for radius_step = 1, radius_count do
		for segment = 1, segment_count do

			-- Potential hide position, subject to check in later code
			local theta = segment_angle * segment
			local potential_pos = Vector3.new(cos(theta), 0, sin(theta)) * radius_step * radius_step_size + enemy_pos

			local skip_segment = false -- Determines if this segment fails to provide sufficient hiding spot
			
			potential_pos += Vector3.new(0, 20)
			local gravity_pos = raycast_module.Raycast(potential_pos, potential_pos - Vector3.new(0, -20), table_module.JoinTables({workspace.Pathway:GetChildren(), workspace.Enemies:GetChildren()}))
			
			if gravity_pos then
				potential_pos = gravity_pos.Position + Vector3.new(0, 2.5)
			else
				potential_pos -= Vector3.new(0, 20)
			end

			-- Checks if spot makes enemy invisible from players
			for _, target in pairs(hide_from_list) do
				local target_pos = target.Character.PrimaryPart.Position

				local obsturctions = raycast_module.Cubecast(target_pos, potential_pos + Vector3.new(0, 1.25), Vector3.new(5, 2.5, 5), table_module.JoinTables({workspace.Pathway:GetChildren(), workspace.Enemies:GetChildren(), target.Character}))

				if #obsturctions < 9 then
					skip_segment = true
					break
				end
			end

			-- Skips segment if it does not provide sufficient hideout
			if skip_segment then
				continue
			end

			-- Skips segment if enemy does not have access to it
			if not pathfind_module.FindPath(enemy_pos, potential_pos) then
				continue
			end

			return potential_pos
		end
	end
end





local function Hide(enemy : Model, targets : {Player}) : boolean
	local hiding_spot = module.FindSafeSpot(enemy, targets)
	
	if hiding_spot then
		enemy.Humanoid.WalkSpeed = settings_module.EnemyHidingSpeed
		pathfind_module.ThreadedMoveToGoal(enemy, hiding_spot)
		wait(math.random(1,5) / 5)
		return true
	else
		enemy:SetAttribute("Animation", "Prone")
		wait(math.random(1,3))
	end
	return false
end


local approach_proportion = settings_module.EnemyApproachDistance
local max_distance = 0 -- Enemy would not try to get closer than this
local function Approach(enemy : Model, targets : {Players}) : boolean
	
	local enemy_pos = enemy.PrimaryPart.Position
	
	if #targets == 0 then
		return false
	end
	
	local rand_target : Player = targets[math.random(1, #targets)]
	local rand_target_pos = rand_target.Character.PrimaryPart.Position
	
	if (enemy_pos - rand_target_pos).Magnitude <= max_distance then
		return false
	end
	
	local path = pathfind_module.FindPath(enemy_pos, rand_target_pos)
	
	if path == nil then
		return false
	end
	
	enemy.Humanoid.WalkSpeed = settings_module.EnemyApproachSpeed
	
	local waypoints = path:GetWaypoints()
	
	local approach_point : PathWaypoint = waypoints[math.ceil(#waypoints * approach_proportion)]
	
	pathfind_module.ThreadedMoveToGoal(enemy, approach_point.Position)
	
	return true
	
end


function module.EnemyLookAtPlayer(enemy : Model, player : Player)
	tween:Create(enemy.PrimaryPart, TweenInfo.new(0.2), {CFrame = CFrame.new(enemy.PrimaryPart.Position, player.Character.PrimaryPart.Position)}):Play()
end



function GetSufficientLean(enemy : Model, target : Player) : string?
	
	local sight_edge = raycast_module.RaycastSightEdge(enemy.Head, target.Character.PrimaryPart.Position, {enemy, target.Character})
	
	if sight_edge["Center"] then
		return "Center"
	elseif sight_edge["Right"] then
		return "Right"
	elseif sight_edge["Left"] then
		return "Left"
	end
end


function module.ShootSpecificTarget(enemy : Model, target : Player) : boolean
	
	if raycast_module.Raycast(enemy.Head.Position, target.Character.PrimaryPart.Position, {enemy, target.Character}) then
		return false
	end
	
	local lean = GetSufficientLean(enemy, target)
	
	
	
	if lean and lean ~= "Center" then
		enemy:SetAttribute("Animation", "Lean " .. lean)
	else
		enemy:SetAttribute("Animation", "Weapon Shoot")
	end
	
	
	module.EnemyLookAtPlayer(enemy, target)
	target.Character.Humanoid:TakeDamage(module.Damage)
	sound_module.CreateSound(settings_module.AssetIds.GunSoundId, enemy.PrimaryPart)

	return true
end


function module.ShootAllVisibleTargets(enemy : Model, targets : {Player})

	for _, target in pairs(targets) do
		if module.ShootSpecificTarget(enemy, target) then
			wait(1 / module.Firerate)
		end
	end

end


function module.ActivateAttack(enemy : Model, targets : {Player})
	
	enemy:SetAttribute("Action", "Attacking")
	
	local humanoid : Humanoid = enemy:FindFirstChild("Humanoid")
	
	
	local first_hide = false
	
	for _, target in pairs(targets) do
		target.Character.Humanoid.Died:Connect(function()
			table_module.RemoveItem(targets, target)
		end)
	end
	
	repeat
		if not first_hide then
			Hide(enemy, targets)
			first_hide = true
		else
			if Random.new(math.pi):NextNumber() < settings_module.EnemyHideDuringApproachChance then
				Hide(enemy, targets)
			end
		end
		
		enemy:SetAttribute("Animation", "Weapon Raise")
		
		Approach(enemy, targets)
		
		
		module.ShootAllVisibleTargets(enemy, targets)
	until #targets == 0
	
	wait(1.5)
	
	humanoid.WalkSpeed = settings_module.EnemyPatrolSpeed
	
	enemy:SetAttribute("Action", "Patroling")
	enemy:SetAttribute("PathID", "Continue")
	enemy:SetAttribute("Animation", "Idle")

end



return module