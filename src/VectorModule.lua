local module = {}

-- Returns angle between two vectors
function module.GetAngleBetweenVectors(v1 : Vector3, v2 : Vector3) : number
	return math.acos(v1:Dot(v2) / (v1.Magnitude * v2.Magnitude))
end

return module
