local settings_module = require(script.Parent.SETTINGS)

-- Enter new ids upon publication
local animation_ids = settings_module.AssetIds

local enemies_folder = workspace:WaitForChild("Enemies")
enemies_folder.ChildAdded:Connect(function(enemy : Model)
	
	enemy:GetAttributeChangedSignal("Animation"):Connect(function()
		local animator : Animator = enemy.Humanoid:WaitForChild("Animator")
		
		for _, anim : AnimationTrack in pairs(animator:GetPlayingAnimationTracks()) do
			local id = anim.Animation.AnimationId
			if id == animation_ids["Idle"] then
				continue
			end
			
			anim:Stop()
		end
		
		local animation_id = animation_ids[enemy:GetAttribute("Animation")]
		
		if animation_id == nil then
			return
		end
		
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. animation_id
		
		animator:LoadAnimation(animation):Play()
		
	end)
	
end)