local module = {
	MinimumSpawnSpace = 60, -- Minimum distance between each enemy spawn
	WeaponDamage = 30, -- Total damage of 100 is required to kill a player
	WeaponFirerate = 2, -- Shots per second
	EnemyHideDuringApproachChance = 0.2, -- Chance that enemy decides to hide during each approachment towards the player
	EnemyApproachDistance = 0.35, -- How close should enemy approach target relative to full path between enemy and target
	EnemyPatrolSpeed = 4, -- How fast enemy walk during patrol
	EnemyHidingSpeed = 14, -- Enemy speed when hiding
	EnemyApproachSpeed = 8, -- How fast enemy moves when approaching a player
}

module.AssetIds = {
	GunSoundId = 1720824125,
	
	["Prone"] = 10206821854,
	["Idle"] = 10206825903,
	["Crouch"] = 10206828637,
	["Lean Left"] = 10206831782,
	["Lean Right"] = 10206830028,
	["Weapon Raise"] = 10206833219,
	["Weapon Shoot"] = 10206835920,
}

return module
