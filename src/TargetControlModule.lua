local players = game:GetService("Players")
local vector_module = require(script.Parent.Parent.VectorModule)

local module = {}

module.see_dist = 70 -- How far can enemies see targets
module.hear_dist = 10 -- How far can enemies hear targets, set 0 to turn off
module.fov = 160 -- Field of enemies' sight (measured in degrees)

-- Allows to make a certain player a valid target to enemies
function module.ChangeTargeting(player : Player, target_mode : boolean)
	
	if not player:IsA("Player") then
		return
	end
	
	player:SetAttribute("ValidTarget", target_mode) 
	
end

-- Checks if enemy can detect player
function module.DoesEnemyDetectTarget(enemy : Model, player : Player) : boolean

	local look_vector = enemy:FindFirstChild("Head") and enemy.Head.CFrame.lookVector
	local enemy_to_player_vector = player.Character.PrimaryPart.Position - enemy.PrimaryPart.Position
	
	-- Checks if enemy can hear player (including from behind)
	if enemy_to_player_vector.Magnitude <= module.hear_dist then
		return true
	end
	
	-- Checks if enemy can see player
	-- First checks if player is within field of sight
	-- Then checks if nothing obstructs enemy vision
	if enemy_to_player_vector.Magnitude <= module.see_dist and vector_module.GetAngleBetweenVectors(look_vector, enemy_to_player_vector) <= math.rad(module.fov) / 2 then
		local ray_origin = enemy.Head.Position
		
		local ray_params = RaycastParams.new()
		ray_params.FilterDescendantsInstances = {enemy}
		ray_params.FilterType = Enum.RaycastFilterType.Blacklist
		
		local ray_result = workspace:Raycast(ray_origin, enemy_to_player_vector, ray_params)
		
		if ray_result then
			local character_hit = ray_result.Instance:FindFirstAncestorWhichIsA("Model")
			local player_hit = players:GetPlayerFromCharacter(character_hit)
			
			return player_hit == player
		end
		
	end

	return false
end

module.Targets = {}

function module.DetectTarget(enemy: Model) : {Player}
	
	local enemy_id = enemy:GetAttribute("ID") -- ID of current enemy
	local target_list = {} -- list of players that it detects
	
	for _, this_player : Player in pairs(players:GetPlayers()) do

		if module.DoesEnemyDetectTarget(enemy, this_player) then
			table.insert(target_list, this_player)
		end
	end
	
	module.Targets[enemy_id] = target_list
	return target_list
	
end


return module
