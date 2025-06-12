local module = {}

local table_module = require(script.Parent.TableModule)

function module.Raycast(start_pos : Vector3, end_pos : Vector3, ignore_list : {Instance}) : RaycastResult
	
	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Blacklist
	ray_params.FilterDescendantsInstances = ignore_list
	
	return workspace:Raycast(start_pos, end_pos - start_pos, ray_params)
	
end


local cube_corners = {
	{-1, -1, -1},
	{-1, -1, 1},
	{-1, 1, -1},
	{-1, 1, 1},
	{1, -1, -1},
	{1, -1, 1},
	{1, 1, -1},
	{1, 1, 1},
	{0,0,0}
}

-- Raycasts to the corners of specified cube
function module.Cubecast(start_pos : Vector3, end_pos : Vector3, cube_size : Vector3, ignore_list : {Instance}) : {Instance}
	
	local result : {Instance} = {}
	
	for _, corner in pairs(cube_corners) do
		
		local local_end_pos = end_pos + cube_size * Vector3.new(table.unpack(corner)) / 2
		
		local corner_result = module.Raycast(start_pos, local_end_pos, ignore_list)
		
		if corner_result then
			table.insert(result, corner_result.Instance)
		end
		
	end
	
	return result
end


function module.RaycastSightEdge(head : Part, lookAt_pos : Vector3, ignore_list : {Instance}) : {Instance?}
	
	local unit_size = 1
	local result = {
		["Left"] = nil,
		["Center"] = nil,
		["Right"] = nil,
	}
	
	local direction_numeration = {"Left", "Center", "Right"}
	
	for i = -1, 1 do
		
		local start_pos : Vector3 = head.CFrame.RightVector * unit_size * i + head.Position
		result[direction_numeration[i + 2]] = module.Raycast(start_pos, lookAt_pos, ignore_list) ~= nil
		
	end
	
	return result
	
end


return module