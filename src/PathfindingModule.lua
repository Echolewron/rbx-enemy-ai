local module = {}


local pathfind = game:GetService("PathfindingService")


function module.FindPath(start : Vector3, goal : Vector3) : Path?
	
	local path : Path

	path = pathfind:CreatePath({
		AgentCanJump = false,
		WaypointSpacing = 5,
	})
	
	local success, feedback = pcall(function()
		return path:ComputeAsync(start, goal)
	end)
	
	
	if success and path.Status == Enum.PathStatus.Success then
		return path
	end

end


function module.CalculatePathLength(path : Path)
	
	local waypoints : {PathWaypoint} = path:GetWaypoints()
	local sum = 0
	
	for i = 2, #waypoints do
		sum = sum + (waypoints[i - 1].Position - waypoints[i].Position).Magnitude
	end
	
	return sum
	
end


local path_count = 0 -- counts how many times pathfinder was used, useful for canceling specific path


-- Cancels previously activated path for specified character
function module.Cancel(character : Model)
	if character:GetAttribute("PathID") == "Canceled" then
		return
	end
	
	local humanoid : Humanoid = character:FindFirstChild("Humanoid")
	character:SetAttribute("PathID", "Canceled")
	humanoid:MoveTo(character.PrimaryPart.Position)
	
end


-- Walks character to the next point without creating a separate thread
function module.ThreadedMoveToGoal(character : Model, goal : Vector3)
	
	path_count += 1
	local path_id = path_count
	
	local humanoid : Humanoid = character:FindFirstChild("Humanoid")
	character:SetAttribute("PathID", path_id)
	humanoid:MoveTo(character.PrimaryPart.Position) -- Cancels any previously activated :WalkTo() function

	-- Calculates & creates the path
	local path : Path
	local attempt = 5

	-- Tries to generate path again if unavailable
	repeat
		path = module.FindPath(character.PrimaryPart.Position, goal)
		attempt = attempt - 1
	until path or attempt == 0

	if attempt == 0 then
		return
	end

	local waypoints = path:GetWaypoints()
	local waypoint_index = 2
	
	for waypoint_index = 2, #waypoints do
		
		-- Allows canceling
		if character:GetAttribute("PathID") ~= path_id then
			return
		end
		
		local this_waypoint : PathWaypoint = waypoints[waypoint_index]
		
		humanoid.Jump = this_waypoint.Action == Enum.PathWaypointAction.Jump
		humanoid:MoveTo(this_waypoint.Position)
		humanoid.MoveToFinished:Wait()
		
	end
	
end


-- Activates path for specified character
function module.CharacterMoveToGoal(character : Model, goal : Vector3)
	
	path_count += 1
	local path_id = path_count
	
	local humanoid : Humanoid = character:FindFirstChild("Humanoid")
	character:SetAttribute("PathID", path_id)
	humanoid:MoveTo(character.PrimaryPart.Position) -- Cancels any previously activated :WalkTo() function

	-- Calculates & creates the path
	local path : Path
	local attempt = 5
	
	-- Tries to generate path again if unavailable
	repeat
		path = module.FindPath(character.PrimaryPart.Position, goal)
		attempt = attempt - 1
	until path or attempt == 0
	
	if attempt == 0 then
		return
	end
	
	local waypoints = path:GetWaypoints()
	local waypoint_index = 2
	
	path.Blocked:Connect(function()
		--print(character:GetAttribute("ID"))
	end)
	
	-- Character walks to the next waypoint as soon as finished walking to the previous
	local finished_connection : RBXScriptConnection
	finished_connection = humanoid.MoveToFinished:Connect(function(reached)
		
		-- Cancels path if a new path was initiated for this character
		if character:GetAttribute("PathID") ~= path_id then
			finished_connection:Disconnect()
			return
		end
		
		if reached then
			
			if waypoint_index < #waypoints then
				
				waypoint_index = waypoint_index + 1
				local next_waypoint : PathWaypoint = waypoints[waypoint_index]
				humanoid.Jump = next_waypoint.Action == Enum.PathWaypointAction.Jump
				humanoid:MoveTo(next_waypoint.Position)
				return
			
			else -- When character reached final destination
				
				character:SetAttribute("PathID", "Finished") -- ID of -1 means character finished walking its path
				finished_connection:Disconnect()
				
			end
			
			
		else
			
			-- Tries to walk again if character was interrupted
			finished_connection:Disconnect()
			module.CharacterMoveToGoal(character, goal)
			
		end
		
	end)
	
	
	humanoid:MoveTo(waypoints[waypoint_index].Position)
	
end





return module