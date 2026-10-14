-- Services
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- NOTE: This is a Server Script - UserInputService is not available on server
-- Keyboard controls will be disabled (UserInputService only works in LocalScripts)
local UserInputService = nil

-- ERROR HANDLING: Print initialization message
print("[NexusActivator] Script initialized. Script type:", script.ClassName)
print("[NexusActivator] Script parent:", script.Parent and script.Parent.Name or "None")
if script.ClassName == "Script" then
	print("[NexusActivator] Running as Server Script - keyboard controls disabled (use LocalScript for keyboard controls)")
end

-- Utility aliases for common Roblox functions
local VT = Vector3.new
local CF = CFrame.new
local MRANDOM = math.random

-- Safely get script parent (optional - script can run without part for auto-spawn)
local NexusPart = nil
local ClickDetector = nil

if script and script.Parent then
	NexusPart = script.Parent
elseif script then
	-- Wait a frame for script to be properly initialized
	RunService.Heartbeat:Wait()
	if script.Parent then
		NexusPart = script.Parent
	end
end

-- Only create ClickDetector if part exists (for manual activation via clicking)
if NexusPart then
	local success, result = pcall(function()
		ClickDetector = Instance.new("ClickDetector")
		ClickDetector.Parent = NexusPart
		return ClickDetector
	end)
	if success then
		ClickDetector = result
		print("[NexusActivator] ClickDetector created successfully on:", NexusPart.Name)
	else
		warn("[NexusActivator] Failed to create ClickDetector:", result)
	end
else
	print("[NexusActivator] No NexusPart found - script will only work with auto-spawn")
end

local nexusInUse = false
local currentNexusPlayer = nil

-- CONFIGURATION: Optional player name to auto-spawn with Nexus powers
local AUTO_SPAWN_PLAYER_NAME = "BatteryRock_YT" -- Leave empty "" to disable, or put player username like what's in there currently

print("[NexusActivator] DEBUG: Variables initialized, AUTO_SPAWN_PLAYER_NAME =", AUTO_SPAWN_PLAYER_NAME)

print("[NexusActivator] DEBUG: About to declare SOUNDS table...")
-- SOUND CONFIGURATION TABLE
-- All sounds used in the script are defined here for easy management
local SOUNDS = {
	-- Intro sounds
	["intro_buildup"] = {
		id = 119750858019376,
		description = "Epic orchestral buildup/charge sound",
		baseVolume = 0.5,
		defaultPitch = 0.6
	},
	["intro_explosion"] = {
		id = 91592069647364,
		description = "Massive explosion sound",
		baseVolume = 0.5,
		defaultPitch = 0.4
	},

	-- Attack sounds
	["lightning_charge"] = {
		id = 9113629047,
		description = "Epic orchestral buildup/charge sound",
		baseVolume = 0.5,
		defaultPitch = 1.1
	},
	["lightning_crack"] = {
		id = 821439273,
		description = "Lightning/electric crack sound",
		baseVolume = 0.5,
		defaultPitch = 0.7
	},
	["cosmic_ambient"] = {
		id = 6038063555,
		description = "Cosmic/space ambient sound",
		baseVolume = 0.5,
		defaultPitch = 0.5
	},
	["explosion_impact"] = {
		id = 610359590,
		description = "Deep explosion/impact sound",
		baseVolume = 0.5,
		defaultPitch = 0.6
	},
	["dimensional_rift"] = {
		id = 4601466178,
		description = "Dimensional rift/portal sound",
		baseVolume = 0.5,
		defaultPitch = 0.5
	},
	["energy_beam"] = {
		id = 1177785010,
		description = "Energy beam/laser charging sound",
		baseVolume = 0.5,
		defaultPitch = 0.6
	},
	["reality_tear"] = {
		id = 2648563122,
		description = "Reality tear/fracture sound",
		baseVolume = 0.5,
		defaultPitch = 1.0
	},
	["fire_whoosh"] = {
		id = 108835547890095,
		description = "Fire/flame whoosh sound",
		baseVolume = 0.5,
		defaultPitch = 0.6
	},
	["time_distortion"] = {
		id = 17871250897,
		description = "Time distortion/slow effect sound",
		baseVolume = 0.5,
		defaultPitch = 0.8
	},
	["plasma_charge"] = {
		id = 115914702675886,
		description = "Plasma energy charging sound",
		baseVolume = 0.5,
		defaultPitch = 0.6
	},
	["ice_beam"] = {
		id = 632831227,
		description = "Ice beam/freeze ray sound",
		baseVolume = 0.5,
		defaultPitch = 0.7
	},
	["massive_explosion"] = {
		id = 107882121969514,
		description = "Massive explosion sound",
		baseVolume = 0.5,
		defaultPitch = 0.4
	},

	-- Chat system sounds
	["chat_typing"] = {
		id = 101572333845544,
		description = "Chat typing sound effect",
		baseVolume = 0.3,
		defaultPitch = 1.2
	},
	["chat_disappear"] = {
		id = 124018322190013,
		description = "Chat disappear sound effect",
		baseVolume = 0.6,
		defaultPitch = 0.8
	},
	["chat_appear"] = {
		id = 94059490149743,
		description = "Chat appear sound effect",
		baseVolume = 0.8,
		defaultPitch = 1.2
	},
}
print("[NexusActivator] DEBUG: SOUNDS table declared successfully")
-- Global volume multiplier for all sounds (adjust this to control overall volume)
-- Default: 0.3 (30% volume) - adjust higher or lower as needed
local GLOBAL_SOUND_VOLUME_MULTIPLIER = 0.3

print("[NexusActivator] DEBUG: About to define activateNexus function...")
local function activateNexus(targetPlayer)
	print("[NexusActivator] DEBUG: Inside activateNexus function!")
	-- Wait for character
	local CHARACTER = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
	local HUMANOID = CHARACTER:WaitForChild("Humanoid")
	local ROOTPART = CHARACTER:WaitForChild("HumanoidRootPart")
	local HEAD = CHARACTER:WaitForChild("Head")

	-- Core Variables
	local DEAD = false
	local Attack = false
	local CLASSIFICATION = "Boss"
	local BossGUI = nil
	local IntroPlayed = false
	local OutroPlayed = false
	local IdleEffectsActive = true

	-- Enhanced Settings
	HUMANOID.MaxHealth = 6000
	HUMANOID.Health = 6000

	-- DISABLE AUTO-HEAL SYSTEM
	local healthChangeConnection
	healthChangeConnection = HUMANOID.HealthChanged:Connect(function(health)
		if health > HUMANOID.Health and not DEAD then
			-- Prevent any health regeneration
			HUMANOID.Health = HUMANOID.Health
		end
	end)

	-- Also disable Roblox's built-in regeneration
	if HUMANOID.Parent:FindFirstChild("Health") then
		HUMANOID.Parent.Health:Destroy()
	end

	-- Taunt System
	local TauntGUI = nil
	local TauntDisplaying = false

	local IntroTaunts = {
		"Mortals... you dare awaken the NEXUS?",
		"Your pitiful existence ends NOW!",
		"Witness the power of cosmic devastation!",
		"I am eternal... you are DUST!",
		"Prepare to face your ANNIHILATION!"
	}

	local OutroTaunts = {
		"Impossible... how could mere mortals...",
		"The Nexus... cannot... be defeated...",
		"This is not... the end...",
		"My power... returning to the cosmos...",
		"Remember this day... I will return..."
	}

	local AttackTaunts = {
		Lightning = {
			"Feel the wrath of the storm!",
			"Lightning obeys MY will!",
			"Thunder shall be your dirge!",
			"The sky itself rejects you!",
			"Witness divine electrical fury!"
		},
		Meteor = {
			"The heavens rain destruction!",
			"Cosmic stones shall crush you!",
			"Meteorites answer my call!",
			"Space itself attacks you!",
			"Burning death from above!"
		},
		Dimensional = {
			"Reality bends to my power!",
			"Dimensional rifts tear you apart!",
			"The multiverse is my weapon!",
			"Portals of destruction open!",
			"Between worlds, you shall perish!"
		},
		Arcane = {
			"Ancient magic flows through me!",
			"Arcane energies obliterate all!",
			"Mystical forces converge!",
			"Magic itself serves the Nexus!",
			"Behold true sorcerous might!"
		},
		Inferno = {
			"Burn in eternal flames!",
			"Fire tornado of DOOM!",
			"Heat of a thousand suns!",
			"Infernal winds consume all!",
			"Blazing vortex of death!"
		},
		Cosmic = {
			"Universal forces align!",
			"Cosmic annihilation begins!",
			"Stars themselves explode!",
			"The universe is my arsenal!",
			"Galactic destruction unleashed!"
		},
		Quantum = {
			"Reality itself shall slice you!",
			"Quantum blades cut dimensions!",
			"Space-time tears before me!",
			"Molecular bonds shatter!",
			"Existence itself is severed!"
		},
		Stellar = {
			"Stars converge at my command!",
			"Stellar energy incinerates!",
			"Celestial bodies unite!",
			"Solar fury unleashed!",
			"Cosmic convergence begins!"
		},
		Void = {
			"The void hungers for you!",
			"Darkness consumes everything!",
			"Emptiness itself attacks!",
			"Void storms tear reality!",
			"Nothingness devours all!"
		},
		Plasma = {
			"Plasma nova erupts!",
			"Stellar core energy released!",
			"Superheated death awaits!",
			"Solar flare annihilation!",
			"Plasma burns through souls!"
		},
		Cryo = {
			"Freeze in eternal ice!",
			"Absolute zero approaches!",
			"Cryogenic death beam!",
			"Ice age begins NOW!",
			"Frozen in time forever!"
		},
		Finale = {
			"ALL ATTACKS COMBINED!",
			"ULTIMATE NEXUS DEVASTATION!",
			"CHAOS INCARNATE UNLEASHED!",
			"WITNESS TOTAL ANNIHILATION!",
			"THE END OF EVERYTHING!"
		}
	}

	-- AI Settings
	local AIMode = false
	local AISettings = {
		DetectionRange = 100,
		AttackRange = 30,
		AttackCooldown = 0.8,
		MovementSpeed = 25
	}

	local AIState = {
		CurrentTarget = nil,
		LastAttackTime = 0
	}

	-- Player Stomp System
	local PlayerStompDamage = 45
	local PlayerStompCooldown = 40
	local PlayerStompRange = 10
	local PlayerLastStompTime = {}

	-- MINION HIRE SYSTEM
	local MinionConfig = {
		Active = false,
		Minions = {},  -- {userId = {Player, RootPart, Humanoid, Rope, RecruitedBy, RecruitedMinions = {}}}
		Connections = {},
		MinionGUIs = {},
		TouchDebounce = {}
	}

	local MINION_TOUCH_COOLDOWN = 1  -- Cooldown for minion recruitment
	local ROPE_COLOR = Color3.fromRGB(150, 0, 255)  -- Purple rope

	local MinionTaunts = {
		"I serve the Nexus now...",
		"Join us... embrace the power...",
		"The Nexus is eternal...",
		"Resistance is futile...",
		"Become one with the Nexus...",
		"Power beyond comprehension...",
		"Submit to the Nexus...",
		"We are legion...",
		"The Nexus commands...",
		"Your will is ours..."
	}

	-- INFECTION SYSTEM CONFIGURATION
	local InfectionConfig = {
		Active = false,
		InfectedPlayers = {},  -- {userId = true}
		CloneGUIs = {},  -- {userId = screenGui}
		CloneConnections = {}  -- {userId_key = connection}
	}

	local CloneTaunts = {
		"I am a Nexus clone...",
		"The Nexus controls me...",
		"Join the infection...",
		"We are one...",
		"Nexus power flows through me...",
		"Resistance is futile...",
		"I serve the Nexus...",
		"The infection spreads...",
		"Become one of us...",
		"Nexus will consume all..."
	}

	-- NPC ENEMY SYSTEM FOR FINALE
	local NPCConfig = {
		Active = false,
		NPCs = {},  -- {npcId = {Model, Humanoid, RootPart, Target, LastAttackTime}}
		NPCConnections = {},
		NextNPCId = 1
	}

	local CurrentFinalePhase = 0  -- Track current finale phase for minion abilities

	-- STATUS EFFECT SYSTEM FOR BALANCE
	local StatusEffects = {
		Stun = {
			Name = "Stun",
			Color = Color3.fromRGB(255, 255, 0),
			Duration = 2,
			Effect = function(character, humanoid)
				if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false) end
			end,
			OnRemove = function(character, humanoid)
				if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true) end
			end
		},
		Burn = {
			Name = "Burn",
			Color = Color3.fromRGB(255, 100, 0),
			Duration = 4,
			DamagePerTick = 5,
			TickRate = 0.5
		},
		Freeze = {
			Name = "Freeze",
			Color = Color3.fromRGB(100, 200, 255),
			Duration = 3,
			Effect = function(character, humanoid)
				if humanoid then humanoid.WalkSpeed = 0 end
			end,
			OnRemove = function(character, humanoid)
				if humanoid then humanoid.WalkSpeed = 16 end
			end
		},
		Slow = {
			Name = "Slow",
			Color = Color3.fromRGB(0, 100, 255),
			Duration = 5,
			Effect = function(character, humanoid)
				if humanoid then humanoid.WalkSpeed = humanoid.WalkSpeed * 0.4 end
			end
		},
		Weakness = {
			Name = "Weakness",
			Color = Color3.fromRGB(200, 0, 100),
			Duration = 6,
			DamageMultiplier = 1.5  -- Takes 50% more damage
		},
		Blind = {
			Name = "Blind",
			Color = Color3.fromRGB(50, 50, 50),
			Duration = 4,
			Effect = function(character, humanoid)
				-- Create dark overlay
				local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
				if humanoidRoot then
					local camera = workspace.CurrentCamera
					local blindPart = Instance.new("Part")
					blindPart.CanCollide = false
					blindPart.Transparency = 0.3
					blindPart.Color = Color3.new(0, 0, 0)
					blindPart.Shape = Enum.PartType.Ball
					blindPart.Size = VT(1000, 1000, 1000)
					blindPart.Parent = humanoidRoot
					blindPart.CanQuery = false
					Debris:AddItem(blindPart, 4)
				end
			end
		},
		Levitate = {
			Name = "Levitate",
			Color = Color3.fromRGB(150, 100, 255),
			Duration = 3,
			Effect = function(character, humanoid)
				if humanoid then humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end
			end
		}
	}

	-- Apply status effect to a character

	local NPCTypes = {
		DarkHerald = {
			Name = "Dark Herald",
			Health = 800,
			MaxHealth = 800,
			Damage = 35,
			AttackCooldown = 2,
			AttackRange = 30,
			MoveSpeed = 22,
			Color = Color3.fromRGB(80, 0, 120),
			Size = Vector3.new(2, 4, 2)
		},
		VoidSentinel = {
			Name = "Void Sentinel",
			Health = 1000,
			MaxHealth = 1000,
			Damage = 45,
			AttackCooldown = 2.5,
			AttackRange = 35,
			MoveSpeed = 20,
			Color = Color3.fromRGB(20, 0, 60),
			Size = Vector3.new(2.5, 5, 2.5)
		},
		ElementalTitan = {
			Name = "Elemental Titan",
			Health = 1500,
			MaxHealth = 1500,
			Damage = 60,
			AttackCooldown = 3,
			AttackRange = 40,
			MoveSpeed = 18,
			Color = Color3.fromRGB(255, 100, 0),
			Size = Vector3.new(3, 6, 3)
		},
		ShadowWraith = {
			Name = "Shadow Wraith",
			Health = 600,
			MaxHealth = 600,
			Damage = 30,
			AttackCooldown = 1.5,
			AttackRange = 25,
			MoveSpeed = 25,
			Color = Color3.fromRGB(10, 10, 10),
			Size = Vector3.new(1.8, 4.5, 1.8)
		},
		CosmicDestroyer = {
			Name = "Cosmic Destroyer",
			Health = 1200,
			MaxHealth = 1200,
			Damage = 50,
			AttackCooldown = 2,
			AttackRange = 45,
			MoveSpeed = 19,
			Color = Color3.fromRGB(100, 50, 200),
			Size = Vector3.new(2.8, 5.5, 2.8)
		}
	}

	-- Stop infection system and clean up
	local function stopInfection()
		InfectionConfig.Active = false

		-- Disconnect all connections
		for key, connection in pairs(InfectionConfig.CloneConnections) do
			if connection and typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end
		end
		InfectionConfig.CloneConnections = {}

		-- Destroy all clone GUIs
		for userId, gui in pairs(InfectionConfig.CloneGUIs) do
			if gui then gui:Destroy() end
		end
		InfectionConfig.CloneGUIs = {}

		-- Clear infected players list
		InfectionConfig.InfectedPlayers = {}
	end

	-- Attack Cooldowns with minimum cooldown enforcement
	local AttackCooldowns = {}
	local MIN_ATTACK_COOLDOWN = 0.3 -- Minimum time between any attacks to prevent spamming
	local lastAttackTime = 0

	-- OPTIMIZATION: Helper function to check if attack can be used
	local function canUseAttack()
		local currentTime = tick()
		if Attack or DEAD or (currentTime - lastAttackTime < MIN_ATTACK_COOLDOWN) then
			return false
		end
		lastAttackTime = currentTime
		return true
	end

	-- OPTIMIZATION: Cached player list system with better performance
	local cachedPlayers = {}
	local lastCacheUpdate = 0
	local CACHE_UPDATE_INTERVAL = 1.0 -- Increased from 0.5 to reduce overhead

	local function updateCachedPlayers()
		cachedPlayers = {}
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= targetPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					table.insert(cachedPlayers, {
						Model = player.Character,
						Humanoid = hum,
						RootPart = root
					})
				end
			end
		end
	end

	-- OPTIMIZED: Use single shared RunService connection with throttling
	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		if currentTime - lastCacheUpdate >= CACHE_UPDATE_INTERVAL then
			updateCachedPlayers()
			lastCacheUpdate = currentTime
		end
	end)

	updateCachedPlayers()

	-- Listen for player changes (only update when needed)
	local playerAddedConnection = Players.PlayerAdded:Connect(updateCachedPlayers)
	local playerRemovingConnection = Players.PlayerRemoving:Connect(updateCachedPlayers)

	-- Math shortcuts
	local CF, VT, ANGLES = CFrame.new, Vector3.new, CFrame.Angles
	local RAD, MRANDOM = math.rad, math.random

	-- Create Effects folder
	local Effects = Instance.new("Folder")
	Effects.Name = "Nexus_Effects"
	Effects.Parent = CHARACTER

	-- Create Classification
	local classValue = Instance.new("StringValue")
	classValue.Name = "Classification"
	classValue.Value = CLASSIFICATION
	classValue.Parent = CHARACTER

	-- Taunt Display System - REMOVED
	local function DisplayTaunt(message, duration, color)
		-- Taunts removed per user request
		return
		--[[
		if TauntDisplaying then return end
		TauntDisplaying = true

		-- Clean up old taunt if exists
		if TauntGUI then TauntGUI:Destroy() end

		-- Ensure HEAD exists for billboard positioning
		if not HEAD or not HEAD.Parent then
			warn("DisplayTaunt: HEAD not found")
			TauntDisplaying = false
			return
		end

		-- Create a separate BillboardGui for taunts (positioned above NexusChat)
		local tauntBillboard = Instance.new("BillboardGui")
		tauntBillboard.Name = "NexusTauntBillboard"
		tauntBillboard.Adornee = HEAD
		tauntBillboard.Size = UDim2.new(0, 400, 0, 80)
		tauntBillboard.StudsOffset = Vector3.new(0, 9, 0)  -- Higher than NexusChat (which is at 6)
		tauntBillboard.AlwaysOnTop = true
		tauntBillboard.MaxDistance = 200
		tauntBillboard.LightInfluence = 0
		tauntBillboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		tauntBillboard.Parent = CHARACTER
		TauntGUI = tauntBillboard

		-- Taunt frame
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(1, 0, 1, 0)
		mainFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
		mainFrame.BackgroundTransparency = 0.2
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = tauntBillboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = mainFrame

		local glow = Instance.new("UIStroke")
		glow.Color = color or Color3.fromRGB(255, 50, 150)
		glow.Thickness = 3
		glow.Transparency = 0.2
		glow.Parent = mainFrame

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -20, 1, -20)
		text.Position = UDim2.new(0, 10, 0, 10)
		text.BackgroundTransparency = 1
		text.Text = message
		text.TextColor3 = color or Color3.fromRGB(255, 200, 255)
		text.TextSize = 22
		text.Font = Enum.Font.GothamBold
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		text.TextWrapped = true
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.TextYAlignment = Enum.TextYAlignment.Center
		text.Parent = mainFrame

		-- Pulsing effect
		local pulseTween = TweenService:Create(glow, 
			TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Transparency = 0.7}
		)
		pulseTween:Play()

		-- Auto remove
		Debris:AddItem(tauntBillboard, duration or 3)

		coroutine.wrap(function()
			task.wait(duration or 3)
			TauntDisplaying = false
		end)()
		--]]
	end

	-- OPTIMIZED SOUND SYSTEM
	-- Accepts either a sound key from SOUNDS table or a direct ID
	-- Usage: CreateSound("intro_buildup", PARENT, volumeOverride, pitchOverride, loop)
	--    or: CreateSound(1843013813, PARENT, volumeOverride, pitchOverride, loop)
	local function CreateSound(soundKeyOrID, PARENT, VOLUME_OVERRIDE, PITCH_OVERRIDE, LOOP, DESCRIPTION)
		local soundId = nil
		local baseVolume = 2 -- Default volume if not found in table
		local defaultPitch = 1 -- Default pitch if not found in table

		-- Check if soundKeyOrID is a string (key in SOUNDS table) or number (direct ID)
		if type(soundKeyOrID) == "string" and SOUNDS[soundKeyOrID] then
			-- Use sound from table
			local soundData = SOUNDS[soundKeyOrID]
			soundId = soundData.id
			baseVolume = soundData.baseVolume
			defaultPitch = soundData.defaultPitch
		elseif type(soundKeyOrID) == "number" then
			-- Direct ID provided (backward compatibility)
			soundId = soundKeyOrID
			baseVolume = VOLUME_OVERRIDE or 2
			defaultPitch = PITCH_OVERRIDE or 1
		else
			warn("CreateSound: Invalid sound key or ID provided:", soundKeyOrID)
			return nil
		end

		-- Use override values if provided, otherwise use defaults
		local finalVolume = (VOLUME_OVERRIDE or baseVolume) * GLOBAL_SOUND_VOLUME_MULTIPLIER
		local finalPitch = PITCH_OVERRIDE or defaultPitch

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. soundId
		sound.Parent = PARENT
		sound.Volume = finalVolume
		sound.PlaybackSpeed = finalPitch
		sound.Looped = LOOP or false
		sound.RollOffMinDistance = 80
		sound.RollOffMaxDistance = 999999
		sound.RollOffMode = Enum.RollOffMode.Linear

		-- Wait for sound to load before playing to prevent cutting off
		task.spawn(function()
			-- Check if sound is already loaded
			if sound.TimeLength > 0 then
				sound:Play()
				return
			end

			-- Wait for sound to load via Loaded event
			local soundLoaded = false
			local connection
			connection = sound.Loaded:Connect(function()
				soundLoaded = true
				if connection then
					connection:Disconnect()
				end
				if sound and sound.Parent then
					sound:Play()
				end
			end)

			-- Fallback: Check TimeLength periodically (in case Loaded event doesn't fire)
			local timeout = 0
			while not soundLoaded and timeout < 5 do -- 5 second timeout
				task.wait(0.1)
				timeout = timeout + 0.1
				if sound.TimeLength > 0 then
					soundLoaded = true
					if connection then
						connection:Disconnect()
					end
					if sound and sound.Parent then
						sound:Play()
					end
					break
				end
			end

			-- If still not loaded after timeout, warn but try to play anyway
			if not soundLoaded and sound.TimeLength == 0 then
				warn("Sound may not have loaded properly:", soundId)
				-- Still try to play - sometimes sounds work even if TimeLength is 0
				if sound and sound.Parent then
					sound:Play()
				end
			end
		end)

		-- Clean up sound when it finishes (only for non-looped sounds)
		if not LOOP then
			sound.Ended:Connect(function()
				task.wait(0.5) -- Small delay to ensure sound finishes completely
				if sound and sound.Parent then
					sound:Destroy()
				end
			end)

			-- Also ensure parent isn't destroyed while sound is playing
			-- Mark parent so CreatePositionalSound knows to keep it alive
			if PARENT and PARENT:IsA("BasePart") then
				PARENT:SetAttribute("HasActiveSound", true)
				sound.Ended:Connect(function()
					task.wait(0.5)
					if PARENT and PARENT:GetAttribute("HasActiveSound") then
						PARENT:SetAttribute("HasActiveSound", nil)
					end
				end)
			end
		end

		return sound
	end

	-- ENHANCED PART CREATION
	local function CreatePart(SIZE, CFRAME, COLOR, MATERIAL, TRANSPARENCY, ANCHORED)
		local part = Instance.new("Part")
		part.Size = SIZE
		part.CFrame = CFRAME
		part.Color = COLOR
		part.Material = MATERIAL
		part.Transparency = TRANSPARENCY
		part.Anchored = ANCHORED
		part.CanCollide = false
		part.CastShadow = false
		part.Parent = Effects
		return part
	end
	local function ApplyDamage(humanoid, damage, attacker)
		if humanoid.Health <= 0 then return end

		local scaledDamage = damage * 2

		-- Check for weakness status effect (damage multiplier)
		-- We check if there's a Weakness label visible on the character
		local character = humanoid.Parent
		if character then
			local head = character:FindFirstChild("Head")
			if head then
				for _, billboard in ipairs(head:GetChildren()) do
					if billboard:IsA("BillboardGui") then
						local label = billboard:FindFirstChild("TextLabel")
						if label and label.Text == "Weakness" then
							scaledDamage = scaledDamage * StatusEffects.Weakness.DamageMultiplier
							break
						end
					end
				end
			end
		end

		humanoid:TakeDamage(scaledDamage)

		-- Enhanced damage indicator
		local dmgPart = CreatePart(VT(1, 1, 1), humanoid.Parent.HumanoidRootPart.CFrame, Color3.new(1, 0, 0), Enum.Material.Neon, 0.3, true)
		local dmgText = Instance.new("BillboardGui")
		dmgText.Size = UDim2.new(0, 120, 0, 60)
		dmgText.AlwaysOnTop = true
		dmgText.Parent = dmgPart

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = "-" .. math.floor(scaledDamage)
		label.TextColor3 = Color3.new(1, 0, 0)
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.Parent = dmgText

		TweenService:Create(dmgPart, TweenInfo.new(1.2), {
			CFrame = dmgPart.CFrame * CF(0, 6, 0),
			Transparency = 1
		}):Play()

		TweenService:Create(label, TweenInfo.new(1.2), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}):Play()

		Debris:AddItem(dmgPart, 1.2)
	end
	local function ApplyStatusEffect(character, humanoid, effectName, attacker)
		if not character or not humanoid or humanoid.Health <= 0 then return end
		local effect = StatusEffects[effectName]
		if not effect then return end

		-- Create visual indicator
		local head = character:FindFirstChild("Head")
		if head then
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(4, 0, 1.5, 0)
			billboard.MaxDistance = 200
			billboard.StudsOffset = Vector3.new(0, 4, 0)

			local textLabel = Instance.new("TextLabel")
			textLabel.BackgroundColor3 = effect.Color
			textLabel.TextColor3 = Color3.new(1, 1, 1)
			textLabel.Text = effect.Name
			textLabel.TextSize = 14
			textLabel.BackgroundTransparency = 0.3
			textLabel.TextStrokeTransparency = 0.5
			textLabel.Parent = billboard
			billboard.Parent = head

			Debris:AddItem(billboard, effect.Duration)
		end

		-- Apply effect function if it exists
		if effect.Effect then
			effect.Effect(character, humanoid)
		end

		-- Handle damage over time effects
		if effect.DamagePerTick then
			local remainingTicks = effect.Duration / effect.TickRate
			local tickCoroutine = coroutine.wrap(function()
				for tick = 1, remainingTicks do
					if humanoid and humanoid.Health > 0 then
						ApplyDamage(humanoid, effect.DamagePerTick, attacker)
					end
					task.wait(effect.TickRate)
				end
				if effect.OnRemove then effect.OnRemove(character, humanoid) end
			end)
			tickCoroutine()
		else
			task.wait(effect.Duration)
			if effect.OnRemove then effect.OnRemove(character, humanoid) end
		end
	end

	-- REALISTIC LIGHTNING BOLT GENERATOR
	-- Creates jagged, branched lightning bolts that look realistic
	local function CreateLightningBolt(startPos, endPos, thickness, color, branches, lifetime)
		thickness = thickness or 8
		color = color or Color3.new(1, 1, 0.9)
		branches = branches or 3
		lifetime = lifetime or 0.3

		local bolts = {}

		-- Generate jagged path from start to end
		local function generateJaggedPath(start, finish, segments)
			segments = segments or math.max(8, math.floor((start - finish).Magnitude / 15))
			local path = {start}
			local direction = (finish - start)
			local distance = direction.Magnitude
			direction = direction.Unit

			for i = 1, segments - 1 do
				local t = i / segments
				local basePos = start + direction * (distance * t)

				-- Add random jaggedness perpendicular to direction
				local right = direction:Cross(VT(0, 1, 0)).Unit
				if right.Magnitude < 0.1 then
					right = direction:Cross(VT(1, 0, 0)).Unit
				end
				local up = direction:Cross(right).Unit

				local offset = right * MRANDOM(-30, 30) + up * MRANDOM(-20, 20)
				table.insert(path, basePos + offset)
			end

			table.insert(path, finish)
			return path
		end

		-- Create main lightning bolt
		local mainPath = generateJaggedPath(startPos, endPos, math.max(10, math.floor((startPos - endPos).Magnitude / 12)))

		-- Create segments for main bolt
		for i = 1, #mainPath - 1 do
			local segmentStart = mainPath[i]
			local segmentEnd = mainPath[i + 1]
			local segmentDir = (segmentEnd - segmentStart)
			local segmentLength = segmentDir.Magnitude
			segmentDir = segmentDir.Unit

			-- Main bolt segment
			local boltPart = CreatePart(
				VT(thickness * 0.6, thickness * 0.6, segmentLength),
				CF(segmentStart, segmentEnd) * CF(0, 0, -segmentLength/2),
				color,
				Enum.Material.Neon,
				0.1,
				true
			)

			-- Bright white core
			local corePart = CreatePart(
				VT(thickness * 0.3, thickness * 0.3, segmentLength),
				boltPart.CFrame,
				Color3.new(1, 1, 1),
				Enum.Material.Neon,
				0,
				true
			)

			table.insert(bolts, boltPart)
			table.insert(bolts, corePart)
		end

		-- Add branches
		for b = 1, branches do
			if #mainPath > 2 then
				local branchIndex = MRANDOM(2, #mainPath - 1)
				local branchStart = mainPath[branchIndex]
				local branchEnd = branchStart + VT(MRANDOM(-60, 60), MRANDOM(-40, -10), MRANDOM(-60, 60))

				local branchPath = generateJaggedPath(branchStart, branchEnd, 5)
				local branchThickness = thickness * 0.5

				for i = 1, #branchPath - 1 do
					local segStart = branchPath[i]
					local segEnd = branchPath[i + 1]
					local segDir = (segEnd - segStart)
					local segLen = segDir.Magnitude
					segDir = segDir.Unit

					local branchPart = CreatePart(
						VT(branchThickness * 0.6, branchThickness * 0.6, segLen),
						CF(segStart, segEnd) * CF(0, 0, -segLen/2),
						color,
						Enum.Material.Neon,
						0.2,
						true
					)

					local branchCore = CreatePart(
						VT(branchThickness * 0.3, branchThickness * 0.3, segLen),
						branchPart.CFrame,
						Color3.new(1, 1, 0.95),
						Enum.Material.Neon,
						0.1,
						true
					)

					table.insert(bolts, branchPart)
					table.insert(bolts, branchCore)
				end
			end
		end

		-- Fade out all bolts
		for _, bolt in ipairs(bolts) do
			TweenService:Create(bolt, TweenInfo.new(lifetime), {
				Transparency = 1,
				Size = bolt.Size * 0.5
			}):Play()
			Debris:AddItem(bolt, lifetime)
		end

		return bolts
	end

	-- Helper function to create positional sounds (creates temporary part at position)
	local function CreatePositionalSound(soundKeyOrID, position, VOLUME_OVERRIDE, PITCH_OVERRIDE, LOOP, DESCRIPTION)
		local soundPart = CreatePart(VT(1, 1, 1), CF(position), Color3.new(0, 0, 0), Enum.Material.Neon, 1, true)
		local sound = CreateSound(soundKeyOrID, soundPart, VOLUME_OVERRIDE, PITCH_OVERRIDE, LOOP, DESCRIPTION)

		-- Only clean up part after sound finishes (for non-looped sounds)
		if sound and not LOOP then
			sound.Ended:Connect(function()
				task.wait(0.5) -- Small delay to ensure sound finishes completely
				if soundPart and soundPart.Parent then
					-- Only destroy if sound has actually finished
					if not soundPart:GetAttribute("HasActiveSound") then
						soundPart:SetAttribute("SoundFinished", true)
						soundPart:Destroy()
					end
				end
			end)
			-- Fallback: Clean up after reasonable time (longer than most sounds)
			-- This will be ignored if sound finishes earlier via Ended event
			task.spawn(function()
				task.wait(30)
				if soundPart and soundPart.Parent and not soundPart:GetAttribute("SoundFinished") then
					-- Only destroy if sound hasn't finished yet and isn't marked as active
					if not soundPart:GetAttribute("HasActiveSound") then
						if sound and sound.IsPlaying then
							-- Sound still playing, wait a bit more
							return
						end
						soundPart:Destroy()
					end
				end
			end)
		else
			-- For looped sounds, use normal cleanup
			Debris:AddItem(soundPart, 10)
		end

		return soundPart
	end

	-- CUSTOM NEXUS CHAT SYSTEM
	local NexusChatBillboard = nil

	local function DisplayNexusMessage(message)
		-- Ensure HEAD exists
		if not HEAD or not HEAD.Parent then
			warn("Nexus chat: HEAD not found")
			return
		end

		-- Remove old billboard if exists
		if NexusChatBillboard then
			NexusChatBillboard:Destroy()
			NexusChatBillboard = nil
		end

		-- Initial size (will be dynamically resized based on actual text)
		-- Smaller, more minimal size
		local baseSize = UDim2.new(0, 200, 0, 50)  -- Smaller default

		-- Create BillboardGui above player's head
		local billboardGui = Instance.new("BillboardGui")
		billboardGui.Name = "NexusChat"
		billboardGui.Adornee = HEAD
		billboardGui.Size = baseSize
		billboardGui.StudsOffset = Vector3.new(0, 5, 0)  -- Slightly lower
		billboardGui.AlwaysOnTop = true
		billboardGui.MaxDistance = 150  -- Reduced distance
		billboardGui.LightInfluence = 0
		billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		billboardGui.Parent = CHARACTER

		NexusChatBillboard = billboardGui

		-- Background frame - More transparent
		local background = Instance.new("Frame")
		background.Size = UDim2.new(1, 0, 1, 0)
		background.BackgroundColor3 = Color3.fromRGB(10, 0, 20)
		background.BackgroundTransparency = 0.6  -- More transparent
		background.BorderSizePixel = 0
		background.Parent = billboardGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)  -- Smaller radius
		corner.Parent = background

		-- Purple glow border - More subtle
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(150, 0, 255)
		stroke.Thickness = 1.5  -- Thinner
		stroke.Transparency = 0.3  -- More transparent
		stroke.Parent = background

		-- Text label for typing effect - Smaller
		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, -12, 1, -12)
		textLabel.Position = UDim2.new(0, 6, 0, 6)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = ""  -- Start empty
		textLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
		textLabel.TextSize = 18  -- Smaller text
		textLabel.Font = Enum.Font.Gotham
		textLabel.TextStrokeTransparency = 0.5  -- More transparent stroke
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.Parent = background

		-- Function to resize GUI based on actual text bounds
		local function resizeGUIFromText()
			-- Run asynchronously to not block typing animation
			task.spawn(function()
				-- Small delay to ensure text renders
				task.wait(0.05)
				if textLabel and textLabel.Parent and billboardGui and billboardGui.Parent then
					local padding = 12  -- Smaller padding
					local minWidth = 150  -- Smaller minimum
					local maxWidth = 350  -- Smaller maximum

					-- Temporarily set label to max width to measure actual text bounds
					local tempWidth = maxWidth - 20
					textLabel.Size = UDim2.new(0, tempWidth, 0, 1000)  -- Tall enough to measure
					task.wait(0.05)  -- Wait for TextBounds to update

					local textBounds = textLabel.TextBounds

					-- Calculate needed width and height
					-- TextBounds.X is the width needed (up to tempWidth if wrapped)
					local neededWidth = math.max(minWidth, math.min(textBounds.X + padding, maxWidth))
					local neededHeight = math.max(textBounds.Y + padding, 40)  -- Smaller min height

					-- Resize the BillboardGui
					billboardGui.Size = UDim2.new(0, neededWidth, 0, neededHeight)

					-- Restore label size relative to GUI
					textLabel.Size = UDim2.new(1, -20, 1, -20)
				end
			end)
		end

		-- Appear sound effect (positional at head position)
		CreatePositionalSound("chat_appear", HEAD.Position, nil, nil, false, "Chat appear")

		-- Initial resize after setup (for initial empty state)
		task.spawn(function()
			task.wait(0.1)
			resizeGUIFromText()
		end)

		-- Typing effect animation (takes exactly 5 seconds total)
		coroutine.wrap(function()
			local fullText = message
			local currentText = ""
			local totalCharacters = #fullText
			local typingDuration = 5  -- Total typing time in seconds
			local delayPerCharacter = typingDuration / totalCharacters  -- Calculate delay per character

			for i = 1, totalCharacters do
				currentText = string.sub(fullText, 1, i)
				textLabel.Text = currentText

				-- Resize GUI dynamically as text is typed (every few characters for performance)
				if i % 10 == 0 or i == totalCharacters then
					resizeGUIFromText()
				end

				-- Typing sound for every character (quiet, non-intrusive)
				-- Use lower volume and pitch variation to avoid choppiness
				local char = string.sub(fullText, i, i)
				-- Only play sound for actual characters (skip spaces/punctuation occasionally)
				if char ~= " " and char ~= "." and char ~= "," and char ~= "!" and char ~= "?" then
					local volume = 0.15  -- Very quiet
					local pitch = 1.0 + (math.random() * 0.2 - 0.1)  -- Slight pitch variation
					CreatePositionalSound("chat_typing", HEAD.Position, volume, pitch, false, "Typing sound")
				end

				task.wait(delayPerCharacter)  -- Dynamic typing speed to take exactly 5 seconds
			end

			-- Final resize after all text is displayed
			resizeGUIFromText()

			-- Message fully typed, display for 5 seconds
			task.wait(5)

			-- Cool fade/dissolve effect after 3 seconds visible (total 8 seconds)
			-- Pulsing before disappear
			for pulse = 1, 6 do
				TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 0.8}):Play()
				task.wait(0.25)
				TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 0}):Play()
				task.wait(0.25)
			end

			-- Disappear sound (positional at head position)
			CreatePositionalSound("chat_disappear", HEAD.Position, nil, nil, false, "Chat disappear")

			-- Dissolve effect
			TweenService:Create(background, TweenInfo.new(1), {
				BackgroundTransparency = 1
			}):Play()
			TweenService:Create(textLabel, TweenInfo.new(1), {
				TextTransparency = 1,
				TextStrokeTransparency = 1
			}):Play()
			TweenService:Create(stroke, TweenInfo.new(1), {
				Transparency = 1
			}):Play()

			-- Particle effect on disappear
			for particle = 1, 15 do
				local sparkle = CreatePart(VT(0.5, 0.5, 0.5), billboardGui.Adornee.CFrame * CF(MRANDOM(-2, 2), MRANDOM(-1, 2), MRANDOM(-2, 2)), Color3.fromRGB(150, 0, 255), Enum.Material.Neon, 0.3, true)
				sparkle.Shape = Enum.PartType.Ball
				TweenService:Create(sparkle, TweenInfo.new(1), {
					CFrame = sparkle.CFrame + VT(MRANDOM(-3, 3), MRANDOM(2, 5), MRANDOM(-3, 3)),
					Transparency = 1
				}):Play()
				Debris:AddItem(sparkle, 1)
			end

			task.wait(1)
			billboardGui:Destroy()
			NexusChatBillboard = nil
		end)()
	end

	-- Hook into TextChatService to intercept Nexus boss messages
	local TextChatService = game:GetService("TextChatService")
	local function SetupCustomChat()
		-- Only setup for the Nexus boss player
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			-- New TextChatService
			pcall(function()
				local textChannels = TextChatService:WaitForChild("TextChannels", 5)
				if textChannels then
					local generalChannel = textChannels:FindFirstChild("RBXGeneral")
					if generalChannel then
						generalChannel.MessageReceived:Connect(function(message)
							if message.TextSource and message.TextSource.UserId == targetPlayer.UserId then
								-- Nexus boss sent a message, display custom chat
								DisplayNexusMessage(message.Text)
							end
						end)
					else
						-- Fallback: try to find any channel
						for _, channel in pairs(textChannels:GetChildren()) do
							if channel:IsA("TextChannel") then
								channel.MessageReceived:Connect(function(message)
									if message.TextSource and message.TextSource.UserId == targetPlayer.UserId then
										DisplayNexusMessage(message.Text)
									end
								end)
								break
							end
						end
					end
				end
			end)
		end

		-- Always setup legacy chat as fallback (this should work in all cases)
		pcall(function()
			targetPlayer.Chatted:Connect(function(message)
				DisplayNexusMessage(message)
			end)
		end)
	end

	-- Setup custom chat after character is ready
	coroutine.wrap(function()
		task.wait(1)  -- Wait for character to fully load
		SetupCustomChat()
	end)()

	-- ULTIMATE EFFECT SYSTEM
	local function CreateEffect(TYPE, CFRAME, SIZE1, SIZE2, COLOR, TIME, SOUNDID, INTENSITY)
		-- For flat rings, ensure part size is also very thin
		local partSize = SIZE1
		if TYPE == "Ring" and SIZE1.Y < 5 then
			-- Make part size extremely thin for flat rings
			local radius = math.max(SIZE1.X, SIZE1.Z)
			partSize = VT(radius, radius * 0.05, radius)  -- Very thin part size
		end

		local effect = CreatePart(partSize, CFRAME, COLOR, Enum.Material.Neon, 0, true)

		local light = Instance.new("PointLight")
		light.Brightness = 8 * (INTENSITY or 1)
		light.Color = COLOR
		light.Range = SIZE1.Magnitude * 4
		light.Parent = effect

		local mesh = nil
		if TYPE == "Sphere" then
			mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = effect
		elseif TYPE == "Ring" then
			mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://3270017"
			-- For ring mesh: VT(radiusX, radiusY, thickness) - X and Y must be equal for perfect circle
			local radius = math.max(SIZE1.X, SIZE1.Z)  -- Use the larger horizontal component as radius
			local thickness = radius * 0.05  -- Thin thickness (5% of radius)
			mesh.Scale = VT(radius, radius, thickness)  -- Perfect circular ring: X=Y for circle, Z for thickness
			mesh.Parent = effect
			-- Only rotate flat rings (small Y component) to lay on ground
			-- Vertical rings (larger Y component) should remain vertical
			if SIZE1.Y < 5 then
				-- Flat ring - rotate 90 degrees on X axis to make it lay flat on ground
				effect.CFrame = CFRAME * ANGLES(RAD(90), 0, 0)
			else
				-- Vertical ring - keep original rotation
				effect.CFrame = CFRAME
			end
		end

		local tween = TweenService:Create(effect, 
			TweenInfo.new(TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = SIZE2, Transparency = 1}
		)

		if mesh then
			if TYPE == "Ring" then
				-- For rings, maintain circular scale during tween - perfect circle
				local radius = math.max(SIZE2.X, SIZE2.Z)
				local thickness = radius * 0.05  -- Maintain thin thickness (5% of radius)
				TweenService:Create(mesh, TweenInfo.new(TIME), {
					Scale = VT(radius, radius, thickness)  -- Perfect circle: X=Y, thin Z
				}):Play()
			else
				TweenService:Create(mesh, TweenInfo.new(TIME), {Scale = SIZE2}):Play()
			end
		end

		if light then
			TweenService:Create(light, TweenInfo.new(TIME), {Brightness = 0, Range = SIZE2.Magnitude * 4}):Play()
		end

		tween:Play()

		if SOUNDID then
			CreateSound(SOUNDID, effect, 2 * (INTENSITY or 1), MRANDOM(8, 12)/10, false)
		end

		Debris:AddItem(effect, TIME + 0.5)
		return effect
	end

	-- DAMAGE SYSTEM
	-- METEOR COLLISION FILTER - Only hit solid parts
	local function isValidMeteorCollision(part)
		if not part or not part.Parent then return false end
		if part.Parent:FindFirstChild("Humanoid") then return true end  -- Hit humanoids
		if not part.CanCollide then return false end  -- Skip non-collidable parts
		if part.Transparency >= 1 then return false end  -- Skip invisible parts
		if part.Material == Enum.Material.Air then return false end  -- Skip air material
		return true
	end

	-- APPLY STATUS EFFECTS TO NEARBY PLAYERS (HELPER)
	local function ApplyStatusEffectToNearby(position, range, effectName, attacker)
		for _, playerData in pairs(cachedPlayers) do
			if playerData.Character and playerData.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (playerData.Character.HumanoidRootPart.Position - position).Magnitude
				if dist < range then
					ApplyStatusEffect(playerData.Character, playerData.Humanoid, effectName, attacker)
				end
			end
		end
	end

	-- AREA DAMAGE - OPTIMIZED
	local function ApplyAoE(position, range, damage, fling)
		-- Use cached player list instead of workspace:GetDescendants()
		for _, playerData in pairs(cachedPlayers) do
			if playerData.RootPart and playerData.Model and not playerData.Model:FindFirstChild("Classification") then
				-- Check if player is a minion - don't damage minions
				local player = Players:GetPlayerFromCharacter(playerData.Model)
				local isMinion = player and MinionConfig.Minions[player.UserId]

				if not isMinion then
					local dist = (playerData.RootPart.Position - position).Magnitude
					if dist <= range then
						ApplyDamage(playerData.Humanoid, damage * (1 - dist/range), targetPlayer)

						if fling > 0 then
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = VT(1e9, 1e9, 1e9)
							bv.Velocity = (playerData.RootPart.Position - position).Unit * fling + VT(0, fling/3, 0)
							bv.Parent = playerData.RootPart
							Debris:AddItem(bv, 0.3)
						end
					end
				end
			end
		end
	end

	-- ENHANCED IDLE EFFECTS SYSTEM FOR NEXUS BOSS (SUBTLE & VISIBLE)
	local function CreateIdleEffects()
		-- Create permanent body part auras for the Nexus boss (more subtle)
		local bodyPartEffects = {}

		-- Add auras to main body parts (smaller and more transparent)
		for _, partName in ipairs({"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Head"}) do
			local part = CHARACTER:FindFirstChild(partName)
			if part then
				-- Create smaller orbiting energy spheres (only 2 per part)
				for i = 1, 2 do
					local auraSphere = CreatePart(VT(0.8, 0.8, 0.8), part.CFrame, Color3.new(0.6, 0.2, 0.9), Enum.Material.Neon, 0.6, true)
					auraSphere.Shape = Enum.PartType.Ball
					table.insert(bodyPartEffects, {Part = part, Aura = auraSphere, Index = i})

					coroutine.wrap(function()
						local angle = (i / 2) * math.pi * 2
						while auraSphere.Parent and not DEAD and part.Parent do
							angle = angle + 0.05  -- Slower rotation
							auraSphere.CFrame = part.CFrame * CF(math.cos(angle) * 3, math.sin(tick() * 2 + i) * 1.2, math.sin(angle) * 3)

							-- Subtle pulsing transparency
							local pulse = 0.6 + math.sin(tick() * 2) * 0.2
							auraSphere.Transparency = pulse

							task.wait()
						end
					end)()
				end
			end
		end

		-- OPTIMIZED: Continuous effect generation with throttling (MORE SUBTLE)
		coroutine.wrap(function()
			local lastIdleEffect = 0
			while not DEAD and CHARACTER and ROOTPART do
				if IdleEffectsActive and not Attack then
					local currentTime = tick()
					-- Throttle idle effects to reduce overhead
					if currentTime - lastIdleEffect >= 1 then  -- Even less frequent
						lastIdleEffect = currentTime

						-- Floating energy orbs (even more reduced, smaller, more transparent)
						if math.random(1, 5) == 1 then
							local orb = CreatePart(VT(1.5, 1.5, 1.5), ROOTPART.CFrame * CF(math.random(-8, 8), math.random(1, 8), math.random(-8, 8)), Color3.new(0.5, 0.2, 0.8), Enum.Material.Neon, 0.5, true)
							orb.Shape = Enum.PartType.Ball

							local orbLight = Instance.new("PointLight")
							orbLight.Brightness = 3  -- Reduced brightness
							orbLight.Color = Color3.new(0.6, 0.2, 0.9)
							orbLight.Range = 10
							orbLight.Parent = orb

							TweenService:Create(orb, TweenInfo.new(3), {
								CFrame = ROOTPART.CFrame * CF(math.random(-12, 12), math.random(8, 15), math.random(-12, 12)),
								Transparency = 1
							}):Play()

							Debris:AddItem(orb, 3)
						end

						-- OPTIMIZED: Even more reduced ring frequency
						if math.random(1, 10) == 1 then
							local ring = CreatePart(VT(1, 1, 1), ROOTPART.CFrame * ANGLES(RAD(math.random(-30, 30)), RAD(math.random(0, 360)), 0), Color3.new(0.6, 0.3, 0.9), Enum.Material.Neon, 0.6, true)
							local mesh = Instance.new("SpecialMesh")
							mesh.MeshType = Enum.MeshType.FileMesh
							mesh.MeshId = "rbxassetid://3270017"
							mesh.Scale = VT(3, 3, 0.1)  -- Perfect circle: X=Y, thin Z
							mesh.Parent = ring
							TweenService:Create(ring, TweenInfo.new(2.5), {
								Size = VT(12, 12, 1),
								Transparency = 1
							}):Play()
							TweenService:Create(mesh, TweenInfo.new(2.5), {Scale = VT(12, 12, 0.1)}):Play()  -- Maintain circular proportions
							Debris:AddItem(ring, 2.5)
						end

						-- OPTIMIZED: Very reduced spark frequency
						if math.random(1, 8) == 1 then
							local spark = CreatePart(VT(0.4, 0.4, 0.4), ROOTPART.CFrame * CF(math.random(-3, 3), math.random(-1, 4), math.random(-3, 3)), Color3.new(0.9, 0.6, 1), Enum.Material.Neon, 0.3, true)
							spark.Shape = Enum.PartType.Ball
							TweenService:Create(spark, TweenInfo.new(1), {
								Size = VT(1.2, 1.2, 1.2),
								Transparency = 1
							}):Play()
							Debris:AddItem(spark, 1)
						end

						-- OPTIMIZED: Very reduced dust frequency
						if math.random(1, 12) == 1 then
							local dust = CreatePart(VT(1, 1, 1), ROOTPART.CFrame * CF(0, math.random(1, 3), 0), Color3.new(0.4, 0.1, 0.6), Enum.Material.Neon, 0.7, true)
							dust.Shape = Enum.PartType.Ball
							TweenService:Create(dust, TweenInfo.new(3), {
								CFrame = dust.CFrame + VT(math.random(-6, 6), math.random(3, 6), math.random(-6, 6)),
								Size = VT(0.2, 0.2, 0.2),
								Transparency = 1
							}):Play()
							Debris:AddItem(dust, 3)
						end
					end
				end
				task.wait(1) -- Increased to 1 second
			end

			-- Clean up body part effects
			for _, effect in ipairs(bodyPartEffects) do
				if effect.Aura and effect.Aura.Parent then
					effect.Aura:Destroy()
				end
			end
		end)()
	end

	-- SPECTACULAR BOSS INTRO WITH EPIC CHARGE-UP AND EXPLOSION
	local function PlayBossIntro()
		if IntroPlayed then return end
		IntroPlayed = true
		Attack = true

		-- Store original lighting values
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogEnd = Lighting.FogEnd
		local originalFogColor = Lighting.FogColor

		-- PHASE 1: AWAKENING - Dramatic environmental changes
		DisplayTaunt(IntroTaunts[1], 5, Color3.fromRGB(255, 0, 0))
		CreatePositionalSound("intro_buildup", ROOTPART.Position, 1.5, 0.5, false, "Epic orchestral buildup/charge sound")

		TweenService:Create(Lighting, TweenInfo.new(4), {
			Brightness = 0.03,
			Ambient = Color3.new(0.15, 0, 0.1),
			ColorShift_Top = Color3.new(0.3, 0, 0.5),
			FogEnd = 400,
			FogColor = Color3.new(0.1, 0, 0.2)
		}):Play()

		-- Create central charge sphere
		local chargeSphere = CreatePart(VT(8, 8, 8), ROOTPART.CFrame * CF(0, 10, 0), Color3.new(0.5, 0, 1), Enum.Material.Neon, 0.3, true)
		chargeSphere.Shape = Enum.PartType.Ball

		-- Pulsing energy rings
		coroutine.wrap(function()
			for pulse = 1, 15 do
				CreateEffect("Ring", chargeSphere.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180))), 
					VT(5, 5, 5), VT(25, 25, 5), Color3.new(0.6, 0, 1), 0.8, nil, 2)
				task.wait(0.3)
			end
		end)()

		task.wait(4.5)

		-- PHASE 2: POWER SURGE - Charge sphere grows, energy intensifies
		DisplayTaunt(IntroTaunts[2], 5, Color3.fromRGB(255, 50, 150))
		CreatePositionalSound("lightning_charge", ROOTPART.Position, 2, 0.7, false, "Lightning charge buildup")

		TweenService:Create(chargeSphere, TweenInfo.new(4), {
			Size = VT(20, 20, 20),
			Transparency = 0.1
		}):Play()

		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = 0.01,
			Ambient = Color3.new(0.2, 0, 0.15),
			ColorShift_Top = Color3.new(0.5, 0, 0.7)
		}):Play()

		-- Orbiting energy particles with DEADLY contact damage
		local orbitals = {}
		for i = 1, 12 do
			local orbital = CreatePart(VT(4, 4, 4), chargeSphere.CFrame, Color3.new(1, 0.2, 0.8), Enum.Material.Neon, 0.2, true)
			orbital.Shape = Enum.PartType.Ball
			table.insert(orbitals, orbital)

			-- Contact damage for orbitals
			local debounce = false
			orbital.Touched:Connect(function(hit)
				local character = hit.Parent
				if character:FindFirstChildOfClass("Humanoid") and character ~= CHARACTER and not debounce then
					debounce = true
					ApplyAoE(orbital.Position, 10, 80, 30)
					CreateEffect("Sphere", CF(orbital.Position), VT(4, 4, 4), VT(15, 15, 15), Color3.new(1, 0.2, 0.8), 0.4, nil, 2)
					task.wait(0.5)
					debounce = false
				end
			end)
		end

		-- Animate orbitals
		coroutine.wrap(function()
			local angle = 0
			while chargeSphere.Parent do
				angle = angle + 5
				for i, orbital in ipairs(orbitals) do
					if orbital.Parent then
						local orbitAngle = angle + (i * 30)
						orbital.CFrame = chargeSphere.CFrame * CF(
							math.cos(RAD(orbitAngle)) * 15,
							math.sin(RAD(orbitAngle * 2)) * 8,
							math.sin(RAD(orbitAngle)) * 15
						)
					end
				end
				task.wait()
			end
		end)()

		task.wait(4.5)

		-- PHASE 3: CRITICAL MASS - Screen shake, intense energy
		DisplayTaunt(IntroTaunts[3], 5, Color3.fromRGB(200, 0, 255))
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 2.5, 0.5, false, "Plasma charging")

		TweenService:Create(chargeSphere, TweenInfo.new(3), {
			Size = VT(35, 35, 35),
			Transparency = 0
		}):Play()

		-- Screen shake effect (camera shake simulation via AoE pulses)
		for shake = 1, 10 do
			CreateEffect("Ring", chargeSphere.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(10, 10, 10), VT(50, 50, 10), Color3.new(0.8, 0, 1), 0.4, nil, 1.5)
			ApplyAoE(chargeSphere.Position, 25 + shake*3, 40, 15)
			task.wait(0.3)
		end

		-- Lightning arcs from sphere to ground
		for arc = 1, 8 do
			local arcPos = ROOTPART.Position + VT(MRANDOM(-30, 30), 0, MRANDOM(-30, 30))
			local lightning = CreatePart(VT(6, 1, 6), CF(chargeSphere.Position, arcPos) * CF(0, 0, -((chargeSphere.Position - arcPos).Magnitude/2)), 
				Color3.new(1, 0.5, 1), Enum.Material.Neon, 0.2, true)
			lightning.Size = VT(6, 6, (chargeSphere.Position - arcPos).Magnitude)
			TweenService:Create(lightning, TweenInfo.new(0.5), {Transparency = 1}):Play()
			Debris:AddItem(lightning, 0.5)
			task.wait(0.15)
		end

		task.wait(2.5)

		-- PHASE 4: OVERLOAD - Sphere pulses violently, about to explode
		DisplayTaunt(IntroTaunts[4], 5, Color3.fromRGB(255, 150, 0))
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.4, false, "Cosmic ambient")

		-- Violent pulsing
		coroutine.wrap(function()
			for i = 1, 20 do
				TweenService:Create(chargeSphere, TweenInfo.new(0.15), {
					Size = VT(35 + i*2, 35 + i*2, 35 + i*2),
					Color = Color3.new(MRANDOM(5, 10)/10, MRANDOM(0, 3)/10, 1)
				}):Play()
				task.wait(0.15)
			end
		end)()

		-- Energy shockwaves
		for wave = 1, 12 do
			CreateEffect("Sphere", chargeSphere.CFrame, VT(30, 30, 30), VT(70 + wave*8, 70 + wave*8, 70 + wave*8), 
				Color3.new(MRANDOM(5, 10)/10, 0, 1), 0.6, nil, 2)
			ApplyAoE(chargeSphere.Position, 30 + wave*5, 60, 20)
			task.wait(0.25)
		end

		task.wait(2)

		-- PHASE 5: THE FINAL CHARGE - Everything converges
		DisplayTaunt(IntroTaunts[5], 6, Color3.fromRGB(255, 255, 0))
		CreatePositionalSound("energy_beam", ROOTPART.Position, 3, 0.5, false, "Energy beam charge")

		-- Sphere shrinks rapidly (imploding)
		TweenService:Create(chargeSphere, TweenInfo.new(2.5), {
			Size = VT(5, 5, 5),
			Transparency = 0,
			Color = Color3.new(1, 1, 1)
		}):Play()

		-- All orbitals rush into center
		for _, orbital in ipairs(orbitals) do
			if orbital.Parent then
				TweenService:Create(orbital, TweenInfo.new(2.5), {
					CFrame = chargeSphere.CFrame,
					Size = VT(0, 0, 0),
					Transparency = 1
				}):Play()
			end
		end

		-- Lighting becomes pitch black
		TweenService:Create(Lighting, TweenInfo.new(2.5), {
			Brightness = 0,
			Ambient = Color3.new(0, 0, 0),
			ColorShift_Top = Color3.new(0, 0, 0)
		}):Play()

		-- Energy spiraling into sphere
		for spiral = 1, 25 do
			local spiralOrb = CreatePart(VT(5, 5, 5), ROOTPART.CFrame * CF(MRANDOM(-40, 40), MRANDOM(-10, 30), MRANDOM(-40, 40)), 
				Color3.new(MRANDOM(7, 10)/10, MRANDOM(0, 5)/10, 1), Enum.Material.Neon, 0, true)
			spiralOrb.Shape = Enum.PartType.Ball
			TweenService:Create(spiralOrb, TweenInfo.new(2), {
				CFrame = chargeSphere.CFrame,
				Size = VT(0, 0, 0)
			}):Play()
			Debris:AddItem(spiralOrb, 2)
			task.wait(0.08)
		end

		task.wait(2.5)

		-- ============================================
		-- PHASE 6: THE EPIC EXPLOSION - ALL SOUNDS AT ONCE!
		-- ============================================

		-- Play ALL sound effects simultaneously!
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.3, false, "Massive explosion")
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.4, false, "Massive explosion 2")
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 4, 0.6, false, "Lightning")
		CreatePositionalSound("explosion_impact", ROOTPART.Position, 4, 0.5, false, "Impact")
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.4, false, "Dimensional rift")
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.3, false, "Cosmic")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.8, false, "Reality tear")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.4, false, "Plasma")
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.5, false, "Fire whoosh")

		-- MASSIVE EXPLOSION EFFECT
		chargeSphere:Destroy()
		for _, orbital in ipairs(orbitals) do
			if orbital.Parent then orbital:Destroy() end
		end

		-- Create blinding flash
		local flash = Instance.new("ColorCorrectionEffect")
		flash.Brightness = 1
		flash.Contrast = 0.5
		flash.Saturation = 0
		flash.Parent = Lighting
		TweenService:Create(flash, TweenInfo.new(0.5), {Brightness = 0}):Play()
		Debris:AddItem(flash, 1)

		-- Multiple massive explosion waves
		for explosion = 1, 25 do
			local randomColor = Color3.new(MRANDOM(7, 10)/10, MRANDOM(3, 8)/10, MRANDOM(8, 10)/10)

			-- Giant sphere explosions
			CreateEffect("Sphere", ROOTPART.CFrame, VT(30, 30, 30), VT(100 + explosion*20, 100 + explosion*20, 100 + explosion*20), 
				randomColor, 1.5, nil, 5)

			-- Ring explosions
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(20, 20, 5), VT(80 + explosion*15, 80 + explosion*15, 5), randomColor, 1.2, nil, 4)

			-- Devastating damage
			ApplyAoE(ROOTPART.Position, 45 + explosion*10, 200, 80)

			task.wait(0.15)
		end

		-- Lightning storms from explosion
		for lightning = 1, 30 do
			local targetPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 0, MRANDOM(-100, 100))
			local startPos = targetPos + VT(0, 150, 0)

			local bolt = CreatePart(VT(12, 150, 12), CF(startPos) * CF(0, -75, 0), Color3.new(1, 1, 0.8), Enum.Material.Neon, 0.1, true)
			bolt.Shape = Enum.PartType.Ball
			TweenService:Create(bolt, TweenInfo.new(0.3), {Transparency = 1}):Play()
			Debris:AddItem(bolt, 0.3)

			ApplyAoE(targetPos, 25, 150, 50)
		end

		-- Fire tornadoes
		for tornado = 1, 8 do
			local tornadoPos = ROOTPART.Position + VT(MRANDOM(-60, 60), 0, MRANDOM(-60, 60))
			for segment = 1, 15 do
				local fire = CreatePart(VT(15 - segment*0.5, 8, 15 - segment*0.5), 
					CF(tornadoPos) * CF(0, segment*6, 0) * ANGLES(0, RAD(segment*24), 0), 
					Color3.new(1, MRANDOM(3, 8)/10, 0), Enum.Material.Neon, 0.3, true)
				fire.Shape = Enum.PartType.Cylinder
				TweenService:Create(fire, TweenInfo.new(2), {Transparency = 1}):Play()
				Debris:AddItem(fire, 2)
			end
			ApplyAoE(tornadoPos, 30, 180, 60)
		end

		-- Shockwave rings on ground
		for shockwave = 1, 40 do
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(90), 0, 0), 
				VT(10, 10, 10), VT(50 + shockwave*25, 50 + shockwave*25, 10), 
				Color3.new(1, 0.5, 0.2), 0.5, nil, 2)
		end

		-- Final massive devastation
		CreateEffect("Sphere", ROOTPART.CFrame, VT(50, 50, 50), VT(300, 300, 300), Color3.new(1, 1, 1), 4, nil, 10)
		ApplyAoE(ROOTPART.Position, 150, 500, 200)

		task.wait(3)

		-- Restore lighting gradually
		TweenService:Create(Lighting, TweenInfo.new(5), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogEnd = originalFogEnd,
			FogColor = originalFogColor
		}):Play()

		task.wait(2)
		Attack = false
	end

	-- ========================================
	-- ENHANCED CHAOTIC ATTACK FUNCTIONS
	-- ========================================

	-- Attack 1: APOCALYPTIC LIGHTNING STORM - EPIC ENHANCED
	local function LightningStrike()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogEnd = Lighting.FogEnd

		DisplayTaunt(AttackTaunts.Lightning[MRANDOM(1, #AttackTaunts.Lightning)], 4, Color3.fromRGB(255, 255, 100))
		CreatePositionalSound("lightning_charge", ROOTPART.Position, 3, 0.9, false, "Lightning charge")

		-- PHASE 1: STORM FORMATION - Sky darkens, massive storm clouds form
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.05,
			Ambient = Color3.new(0.1, 0.1, 0.2),
			ColorShift_Top = Color3.new(0.3, 0.3, 0.6),
			FogEnd = 500
		}):Play()

		-- Create massive storm eye above
		local stormEye = CreatePart(VT(80, 30, 80), ROOTPART.CFrame * CF(0, 150, 0), Color3.new(0.15, 0.15, 0.3), Enum.Material.ForceField, 0.5, true)
		stormEye.Shape = Enum.PartType.Ball
		TweenService:Create(stormEye, TweenInfo.new(3), {Size = VT(150, 40, 150)}):Play()

		-- Lightning pillars circling the arena
		for pillar = 1, 16 do
			local angle = pillar * 22.5
			local distance = 100
			local pillarPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * distance, 0, math.sin(RAD(angle)) * distance)
			local electricPillar = CreatePart(VT(15, 5, 15), CF(pillarPos), Color3.new(0.7, 0.7, 1), Enum.Material.Neon, 0.3, true)
			TweenService:Create(electricPillar, TweenInfo.new(2), {
				Size = VT(15, 200, 15),
				CFrame = CF(pillarPos) * CF(0, 100, 0)
			}):Play()
			Debris:AddItem(electricPillar, 8)
		end

		-- Floating storm clouds with constant discharge
		for i = 1, 15 do
			local cloud = CreatePart(VT(50, 20, 50), ROOTPART.CFrame * CF(MRANDOM(-100, 100), 120 + i*10, MRANDOM(-100, 100)), 
				Color3.new(0.15, 0.15, 0.25), Enum.Material.ForceField, 0.3, true)
			cloud.Shape = Enum.PartType.Ball

			-- Continuous electrical discharge
			coroutine.wrap(function()
				for pulse = 1, 20 do
					if DEAD then break end
					if cloud.Parent then
						local discharge = CreatePart(VT(8, 8, 8), cloud.CFrame * CF(MRANDOM(-20, 20), MRANDOM(-10, 10), MRANDOM(-20, 20)), 
							Color3.new(1, 1, 0.9), Enum.Material.Neon, 0.2, true)
						discharge.Shape = Enum.PartType.Ball
						TweenService:Create(discharge, TweenInfo.new(0.5), {
							Size = VT(15, 15, 15),
							Transparency = 1
						}):Play()
						Debris:AddItem(discharge, 0.5)
						task.wait(0.15)
					end
				end
			end)()
			Debris:AddItem(cloud, 10)
		end

		task.wait(2)

		-- PHASE 2: CHAIN LIGHTNING APOCALYPSE
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 4, 0.6, false, "Lightning crack")

		-- Brighter flash lighting
		TweenService:Create(Lighting, TweenInfo.new(0.1), {Brightness = 1}):Play()
		task.wait(0.1)
		TweenService:Create(Lighting, TweenInfo.new(0.3), {Brightness = 0.05}):Play()

		-- Massive coordinated lightning strikes
		for wave = 1, 3 do
			-- Ring pattern strikes
			for ring = 1, 12 do
				local angle = ring * 30
				local distance = 60 + wave*20
				local targetPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * distance, 0, math.sin(RAD(angle)) * distance)
				local startPos = stormEye.Position

				-- Realistic jagged lightning bolt with branches
				CreateLightningBolt(startPos, targetPos, 18, Color3.new(1, 1, 0.8), MRANDOM(4, 8), 0.4)

				-- Ground impact explosion
				CreateEffect("Sphere", CF(targetPos), VT(20, 20, 20), VT(80, 80, 80), Color3.new(1, 1, 0.7), 0.6, nil, 3)
				CreateEffect("Ring", CF(targetPos) * ANGLES(RAD(90), 0, 0), VT(15, 15, 15), VT(70, 70, 15), Color3.new(0.8, 0.8, 1), 0.5, nil, 2)
				ApplyAoE(targetPos, 45, 220, 100)

				-- Electric field damage zone
				local field = CreatePart(VT(35, 5, 35), CF(targetPos), Color3.new(1, 1, 0.8), Enum.Material.Neon, 0.4, true)
				field.Shape = Enum.PartType.Ball

				-- Arcing electricity from field
				for arc = 1, 6 do
					local arcPart = CreatePart(VT(4, 20, 4), field.CFrame * CF(MRANDOM(-20, 20), 10, MRANDOM(-20, 20)), 
						Color3.new(1, 1, 0.95), Enum.Material.Neon, 0.3, true)
					arcPart.Shape = Enum.PartType.Ball
					TweenService:Create(arcPart, TweenInfo.new(1.2), {
						CFrame = arcPart.CFrame + VT(0, 15, 0),
						Transparency = 1
					}):Play()
					Debris:AddItem(arcPart, 1.2)
				end

				-- Field pulses damage
				coroutine.wrap(function()
					for pulse = 1, 8 do
						ApplyAoE(targetPos, 30, 40, 20)
						task.wait(0.3)
					end
				end)()

				TweenService:Create(field, TweenInfo.new(2.5), {Transparency = 1}):Play()
				Debris:AddItem(field, 2.5)
			end
			task.wait(0.4)
		end

		task.wait(0.5)

		-- PHASE 3: RANDOM CHAOS STRIKES
		for chaos = 1, 35 do
			local targetPos = ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120))
			local startPos = stormEye.Position

			-- Realistic jagged lightning bolt
			local boltColor = Color3.new(MRANDOM(8, 10)/10, MRANDOM(8, 10)/10, 1)
			CreateLightningBolt(startPos, targetPos, 20, boltColor, MRANDOM(3, 6), 0.3)

			-- Flash effect
			if chaos % 5 == 0 then
				TweenService:Create(Lighting, TweenInfo.new(0.05), {Brightness = 0.8}):Play()
				task.wait(0.05)
				TweenService:Create(Lighting, TweenInfo.new(0.2), {Brightness = 0.05}):Play()
			end

			CreateEffect("Sphere", CF(targetPos), VT(15, 15, 15), VT(60, 60, 60), Color3.new(1, 1, 0.8), 0.5, nil, 2)
			ApplyAoE(targetPos, 40, 200, 90)

			task.wait(0.08)
		end

		-- Cleanup and restore
		stormEye:Destroy()
		task.wait(1)
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogEnd = originalFogEnd
		}):Play()

		task.wait(0.5)
		Attack = false
		AttackCooldowns.LightningStrike = tick()
	end

	-- Attack 2: CATASTROPHIC METEOR APOCALYPSE - EPIC ENHANCED
	local function MeteorShower()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogColor = Lighting.FogColor
		local originalFogEnd = Lighting.FogEnd

		DisplayTaunt(AttackTaunts.Meteor[MRANDOM(1, #AttackTaunts.Meteor)], 4, Color3.fromRGB(255, 100, 0))
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.4, false, "Cosmic ambient")

		-- PHASE 1: SKY TURNS FIERY ORANGE
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.3,
			Ambient = Color3.new(0.4, 0.15, 0),
			ColorShift_Top = Color3.new(1, 0.4, 0),
			FogColor = Color3.new(0.4, 0.1, 0),
			FogEnd = 400
		}):Play()

		-- Create giant meteor portal in sky
		local meteorPortal = CreatePart(VT(100, 50, 100), ROOTPART.CFrame * CF(0, 200, 0), Color3.new(1, 0.3, 0), Enum.Material.ForceField, 0.4, true)
		meteorPortal.Shape = Enum.PartType.Ball
		TweenService:Create(meteorPortal, TweenInfo.new(2), {Size = VT(180, 70, 180)}):Play()

		-- Fire pillars mark impact zones - Better spread using circular distribution
		local targetPositions = {}
		local numTargets = 25  -- More targets for better spread
		for i = 1, numTargets do
			local angle = (i / numTargets) * math.pi * 2
			local radius = 40 + (i % 3) * 30  -- Vary radius for better spread
			local pos = ROOTPART.Position + VT(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			-- Raycast to find actual ground position
			local raycast = workspace:Raycast(pos + VT(0, 500, 0), VT(0, -1000, 0))
			if raycast then
				pos = raycast.Position
			end
			table.insert(targetPositions, pos)

			-- Fiery warning pillar
			local warning = CreatePart(VT(20, 5, 20), CF(pos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.3, true)
			TweenService:Create(warning, TweenInfo.new(2), {
				Size = VT(20, 150, 20),
				CFrame = CF(pos) * CF(0, 75, 0)
			}):Play()
			ApplyAoE(pos, 15, 50, 20)
			Debris:AddItem(warning, 8)
		end

		task.wait(2)

		-- PHASE 2: METEOR BOMBARDMENT
		CreatePositionalSound("explosion_impact", ROOTPART.Position, 4, 0.5, false, "Explosion impact")

		-- Sky flashes brighter
		TweenService:Create(Lighting, TweenInfo.new(1), {
			Brightness = 0.6,
			Ambient = Color3.new(0.6, 0.2, 0)
		}):Play()

		-- Massive meteor shower
		for wave = 1, 3 do
			for _, pos in ipairs(targetPositions) do
				coroutine.wrap(function()
					-- Multiple giant meteors per position - Better spread
					for m = 1, MRANDOM(2, 3) do
						local spreadAngle = (m / MRANDOM(2, 3)) * math.pi * 2
						local spreadRadius = MRANDOM(20, 40)
						local meteorPos = pos + VT(math.cos(spreadAngle) * spreadRadius, 0, math.sin(spreadAngle) * spreadRadius)
						-- Raycast to find actual ground
						local groundRay = workspace:Raycast(meteorPos + VT(0, 500, 0), VT(0, -1000, 0))
						if groundRay then
							meteorPos = groundRay.Position
						end
						local meteorSize = MRANDOM(15, 25)
						local startCFrame = CF(meteorPortal.Position) * CF(MRANDOM(-50, 50), 0, MRANDOM(-50, 50))
						local meteor = CreatePart(VT(meteorSize, meteorSize, meteorSize), startCFrame, 
							Color3.new(0.3, 0.2, 0.15), Enum.Material.Concrete, 0, false)
						meteor.Shape = Enum.PartType.Ball

						-- Fire core (bright hot center)
						local fireCore = CreatePart(VT(meteorSize*0.6, meteorSize*0.6, meteorSize*0.6), meteor.CFrame,
							Color3.new(1, MRANDOM(5, 8)/10, 0), Enum.Material.Neon, 0, false)
						fireCore.Shape = Enum.PartType.Ball

						-- Weld fire core to meteor
						local coreWeld = Instance.new("WeldConstraint")
						coreWeld.Part0 = meteor
						coreWeld.Part1 = fireCore
						coreWeld.Parent = meteor

						-- Bright meteor light
						local light = Instance.new("PointLight")
						light.Brightness = 25
						light.Color = Color3.new(1, 0.5, 0.2)
						light.Range = 100
						light.Parent = meteor

						-- Realistic fire trail with multiple layers
						coroutine.wrap(function()
							while meteor.Parent do
								-- Main fire trail (orange/yellow)
								local trail = CreatePart(VT(meteorSize*1.2, meteorSize*1.2, meteorSize*1.2), meteor.CFrame, 
									Color3.new(1, MRANDOM(4, 7)/10, 0), Enum.Material.Neon, 0.2, true)
								trail.Shape = Enum.PartType.Ball
								TweenService:Create(trail, TweenInfo.new(1.2), {
									Size = VT(meteorSize*0.3, meteorSize*0.3, meteorSize*0.3),
									Transparency = 1
								}):Play()
								Debris:AddItem(trail, 1.2)

								-- Outer flame layer (red/orange)
								local outerFlame = CreatePart(VT(meteorSize*1.5, meteorSize*1.5, meteorSize*1.5), meteor.CFrame,
									Color3.new(1, MRANDOM(2, 4)/10, 0), Enum.Material.Neon, 0.4, true)
								outerFlame.Shape = Enum.PartType.Ball
								TweenService:Create(outerFlame, TweenInfo.new(1.5), {
									Size = VT(meteorSize*0.2, meteorSize*0.2, meteorSize*0.2),
									Transparency = 1
								}):Play()
								Debris:AddItem(outerFlame, 1.5)

								-- Spark particles
								for spark = 1, 3 do
									local sparkPart = CreatePart(VT(2, 2, 2), meteor.CFrame * CF(MRANDOM(-meteorSize/2, meteorSize/2), MRANDOM(-meteorSize/2, meteorSize/2), MRANDOM(-meteorSize/2, meteorSize/2)),
										Color3.new(1, MRANDOM(6, 9)/10, 0), Enum.Material.Neon, 0.1, true)
									sparkPart.Shape = Enum.PartType.Ball
									local sparkVel = Instance.new("BodyVelocity")
									sparkVel.MaxForce = VT(1e9, 1e9, 1e9)
									sparkVel.Velocity = VT(MRANDOM(-15, 15), MRANDOM(-10, 5), MRANDOM(-15, 15))
									sparkVel.Parent = sparkPart
									TweenService:Create(sparkPart, TweenInfo.new(0.8), {
										Size = VT(0.5, 0.5, 0.5),
										Transparency = 1
									}):Play()
									Debris:AddItem(sparkPart, 0.8)
								end

								task.wait(0.04)
							end
						end)()

						-- Velocity towards target
						local direction = (meteorPos - meteor.Position).Unit
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = direction * 200
						bv.Parent = meteor

						local hitDebounce = false
						local lastY = meteor.Position.Y
						-- Check for ground collision using raycast and position
						coroutine.wrap(function()
							while meteor.Parent do
								local currentY = meteor.Position.Y
								-- Raycast downward to detect ground
								local groundRay = workspace:Raycast(meteor.Position, VT(0, -meteorSize, 0))
								if groundRay or (lastY - currentY < 0.1 and currentY < ROOTPART.Position.Y + 10) then
									if not hitDebounce and groundRay and isValidMeteorCollision(groundRay.Instance) then
										hitDebounce = true
										local impactPos = groundRay and groundRay.Position or meteor.Position

										-- MASSIVE EXPLOSION
										CreatePositionalSound("explosion_impact", impactPos, 3, MRANDOM(7, 12)/10, false, "Meteor impact")
										for explosion = 1, 6 do
											local expPos = impactPos + VT(MRANDOM(-20, 20), MRANDOM(-5, 5), MRANDOM(-20, 20))
											CreateEffect("Sphere", CF(expPos), VT(25, 25, 25), VT(90, 90, 90), 
												Color3.new(1, MRANDOM(3, 7)/10, 0), 0.8, nil, 4)
											CreateEffect("Ring", CF(expPos) * ANGLES(RAD(90), 0, 0), VT(20, 20, 20), VT(100, 100, 20), 
												Color3.new(1, 0.5, 0), 0.6, nil, 3)
											ApplyAoE(expPos, 50, 280, 120)
										end

										-- Impact crater effect
										local crater = CreatePart(VT(60, 5, 60), CF(impactPos), Color3.new(0.3, 0.15, 0.1), Enum.Material.Neon, 0.4, true)
										TweenService:Create(crater, TweenInfo.new(3), {Transparency = 1}):Play()
										Debris:AddItem(crater, 3)

										-- Lava pools with filled ring mesh
										for lava = 1, 4 do
											local lavaPos = impactPos + VT(MRANDOM(-25, 25), 0, MRANDOM(-25, 25))
											-- Raycast to ground
											local lavaRay = workspace:Raycast(lavaPos + VT(0, 10, 0), VT(0, -20, 0))
											if lavaRay then
												lavaPos = lavaRay.Position
											end
											local lavaSize = MRANDOM(20, 35)
											local lavaPool = CreatePart(VT(lavaSize, 0.5, lavaSize), CF(lavaPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
											local mesh = Instance.new("SpecialMesh")
											mesh.MeshType = Enum.MeshType.FileMesh
											mesh.MeshId = "rbxassetid://3270017"  -- Ring mesh
											mesh.Scale = VT(lavaSize, lavaSize, 0.5)  -- Filled ring
											mesh.Parent = lavaPool

											-- Lava bubbles
											coroutine.wrap(function()
												for bubble = 1, 25 do
													local lavaBubble = CreatePart(VT(2, 2, 2), lavaPool.CFrame * CF(MRANDOM(-10, 10), 0, MRANDOM(-10, 10)), 
														Color3.new(1, MRANDOM(4, 7)/10, 0), Enum.Material.Neon, 0.2, true)
													lavaBubble.Shape = Enum.PartType.Ball
													TweenService:Create(lavaBubble, TweenInfo.new(1.2), {
														CFrame = lavaBubble.CFrame + VT(0, 12, 0),
														Size = VT(5, 5, 5),
														Transparency = 1
													}):Play()
													Debris:AddItem(lavaBubble, 1.2)
													task.wait(0.3)
												end
											end)()

											-- Lava damage
											coroutine.wrap(function()
												for i = 1, 30 do
													ApplyAoE(lavaPos, 25, 35, 15)
													task.wait(0.5)
												end
											end)()

											Debris:AddItem(lavaPool, 15)
										end

										-- Debris explosion
										for debris = 1, 12 do
											local debrisPart = CreatePart(VT(4, 4, 4), CF(impactPos), Color3.new(0.7, 0.3, 0), Enum.Material.Neon, 0, false)
											local debrisVel = Instance.new("BodyVelocity")
											debrisVel.MaxForce = VT(1e9, 1e9, 1e9)
											debrisVel.Velocity = VT(MRANDOM(-80, 80), MRANDOM(60, 120), MRANDOM(-80, 80))
											debrisVel.Parent = debrisPart
											TweenService:Create(debrisPart, TweenInfo.new(3), {Transparency = 1}):Play()
											Debris:AddItem(debrisPart, 3)
										end

										meteor:Destroy()
									end
								end
								task.wait(0.05)
							end
						end)()

						meteor.Touched:Connect(function(part)
							if not hitDebounce and part.Parent ~= CHARACTER and part.Name ~= "Base" then
								hitDebounce = true
								local impactPos = meteor.Position
								-- Raycast to find ground
								local groundRay = workspace:Raycast(impactPos, VT(0, -50, 0))
								if groundRay then
									impactPos = groundRay.Position
								end

								CreatePositionalSound("explosion_impact", impactPos, 3, MRANDOM(7, 12)/10, false, "Meteor impact")
								CreateEffect("Sphere", CF(impactPos), VT(25, 25, 25), VT(90, 90, 90), 
									Color3.new(1, MRANDOM(3, 7)/10, 0), 0.8, nil, 4)
								CreateEffect("Ring", CF(impactPos) * ANGLES(RAD(90), 0, 0), VT(20, 20, 20), VT(100, 100, 20), 
									Color3.new(1, 0.5, 0), 0.6, nil, 3)
								ApplyAoE(impactPos, 50, 280, 120)

								-- Lava pool
								local lavaPos = impactPos + VT(MRANDOM(-25, 25), 0, MRANDOM(-25, 25))
								local lavaRay = workspace:Raycast(lavaPos + VT(0, 10, 0), VT(0, -20, 0))
								if lavaRay then
									lavaPos = lavaRay.Position
								end
								local lavaSize = MRANDOM(20, 35)
								local lavaPool = CreatePart(VT(lavaSize, 0.5, lavaSize), CF(lavaPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
								local mesh = Instance.new("SpecialMesh")
								mesh.MeshType = Enum.MeshType.FileMesh
								mesh.MeshId = "rbxassetid://3270017"
								mesh.Scale = VT(lavaSize, lavaSize, 0.5)
								mesh.Parent = lavaPool

								coroutine.wrap(function()
									for i = 1, 20 do
										ApplyAoE(lavaPos, 20, 30, 10)
										task.wait(0.5)
									end
								end)()

								Debris:AddItem(lavaPool, 12)
								meteor:Destroy()
							end
						end)

						Debris:AddItem(meteor, 8)
						task.wait(0.05)
					end
				end)()
			end
			task.wait(1.5)
		end

		-- PHASE 3: FINAL BARRAGE - Random chaos meteors (better spread)
		for chaos = 1, 30 do
			local angle = (chaos / 30) * math.pi * 2
			local radius = MRANDOM(60, 150)
			local randomPos = ROOTPART.Position + VT(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			-- Raycast to ground
			local groundRay = workspace:Raycast(randomPos + VT(0, 500, 0), VT(0, -1000, 0))
			if groundRay then
				randomPos = groundRay.Position
			end
			local meteorSize = MRANDOM(15, 25)
			local startCFrame = CF(meteorPortal.Position + VT(MRANDOM(-40, 40), 0, MRANDOM(-40, 40)))
			local meteor = CreatePart(VT(meteorSize, meteorSize, meteorSize), startCFrame, 
				Color3.new(0.3, 0.2, 0.15), Enum.Material.Concrete, 0, false)
			meteor.Shape = Enum.PartType.Ball

			-- Fire core
			local fireCore = CreatePart(VT(meteorSize*0.6, meteorSize*0.6, meteorSize*0.6), meteor.CFrame,
				Color3.new(1, MRANDOM(5, 8)/10, 0), Enum.Material.Neon, 0, false)
			fireCore.Shape = Enum.PartType.Ball

			local coreWeld = Instance.new("WeldConstraint")
			coreWeld.Part0 = meteor
			coreWeld.Part1 = fireCore
			coreWeld.Parent = meteor

			-- Bright light
			local light = Instance.new("PointLight")
			light.Brightness = 22
			light.Color = Color3.new(1, 0.5, 0.2)
			light.Range = 90
			light.Parent = meteor

			-- Realistic fire trail
			coroutine.wrap(function()
				while meteor.Parent do
					local trail = CreatePart(VT(meteorSize*1.2, meteorSize*1.2, meteorSize*1.2), meteor.CFrame,
						Color3.new(1, MRANDOM(4, 7)/10, 0), Enum.Material.Neon, 0.2, true)
					trail.Shape = Enum.PartType.Ball
					TweenService:Create(trail, TweenInfo.new(1.2), {
						Size = VT(meteorSize*0.3, meteorSize*0.3, meteorSize*0.3),
						Transparency = 1
					}):Play()
					Debris:AddItem(trail, 1.2)

					local outerFlame = CreatePart(VT(meteorSize*1.5, meteorSize*1.5, meteorSize*1.5), meteor.CFrame,
						Color3.new(1, MRANDOM(2, 4)/10, 0), Enum.Material.Neon, 0.4, true)
					outerFlame.Shape = Enum.PartType.Ball
					TweenService:Create(outerFlame, TweenInfo.new(1.5), {
						Size = VT(meteorSize*0.2, meteorSize*0.2, meteorSize*0.2),
						Transparency = 1
					}):Play()
					Debris:AddItem(outerFlame, 1.5)

					task.wait(0.04)
				end
			end)()

			local direction = (randomPos - meteor.Position).Unit
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = VT(1e9, 1e9, 1e9)
			bv.Velocity = direction * 250
			bv.Parent = meteor

			local hitDebounce = false
			local lastY = meteor.Position.Y
			-- Ground detection for phase 3 meteors
			coroutine.wrap(function()
				while meteor.Parent do
					local currentY = meteor.Position.Y
					local groundRay = workspace:Raycast(meteor.Position, VT(0, -meteorSize, 0))
					if groundRay or (lastY - currentY < 0.1 and currentY < ROOTPART.Position.Y + 10) then
						if not hitDebounce and groundRay and isValidMeteorCollision(groundRay.Instance) then
							hitDebounce = true
							local impactPos = groundRay and groundRay.Position or meteor.Position
							CreatePositionalSound("explosion_impact", impactPos, 3, MRANDOM(7, 12)/10, false, "Meteor impact")
							CreateEffect("Sphere", CF(impactPos), VT(20, 20, 20), VT(80, 80, 80), Color3.new(1, 0.4, 0), 0.7, nil, 3)
							ApplyAoE(impactPos, 45, 260, 110)

							-- Lava pool with filled ring
							local lavaPos = impactPos
							local lavaSize = MRANDOM(25, 40)
							local lavaPool = CreatePart(VT(lavaSize, 0.5, lavaSize), CF(lavaPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
							local lavaMesh = Instance.new("SpecialMesh")
							lavaMesh.MeshType = Enum.MeshType.FileMesh
							lavaMesh.MeshId = "rbxassetid://3270017"
							lavaMesh.Scale = VT(lavaSize, lavaSize, 0.5)
							lavaMesh.Parent = lavaPool

							-- Lava damage
							coroutine.wrap(function()
								for i = 1, 20 do
									ApplyAoE(lavaPos, 20, 30, 10)
									task.wait(0.5)
								end
							end)()

							Debris:AddItem(lavaPool, 12)
							meteor:Destroy()
						end
					end
					lastY = currentY
					task.wait(0.05)
				end
			end)()

			meteor.Touched:Connect(function(part)
				if not hitDebounce and part.Parent ~= CHARACTER and part.Name ~= "Base" then
					hitDebounce = true
					local impactPos = meteor.Position
					local groundRay = workspace:Raycast(impactPos, VT(0, -50, 0))
					if groundRay then
						impactPos = groundRay.Position
					end
					CreatePositionalSound("explosion_impact", impactPos, 3, MRANDOM(7, 12)/10, false, "Meteor impact")
					CreateEffect("Sphere", CF(impactPos), VT(20, 20, 20), VT(80, 80, 80), Color3.new(1, 0.4, 0), 0.7, nil, 3)
					ApplyAoE(impactPos, 45, 260, 110)

					-- Lava pool
					local lavaPos = impactPos
					local lavaSize = MRANDOM(25, 40)
					local lavaPool = CreatePart(VT(lavaSize, 0.5, lavaSize), CF(lavaPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
					local lavaMesh = Instance.new("SpecialMesh")
					lavaMesh.MeshType = Enum.MeshType.FileMesh
					lavaMesh.MeshId = "rbxassetid://3270017"
					lavaMesh.Scale = VT(lavaSize, lavaSize, 0.5)
					lavaMesh.Parent = lavaPool

					coroutine.wrap(function()
						for i = 1, 20 do
							ApplyAoE(lavaPos, 20, 30, 10)
							task.wait(0.5)
						end
					end)()

					Debris:AddItem(lavaPool, 12)
					meteor:Destroy()
				end
			end)

			Debris:AddItem(meteor, 6)
			task.wait(0.06)
		end

		-- Cleanup
		meteorPortal:Destroy()
		task.wait(1)
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogColor = originalFogColor,
			FogEnd = originalFogEnd
		}):Play()

		task.wait(0.5)
		Attack = false
		AttackCooldowns.MeteorShower = tick()
	end

	-- Attack 3: REALITY-TEARING DIMENSIONAL RIFTS - EPIC ENHANCED
	local function DimensionalRifts()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogEnd = Lighting.FogEnd
		local originalGravity = workspace.Gravity

		DisplayTaunt(AttackTaunts.Dimensional[MRANDOM(1, #AttackTaunts.Dimensional)], 4, Color3.fromRGB(150, 0, 255))

		local riftSounds = {"dimensional_rift", "reality_tear", "time_distortion"}
		CreatePositionalSound(riftSounds[MRANDOM(1, #riftSounds)], ROOTPART.Position, 3, 0.4, false, "Dimensional rift")

		-- PHASE 1: REALITY DISTORTION - Purple void effect (toned down)
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.3,  -- Less dark
			Ambient = Color3.new(0.25, 0.05, 0.35),  -- Less intense
			ColorShift_Top = Color3.new(0.3, 0.05, 0.5),  -- Toned down
			FogEnd = 450  -- More visibility
		}):Play()

		-- Gravity fluctuates
		workspace.Gravity = 140

		-- Create giant void tear in sky
		local voidTear = CreatePart(VT(120, 80, 10), ROOTPART.CFrame * CF(0, 150, 0), Color3.new(0.1, 0, 0.5), Enum.Material.ForceField, 0.3, true)
		TweenService:Create(voidTear, TweenInfo.new(2), {Size = VT(180, 120, 10)}):Play()

		-- Reality distortion waves
		for wave = 1, 8 do
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(20, 20, 5), VT(150 + wave*20, 150 + wave*20, 5), Color3.new(0.3, 0, 0.7), 1, nil, 3)
		end

		-- PHASE 2: MASSIVE DIMENSIONAL RIFTS
		local soloMode = #cachedPlayers == 0

		-- Create 20 giant rifts in chaotic positions
		for r = 1, 20 do
			local riftPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(15, 80), MRANDOM(-120, 120))

			-- Giant swirling rift portal (toned down)
			local rift = CreatePart(VT(35, 35, 5), CF(riftPos), Color3.new(0.1, 0, 0.6), Enum.Material.ForceField, 0.4, true)  -- More transparent
			local riftMesh = Instance.new("SpecialMesh")
			riftMesh.MeshType = Enum.MeshType.Sphere
			riftMesh.Scale = VT(1, 1, 0.15)
			riftMesh.Parent = rift

			-- Swirling portal layers
			for layer = 1, 5 do
				local portalLayer = CreatePart(VT(30 - layer*3, 30 - layer*3, 3), rift.CFrame, 
					Color3.new(0.2 + layer*0.1, 0, 0.7 + layer*0.05), Enum.Material.Neon, 0.2, true)
				local layerMesh = Instance.new("SpecialMesh")
				layerMesh.MeshType = Enum.MeshType.Sphere
				layerMesh.Scale = VT(1, 1, 0.1)
				layerMesh.Parent = portalLayer

				coroutine.wrap(function()
					local rotation = layer * 45
					while portalLayer.Parent do
						rotation = rotation + (2 + layer)
						portalLayer.CFrame = rift.CFrame * ANGLES(0, 0, RAD(rotation))
						task.wait()
					end
				end)()
				Debris:AddItem(portalLayer, 10)
			end

			CreateSound(riftSounds[MRANDOM(1, #riftSounds)], rift, 2, MRANDOM(7, 12)/10, false, "Rift sound")
			TweenService:Create(rift, TweenInfo.new(1.5), {Size = VT(50, 50, 5)}):Play()

			-- MASSIVE PROJECTILE BARRAGE
			coroutine.wrap(function()
				for wave = 1, 20 do
					if DEAD then break end
					-- Spawn multiple projectiles per wave
					for proj = 1, 3 do
						local projectile = CreatePart(VT(7, 7, 7), rift.CFrame * CF(MRANDOM(-15, 15), MRANDOM(-15, 15), 0), 
							Color3.new(0.3, 0, MRANDOM(7, 10)/10), Enum.Material.Neon, 0, false)
						projectile.Shape = Enum.PartType.Ball

						-- Projectile trail
						coroutine.wrap(function()
							while projectile.Parent do
								local trail = CreatePart(VT(5, 5, 5), projectile.CFrame, Color3.new(0.2, 0, 0.5), Enum.Material.Neon, 0.4, true)
								trail.Shape = Enum.PartType.Ball
								TweenService:Create(trail, TweenInfo.new(1), {Size = VT(1, 1, 1), Transparency = 1}):Play()
								Debris:AddItem(trail, 1)
								task.wait(0.08)
							end
						end)()

						-- Target direction
						local direction
						if soloMode or #cachedPlayers == 0 then
							direction = VT(MRANDOM(-100, 100), MRANDOM(-50, -10), MRANDOM(-100, 100)).Unit
						else
							local validTargets = {}
							for _, playerData in pairs(cachedPlayers) do
								if playerData.RootPart and playerData.Model then
									table.insert(validTargets, Players:GetPlayerFromCharacter(playerData.Model))
								end
							end
							if #validTargets > 0 then
								local target = validTargets[MRANDOM(1, #validTargets)]
								if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
									direction = (target.Character.HumanoidRootPart.Position - riftPos).Unit
								else
									direction = VT(MRANDOM(-100, 100), MRANDOM(-50, -10), MRANDOM(-100, 100)).Unit
								end
							else
								direction = VT(MRANDOM(-100, 100), MRANDOM(-50, -10), MRANDOM(-100, 100)).Unit
							end
						end

						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = direction * 100
						bv.Parent = projectile

						local hitDebounce = false
						projectile.Touched:Connect(function(hit)
							if not hitDebounce and hit.Parent ~= CHARACTER and hit.Parent ~= Effects then
								hitDebounce = true
								-- Explosive impact
								for exp = 1, 4 do
									local expPos = projectile.Position + VT(MRANDOM(-12, 12), MRANDOM(-5, 5), MRANDOM(-12, 12))
									CreateEffect("Sphere", CF(expPos), VT(10, 10, 10), VT(35, 35, 35), Color3.new(0.3, 0, 0.8), 0.6, nil, 2)
									ApplyAoE(expPos, 25, 180, 80)
								end
								projectile:Destroy()
							end
						end)

						Debris:AddItem(projectile, 6)
					end
					task.wait(0.15)
				end

				-- Rift closes with massive explosion
				CreateSound("massive_explosion", rift, 3, MRANDOM(6, 10)/10, false, "Rift explosion")
				CreateEffect("Sphere", rift.CFrame, VT(50, 50, 5), VT(100, 100, 15), Color3.new(0.2, 0, 0.7), 1.5, nil, 4)
				ApplyAoE(riftPos, 50, 250, 100)

				TweenService:Create(rift, TweenInfo.new(2), {Size = VT(0, 0, 5), Transparency = 1}):Play()
				Debris:AddItem(rift, 2)
			end)()

			task.wait(0.1)
		end

		-- PHASE 3: REALITY COLLAPSE
		task.wait(2)
		workspace.Gravity = 80

		-- Giant void explosions
		for collapse = 1, 15 do
			local collapsePos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(-20, 40), MRANDOM(-100, 100))
			CreateEffect("Sphere", CF(collapsePos), VT(20, 20, 20), VT(80, 80, 80), Color3.new(0.2, 0, 0.6), 0.8, nil, 3)
			ApplyAoE(collapsePos, 45, 240, 110)
			task.wait(0.15)
		end

		-- Cleanup
		voidTear:Destroy()
		task.wait(1)
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogEnd = originalFogEnd
		}):Play()
		workspace.Gravity = originalGravity

		task.wait(0.5)
		Attack = false
		AttackCooldowns.DimensionalRifts = tick()
	end

	-- Attack 4: APOCALYPTIC ARCANE DEVASTATION - EPIC ENHANCED
	local function ArcaneDevastation()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogEnd = Lighting.FogEnd

		DisplayTaunt(AttackTaunts.Arcane[MRANDOM(1, #AttackTaunts.Arcane)], 4, Color3.fromRGB(200, 0, 255))
		CreatePositionalSound("energy_beam", ROOTPART.Position, 3, 0.5, false, "Energy beam")

		-- PHASE 1: ARCANE AWAKENING - Purple mystic environment
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.2,
			Ambient = Color3.new(0.2, 0, 0.3),
			ColorShift_Top = Color3.new(0.5, 0, 0.8),
			FogEnd = 380
		}):Play()

		-- Giant arcane circle in sky
		local skyCircle = CreatePart(VT(150, 150, 5), ROOTPART.CFrame * CF(0, 180, 0), Color3.new(0.8, 0, 1), Enum.Material.Neon, 0.3, true)
		local skyMesh = Instance.new("SpecialMesh")
		skyMesh.MeshType = Enum.MeshType.FileMesh
		skyMesh.MeshId = "rbxassetid://3270017"
		skyMesh.Scale = VT(150, 150, 5)
		skyMesh.Parent = skyCircle

		-- Rotate sky circle
		coroutine.wrap(function()
			local rotation = 0
			while skyCircle.Parent do
				rotation = rotation + 1
				skyCircle.CFrame = ROOTPART.CFrame * CF(0, 180, 0) * ANGLES(0, RAD(rotation), 0)
				task.wait()
			end
		end)()

		-- MASSIVE floating arcane symbols around arena
		local symbols = {}
		for s = 1, 16 do
			local symbolAngle = (s / 16) * math.pi * 2
			local symbolHeight = MRANDOM(30, 70)
			local symbolDist = MRANDOM(50, 80)
			local symbolPos = ROOTPART.Position + VT(math.cos(symbolAngle) * symbolDist, symbolHeight, math.sin(symbolAngle) * symbolDist)

			local symbol = CreatePart(VT(30, 30, 3), CF(symbolPos), Color3.new(0.9, 0, 1), Enum.Material.Neon, 0.2, true)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://3270017"
			mesh.Scale = VT(30, 30, 3)
			mesh.Parent = symbol

			table.insert(symbols, symbol)

			-- Symbol rotation with particle streams
			coroutine.wrap(function()
				local rotation = 0
				for i = 1, 150 do
					if DEAD or not symbol.Parent then break end
					rotation = rotation + 3
					symbol.CFrame = CF(symbolPos) * ANGLES(RAD(90), RAD(rotation), 0)

					-- Arcane particles flowing
					if i % 3 == 0 then
						local particle = CreatePart(VT(3, 3, 3), symbol.CFrame * CF(MRANDOM(-12, 12), 0, MRANDOM(-12, 12)), 
							Color3.new(0.8, 0, 1), Enum.Material.Neon, 0.3, true)
						particle.Shape = Enum.PartType.Ball
						TweenService:Create(particle, TweenInfo.new(2), {
							CFrame = particle.CFrame + VT(0, 20, 0),
							Transparency = 1
						}):Play()
						Debris:AddItem(particle, 2)
					end
					task.wait()
				end
			end)()

			Debris:AddItem(symbol, 12)
		end

		task.wait(2)

		-- PHASE 2: TELEGRAPH MARKERS - Giant beam warnings
		local beamTargets = {}
		for b = 1, 30 do
			local beamPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 0, MRANDOM(-100, 100))
			table.insert(beamTargets, beamPos)

			-- Sound for telegraph marker appearance
			if b % 5 == 0 then  -- Play sound every 5 markers to avoid spam
				CreatePositionalSound("energy_beam", beamPos, 1.5, MRANDOM(8, 12)/10, false, "Telegraph marker")
			end

			local telegraph = CreatePart(VT(15, 1, 15), CF(beamPos), Color3.new(1, 0.7, 0), Enum.Material.Neon, 0.2, true)
			local telegraphMesh = Instance.new("SpecialMesh")
			telegraphMesh.MeshType = Enum.MeshType.Sphere
			telegraphMesh.Scale = VT(1, 0.05, 1)
			telegraphMesh.Parent = telegraph

			local telegraphRing = CreatePart(VT(1, 1, 1), CF(beamPos), Color3.new(0.9, 0, 1), Enum.Material.Neon, 0.4, true)
			local ringMesh = Instance.new("SpecialMesh")
			ringMesh.MeshType = Enum.MeshType.FileMesh
			ringMesh.MeshId = "rbxassetid://3270017"
			ringMesh.Scale = VT(8, 8, 1)
			ringMesh.Parent = telegraphRing

			-- Pulsing warning
			coroutine.wrap(function()
				for pulse = 1, 25 do
					if telegraph.Parent then
						local scale = 15 + math.sin(pulse * 0.6) * 5
						TweenService:Create(telegraph, TweenInfo.new(0.12), {Size = VT(scale, 1, scale)}):Play()
						TweenService:Create(ringMesh, TweenInfo.new(0.12), {Scale = VT(scale + 3, scale + 3, 1)}):Play()
					end
					task.wait(0.12)
				end
			end)()

			Debris:AddItem(telegraph, 3)
			Debris:AddItem(telegraphRing, 3)
			task.wait(0.08)
		end

		task.wait(2)

		-- PHASE 3: ARCANE BEAM APOCALYPSE
		CreatePositionalSound("reality_tear", ROOTPART.Position, 4, 0.7, false, "Reality tear")

		-- Brighter purple flash
		TweenService:Create(Lighting, TweenInfo.new(0.2), {Brightness = 0.8}):Play()
		task.wait(0.2)
		TweenService:Create(Lighting, TweenInfo.new(0.5), {Brightness = 0.2}):Play()

		for i, beamPos in ipairs(beamTargets) do
			coroutine.wrap(function()
				-- Charge beams from all symbols
				for _, symbol in ipairs(symbols) do
					if symbol.Parent then
						local chargeBeam = CreatePart(VT(4, 4, (symbol.Position - beamPos).Magnitude), 
							CF(symbol.Position, beamPos) * CF(0, 0, -(symbol.Position - beamPos).Magnitude/2), 
							Color3.new(0.7, 0, 1), Enum.Material.Neon, 0.5, true)
						TweenService:Create(chargeBeam, TweenInfo.new(0.2), {Transparency = 1}):Play()
						Debris:AddItem(chargeBeam, 0.2)
					end
				end

				task.wait(0.15)

				-- GIANT DEVASTATING BEAM
				local beam = CreatePart(VT(25, 200, 25), CF(beamPos + VT(0, 100, 0)), 
					Color3.new(1, 0.3, 1), Enum.Material.Neon, 0.1, true)
				beam.Shape = Enum.PartType.Cylinder

				local coreBeam = CreatePart(VT(12, 200, 12), beam.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)
				coreBeam.Shape = Enum.PartType.Cylinder

				-- MASSIVE EXPLOSIONS - Multiple sounds per laser
				CreatePositionalSound("explosion_impact", beamPos, 2.5, MRANDOM(7, 12)/10, false, "Laser explosion")
				for explosion = 1, 6 do
					local expPos = beamPos + VT(MRANDOM(-15, 15), 0, MRANDOM(-15, 15))
					-- Play explosion sound for each explosion
					if explosion % 2 == 0 then  -- Play sound for every other explosion
						CreatePositionalSound("explosion_impact", expPos, 2, MRANDOM(8, 12)/10, false, "Explosion")
					end
					CreateEffect("Sphere", CF(expPos), VT(20, 20, 20), VT(70, 70, 70), Color3.new(1, 0.3, 1), 0.8, nil, 3)
					CreateEffect("Ring", CF(expPos) * ANGLES(RAD(90), 0, 0), VT(20, 20, 20), VT(80, 80, 20), 
						Color3.new(0.9, 0, 1), 0.6, nil, 2)
					ApplyAoE(expPos, 35, 240, 100)
				end

				-- Arcane residue field
				local residue = CreatePart(VT(40, 1, 40), CF(beamPos), Color3.new(0.8, 0, 1), Enum.Material.Neon, 0.3, true)
				local residueMesh = Instance.new("SpecialMesh")
				residueMesh.MeshType = Enum.MeshType.Sphere
				residueMesh.Scale = VT(1, 0.05, 1)
				residueMesh.Parent = residue

				-- Damage over time
				coroutine.wrap(function()
					for tick = 1, 20 do
						ApplyAoE(beamPos, 30, 40, 15)

						-- Arcane eruptions
						if tick % 2 == 0 then
							local eruption = CreatePart(VT(4, 4, 4), CF(beamPos) * CF(MRANDOM(-15, 15), 0, MRANDOM(-15, 15)), 
								Color3.new(0.9, 0, 1), Enum.Material.Neon, 0.2, true)
							eruption.Shape = Enum.PartType.Ball
							TweenService:Create(eruption, TweenInfo.new(1), {
								CFrame = eruption.CFrame + VT(0, 15, 0),
								Size = VT(8, 8, 8),
								Transparency = 1
							}):Play()
							Debris:AddItem(eruption, 1)
						end
						task.wait(0.4)
					end
				end)()

				TweenService:Create(beam, TweenInfo.new(1.2), {Transparency = 1}):Play()
				TweenService:Create(coreBeam, TweenInfo.new(1.2), {Transparency = 1}):Play()
				TweenService:Create(residue, TweenInfo.new(8), {Transparency = 1}):Play()

				Debris:AddItem(beam, 1.2)
				Debris:AddItem(coreBeam, 1.2)
				Debris:AddItem(residue, 8)
			end)()

			task.wait(0.05)
		end

		-- PHASE 4: FINAL ARCANE COLLAPSE
		task.wait(2)

		-- All symbols converge to center
		for _, symbol in ipairs(symbols) do
			if symbol.Parent then
				TweenService:Create(symbol, TweenInfo.new(2), {
					CFrame = ROOTPART.CFrame * CF(0, 50, 0),
					Size = VT(0, 0, 0),
					Transparency = 1
				}):Play()
			end
		end

		-- Giant central explosion
		task.wait(1.5)
		CreateEffect("Sphere", ROOTPART.CFrame * CF(0, 50, 0), VT(30, 30, 30), VT(150, 150, 150), 
			Color3.new(1, 0.4, 1), 2, nil, 6)
		ApplyAoE(ROOTPART.Position, 80, 300, 130)

		-- Cleanup
		skyCircle:Destroy()
		task.wait(1)
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogEnd = originalFogEnd
		}):Play()

		task.wait(0.5)
		Attack = false
		AttackCooldowns.ArcaneDevastation = tick()
	end

	-- Attack 5: APOCALYPTIC INFERNO TORNADO - EPIC ENHANCED
	local function InfernoTornado()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogColor = Lighting.FogColor
		local originalFogEnd = Lighting.FogEnd

		DisplayTaunt(AttackTaunts.Inferno[MRANDOM(1, #AttackTaunts.Inferno)], 4, Color3.fromRGB(255, 100, 0))
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.5, false, "Fire whoosh")

		-- PHASE 1: INFERNO IGNITION - Fiery orange/red environment
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.4,
			Ambient = Color3.new(0.5, 0.15, 0),
			ColorShift_Top = Color3.new(1, 0.3, 0),
			FogColor = Color3.new(0.4, 0.1, 0),
			FogEnd = 320
		}):Play()

		-- Fire pillars erupt from ground
		for pillar = 1, 12 do
			local angle = pillar * 30
			local distance = 70
			local pillarPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * distance, 0, math.sin(RAD(angle)) * distance)

			local firePillar = CreatePart(VT(20, 10, 20), CF(pillarPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
			TweenService:Create(firePillar, TweenInfo.new(2), {
				Size = VT(20, 140, 20),
				CFrame = CF(pillarPos) * CF(0, 70, 0)
			}):Play()
			ApplyAoE(pillarPos, 25, 100, 40)
			Debris:AddItem(firePillar, 10)
		end

		-- MASSIVE fire tornado formation - Optimized and smoother
		local fireSpheres = {}
		local sphereCount = 25  -- Reduced for better performance

		for s = 1, sphereCount do
			local sphere = CreatePart(VT(12, 12, 12), ROOTPART.CFrame, 
				Color3.new(1, MRANDOM(2, 5)/10, 0), Enum.Material.Neon, 0.1, true)  -- Anchored for smoother movement
			sphere.Shape = Enum.PartType.Ball

			local sphereLight = Instance.new("PointLight")
			sphereLight.Brightness = 20
			sphereLight.Color = Color3.new(1, 0.4, 0)
			sphereLight.Range = 60
			sphereLight.Parent = sphere

			local core = CreatePart(VT(6, 6, 6), sphere.CFrame, Color3.new(1, 0.9, 0.3), Enum.Material.Neon, 0, true)
			core.Shape = Enum.PartType.Ball

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = sphere
			weld.Part1 = core
			weld.Parent = sphere

			table.insert(fireSpheres, {Sphere = sphere, Core = core, Index = s, LastPos = ROOTPART.CFrame})

			-- Epic fire trail with better visuals
			coroutine.wrap(function()
				while sphere.Parent do
					local trail = CreatePart(VT(10, 10, 10), sphere.CFrame, 
						Color3.new(1, MRANDOM(3, 7)/10, 0), Enum.Material.Neon, 0.2, true)
					trail.Shape = Enum.PartType.Ball
					TweenService:Create(trail, TweenInfo.new(1.5), {
						Size = VT(2, 2, 2),
						Transparency = 1
					}):Play()
					Debris:AddItem(trail, 1.5)
					task.wait(0.1)
				end
			end)()
		end

		task.wait(1)

		-- PHASE 2: TORNADO RAMPAGE - Smooth spinning inferno
		local duration = 300
		local lastUpdate = tick()

		coroutine.wrap(function()
			local connection
			connection = RunService.Heartbeat:Connect(function()
				if DEAD then 
					connection:Disconnect()
					return 
				end

				local deltaTime = tick() - lastUpdate
				lastUpdate = tick()
				local frame = math.floor((tick() - (tick() - duration/60)) * 60)

				for _, data in ipairs(fireSpheres) do
					if data.Sphere.Parent then
						local sphere = data.Sphere
						local index = data.Index

						-- Smooth tornado pattern with time-based animation
						local time = tick() * 0.5
						local angleOffset = (index / sphereCount) * math.pi * 2
						local currentAngle = angleOffset + time

						-- Wider radius for more destructive tornado
						local radius = 25 + (index / sphereCount) * 20

						-- Height with smooth spiral
						local baseHeight = (index / sphereCount) * 90
						local height = baseHeight + math.sin(time * 2 + index) * 10

						local x = math.cos(currentAngle) * radius
						local z = math.sin(currentAngle) * radius

						-- Smooth movement using TweenService instead of direct CFrame
						local targetCFrame = ROOTPART.CFrame * CF(x, height, z)
						local currentCFrame = data.LastPos

						-- Lerp for smooth interpolation
						local lerpFactor = math.min(deltaTime * 10, 1)
						local newCFrame = currentCFrame:Lerp(targetCFrame, lerpFactor)

						sphere.CFrame = newCFrame
						if data.Core.Parent then
							data.Core.CFrame = newCFrame
						end
						data.LastPos = newCFrame

						-- Player contact damage and ignition
						for _, playerData in pairs(cachedPlayers) do
							if playerData.RootPart and playerData.Humanoid then
								local distance = (playerData.RootPart.Position - sphere.Position).Magnitude

								if distance < 12 then
									local humanoid = playerData.Humanoid
									humanoid:TakeDamage(60)

									-- Powerful fling
									local flingForce = Instance.new("BodyVelocity")
									flingForce.MaxForce = VT(1e9, 1e9, 1e9)
									flingForce.Velocity = (playerData.RootPart.Position - ROOTPART.Position).Unit * 100 + VT(0, 80, 0)
									flingForce.Parent = playerData.RootPart
									Debris:AddItem(flingForce, 0.4)

									-- Burning effect
									coroutine.wrap(function()
										for burn = 1, 25 do
											if not playerData.Model or not playerData.Model.Parent then break end

											local firePart = CreatePart(VT(3, 3, 3), 
												playerData.RootPart.CFrame * CF(MRANDOM(-3, 3), MRANDOM(-3, 4), MRANDOM(-3, 3)), 
												Color3.new(1, MRANDOM(3, 7)/10, 0), Enum.Material.Neon, 0.2, true)
											firePart.Shape = Enum.PartType.Ball
											TweenService:Create(firePart, TweenInfo.new(0.8), {
												CFrame = firePart.CFrame + VT(0, 6, 0),
												Transparency = 1
											}):Play()
											Debris:AddItem(firePart, 0.8)

											humanoid:TakeDamage(12)
											task.wait(0.25)
										end
									end)()

									CreateEffect("Sphere", CF(sphere.Position), VT(10, 10, 10), VT(30, 30, 30), 
										Color3.new(1, 0.4, 0), 0.5, nil, 2)
								end
							end
						end

						-- Constant area damage (less frequent for performance)
						if math.random() < 0.1 then
							ApplyAoE(sphere.Position, 15, 50, 25)
						end
					end
				end

				-- Periodic fire sounds
				if math.random() < 0.04 then
					CreatePositionalSound("fire_whoosh", ROOTPART.Position, 2, MRANDOM(6, 10)/10, false, "Tornado roar")
				end
			end)

			-- Cleanup connection after duration
			task.wait(duration / 60)
			if connection then
				connection:Disconnect()
			end

			-- PHASE 3: INFERNO DETONATION
			CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.3, false, "Massive explosion")

			-- All fire spheres explode
			for _, data in ipairs(fireSpheres) do
				if data.Sphere.Parent then
					CreateEffect("Sphere", data.Sphere.CFrame, VT(10, 10, 10), VT(50, 50, 50), 
						Color3.new(1, 0.3, 0), 0.7, nil, 3)
					ApplyAoE(data.Sphere.Position, 30, 180, 80)
					data.Sphere:Destroy()
					if data.Core.Parent then
						data.Core:Destroy()
					end
				end
			end

			-- Ring of fire explosions
			for ring = 1, 16 do
				local angle = ring * 22.5
				local distance = 50
				local expPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * distance, 0, math.sin(RAD(angle)) * distance)
				CreateEffect("Sphere", CF(expPos), VT(20, 20, 20), VT(60, 60, 60), 
					Color3.new(1, MRANDOM(2, 5)/10, 0), 0.8, nil, 3)
				ApplyAoE(expPos, 40, 240, 100)
			end

			-- Central massive explosion
			task.wait(0.5)
			CreateEffect("Sphere", ROOTPART.CFrame, VT(50, 50, 50), VT(180, 180, 180), 
				Color3.new(1, 0.5, 0), 2, nil, 6)
			ApplyAoE(ROOTPART.Position, 100, 350, 150)
		end)()

		task.wait(duration / 60 + 2.5)

		-- Cleanup and restore
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogColor = originalFogColor,
			FogEnd = originalFogEnd
		}):Play()

		task.wait(0.5)
		Attack = false
		AttackCooldowns.InfernoTornado = tick()
	end

	-- Attack 6: COSMIC ANNIHILATION - NEXUS SIGNATURE ATTACK
	local function CosmicAnnihilation()
		if not canUseAttack() then return end
		Attack = true

		-- Display random taunt
		DisplayTaunt(AttackTaunts.Cosmic[MRANDOM(1, #AttackTaunts.Cosmic)], 3, Color3.fromRGB(100, 0, 200))

		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.3, false, "Cosmic/space ambient sound")

		-- Enhanced environment darkening
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top

		TweenService:Create(Lighting, TweenInfo.new(2.5), {
			Brightness = 0,
			Ambient = Color3.new(0.02, 0, 0.08),
			ColorShift_Top = Color3.new(0.1, 0, 0.3)
		}):Play()

		task.wait(1)

		-- Create SIGNATURE cosmic sphere WAY ABOVE the boss
		local sphereHeight = 200  -- Very high above
		local spherePos = ROOTPART.Position + VT(0, sphereHeight, 0)

		-- Main cosmic core
		local cosmicCore = CreatePart(VT(30, 30, 30), CF(spherePos), Color3.new(0.15, 0, 0.5), Enum.Material.Neon, 0, true)
		cosmicCore.Shape = Enum.PartType.Ball

		-- Inner white core
		local innerCore = CreatePart(VT(15, 15, 15), cosmicCore.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)
		innerCore.Shape = Enum.PartType.Ball

		-- Ultra-bright light
		local coreLight = Instance.new("PointLight")
		coreLight.Brightness = 50
		coreLight.Color = Color3.new(0.3, 0, 1)
		coreLight.Range = 300
		coreLight.Parent = cosmicCore

		-- Cosmic sound
		CreateSound("energy_beam", cosmicCore, 4, 0.4, false, "Cosmic charging")

		-- Keep inner core centered
		coroutine.wrap(function()
			while cosmicCore.Parent do
				innerCore.CFrame = cosmicCore.CFrame
				task.wait()
			end
		end)()

		-- THREE RAPID RINGS around the sphere (no flickering)
		local rings = {}
		for r = 1, 3 do
			local ringDist = 40 + r*15
			local ring = CreatePart(VT(1, 1, 1), cosmicCore.CFrame, Color3.new(0.2 + r*0.15, 0, 0.6 + r*0.15), Enum.Material.Neon, 0.3, true)

			local ringMesh = Instance.new("SpecialMesh")
			ringMesh.MeshType = Enum.MeshType.FileMesh
			ringMesh.MeshId = "rbxassetid://3270017"
			ringMesh.Scale = VT(ringDist, ringDist, 3)
			ringMesh.Parent = ring

			table.insert(rings, {Part = ring, Mesh = ringMesh, Distance = ringDist, Index = r})

			-- Smooth rotation without flickering
			coroutine.wrap(function()
				local rotation = r * 60
				while cosmicCore.Parent do
					rotation = rotation + (3 + r)
					ring.CFrame = cosmicCore.CFrame * ANGLES(RAD(rotation * 0.5), RAD(rotation), RAD(rotation * 0.7))
					task.wait()
				end
			end)()
		end

		-- Cosmic energy beams connecting to ground
		local beamCount = 12
		for b = 1, beamCount do
			local beamAngle = (b / beamCount) * math.pi * 2
			local beamDist = 60
			local groundPos = ROOTPART.Position + VT(math.cos(beamAngle) * beamDist, 0, math.sin(beamAngle) * beamDist)

			coroutine.wrap(function()
				for pulse = 1, 40 do
					local beam = CreatePart(VT(4, sphereHeight, 4), CF(groundPos + VT(0, sphereHeight/2, 0)), Color3.new(0.2, 0, 0.7), Enum.Material.Neon, 0.5, true)
					TweenService:Create(beam, TweenInfo.new(0.3), {Transparency = 1}):Play()
					Debris:AddItem(beam, 0.3)
					task.wait(0.15)
				end
			end)()
		end

		-- Stellar particles orbiting the cosmic sphere
		local particles = {}
		for p = 1, 100 do
			local particle = CreatePart(VT(3, 3, 3), cosmicCore.CFrame, Color3.new(MRANDOM(5, 10)/10, MRANDOM(3, 8)/10, 1), Enum.Material.Neon, 0.2, true)
			particle.Shape = Enum.PartType.Ball
			table.insert(particles, {Part = particle, Angle = MRANDOM(0, 360), Dist = MRANDOM(35, 80), Speed = MRANDOM(2, 6)})

			coroutine.wrap(function()
				local angle = MRANDOM(0, 360)
				local height = MRANDOM(-40, 40)
				while cosmicCore.Parent and particle.Parent do
					angle = angle + (2 + MRANDOM(1, 3))
					local dist = MRANDOM(40, 90)
					particle.CFrame = cosmicCore.CFrame * CF(math.cos(RAD(angle)) * dist, height, math.sin(RAD(angle)) * dist)
					task.wait()
				end
			end)()
		end

		-- Energy vortex spiraling into the sphere
		coroutine.wrap(function()
			for spiral = 1, 80 do
				for s = 1, 5 do
					local spiralAngle = (spiral * 30 + s * 72) % 360
					local spiralDist = 100 - (spiral * 1.2)
					if spiralDist > 10 then
						local spiralPos = cosmicCore.Position + VT(math.cos(RAD(spiralAngle)) * spiralDist, MRANDOM(-30, 30), math.sin(RAD(spiralAngle)) * spiralDist)
						local spiralPart = CreatePart(VT(5, 5, 5), CF(spiralPos), Color3.new(0.3, 0, 0.8), Enum.Material.Neon, 0.4, true)
						spiralPart.Shape = Enum.PartType.Ball
						TweenService:Create(spiralPart, TweenInfo.new(0.8), {
							CFrame = cosmicCore.CFrame,
							Transparency = 1
						}):Play()
						Debris:AddItem(spiralPart, 0.8)
					end
				end
				task.wait(0.08)
			end
		end)()

		-- Grow the cosmic sphere
		TweenService:Create(cosmicCore, TweenInfo.new(5), {Size = VT(120, 120, 120)}):Play()
		TweenService:Create(innerCore, TweenInfo.new(5), {Size = VT(60, 60, 60)}):Play()

		-- Grow the rings
		for _, ringData in ipairs(rings) do
			local finalScale = ringData.Distance * 2.5
			TweenService:Create(ringData.Mesh, TweenInfo.new(5), {Scale = VT(finalScale, finalScale, 5)}):Play()
		end

		task.wait(5)

		-- MASSIVE COSMIC COLLAPSE
		CreateSound("dimensional_rift", cosmicCore, 5, 0.2, false, "Dimensional rift/portal sound")

		-- Collapse animation
		TweenService:Create(cosmicCore, TweenInfo.new(1.5), {Size = VT(5, 5, 5)}):Play()
		TweenService:Create(innerCore, TweenInfo.new(1.5), {Size = VT(2, 2, 2)}):Play()
		TweenService:Create(coreLight, TweenInfo.new(1.5), {Brightness = 100, Range = 400}):Play()

		for _, ringData in ipairs(rings) do
			TweenService:Create(ringData.Part, TweenInfo.new(1.5), {Transparency = 1}):Play()
		end

		task.wait(1.5)

		-- ULTIMATE COSMIC ANNIHILATION EXPLOSION - Use positional sounds that won't get cut off
		CreatePositionalSound("intro_explosion", cosmicCore.Position, 6, 0.2, false, "Massive explosion sound")
		CreatePositionalSound("massive_explosion", cosmicCore.Position, 6, 0.3, false, "Massive explosion sound")

		-- Central nova explosion
		CreateEffect("Sphere", cosmicCore.CFrame, VT(5, 5, 5), VT(300, 300, 300), Color3.new(1, 1, 1), 2.5, nil, 8)
		CreateEffect("Sphere", cosmicCore.CFrame, VT(10, 10, 10), VT(280, 280, 280), Color3.new(0.3, 0, 1), 2.5, nil, 8)

		-- Massive shockwave rings
		for wave = 1, 8 do
			CreateEffect("Ring", cosmicCore.CFrame * ANGLES(RAD(90), 0, 0), VT(50, 50, 1), VT(400 + wave*50, 400 + wave*50, 1), Color3.new(0.2, 0, 0.8), 2, nil, 6)
			CreateEffect("Ring", cosmicCore.CFrame * ANGLES(0, RAD(90), 0), VT(50, 50, 1), VT(400 + wave*50, 400 + wave*50, 1), Color3.new(0.3, 0, 0.9), 2, nil, 6)
		end

		-- Multiple cascading explosions
		for explosion = 1, 60 do
			local expDist = MRANDOM(10, 150)
			local expAngle = MRANDOM(0, 360)
			local expHeight = MRANDOM(-30, 30)
			local expPos = ROOTPART.Position + VT(math.cos(RAD(expAngle)) * expDist, expHeight, math.sin(RAD(expAngle)) * expDist)

			CreateEffect("Sphere", CF(expPos), VT(15, 15, 15), VT(60, 60, 60), Color3.new(MRANDOM(3, 8)/10, 0, MRANDOM(5, 10)/10), 1.2, nil, 4)
			ApplyAoE(expPos, 45, 200, 80)

			-- Ground impact
			if math.random(1, 3) == 1 then
				CreateEffect("Ring", CF(expPos), VT(20, 1, 20), VT(80, 1, 80), Color3.new(0.3, 0, 1), 1, nil, 3)
			end

			task.wait(0.03)
		end

		-- Cosmic aftermath particles
		for aftermath = 1, 40 do
			local afterPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(-20, 50), MRANDOM(-120, 120))
			local afterPart = CreatePart(VT(6, 6, 6), CF(afterPos), Color3.new(MRANDOM(2, 7)/10, 0, MRANDOM(5, 10)/10), Enum.Material.Neon, 0.3, true)
			afterPart.Shape = Enum.PartType.Ball
			TweenService:Create(afterPart, TweenInfo.new(4), {
				Size = VT(1, 1, 1),
				Transparency = 1
			}):Play()
			Debris:AddItem(afterPart, 4)
		end

		-- Clean up
		cosmicCore:Destroy()
		innerCore:Destroy()
		for _, ringData in ipairs(rings) do
			if ringData.Part.Parent then
				ringData.Part:Destroy()
			end
		end
		for _, particleData in ipairs(particles) do
			if particleData.Part.Parent then
				particleData.Part:Destroy()
			end
		end

		-- Restore lighting
		TweenService:Create(Lighting, TweenInfo.new(6), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift
		}):Play()

		task.wait(3)
		Attack = false
		AttackCooldowns.CosmicAnnihilation = tick()
	end

	-- Attack 7: REALITY-SEVERING QUANTUM SLICE - EPIC ENHANCED
	local function QuantumSlice()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogEnd = Lighting.FogEnd
		local originalGravity = workspace.Gravity

		DisplayTaunt(AttackTaunts.Quantum[MRANDOM(1, #AttackTaunts.Quantum)], 4, Color3.fromRGB(0, 255, 150))
		CreatePositionalSound("time_distortion", ROOTPART.Position, 3, 0.7, false, "Time distortion")

		-- PHASE 1: QUANTUM REALITY - Green distorted environment
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.15,
			Ambient = Color3.new(0, 0.25, 0.15),
			ColorShift_Top = Color3.new(0, 0.7, 0.3),
			FogEnd = 350
		}):Play()

		workspace.Gravity = 120

		-- MASSIVE QUANTUM BLADES
		local blades = {}
		for b = 1, 12 do
			local blade = CreatePart(VT(5, 100, 5), ROOTPART.CFrame * CF(12 * b, 50, 0), 
				Color3.new(0, 1, MRANDOM(2, 5)/10), Enum.Material.Neon, 0, true)

			local bladeGlow = Instance.new("PointLight")
			bladeGlow.Name = "BladeGlow"
			bladeGlow.Brightness = 25
			bladeGlow.Color = Color3.new(0, 1, 0.3)
			bladeGlow.Range = 60
			bladeGlow.Parent = blade

			table.insert(blades, blade)
		end

		task.wait(1)

		-- PHASE 2: OMNIDIRECTIONAL QUANTUM SLICING
		for slice = 1, 40 do
			local slashAngle = RAD(slice * 9)

			for i, blade in ipairs(blades) do
				blade.CFrame = ROOTPART.CFrame * CF(0, 50, 0) * ANGLES(0, slashAngle + RAD(i * 30), RAD(60))

				-- GIANT slash trail
				local trail = CreatePart(VT(8, 100, 180), blade.CFrame * CF(0, 0, -90), 
					Color3.new(0, 1, MRANDOM(2, 5)/10), Enum.Material.Neon, 0.2, true)

				-- Reality tears along the blade path
				for crack = 1, 12 do
					local rift = CreatePart(VT(4, 80, 4), trail.CFrame * CF(MRANDOM(-50, 50), MRANDOM(-30, 30), MRANDOM(-60, 60)), 
						Color3.new(0, 0, 0), Enum.Material.Neon, 0.1, true)
					TweenService:Create(rift, TweenInfo.new(1.5), {
						Size = VT(10, 80, 10),
						Transparency = 1
					}):Play()
					Debris:AddItem(rift, 1.5)
				end

				TweenService:Create(trail, TweenInfo.new(0.8), {
					Transparency = 1
				}):Play()

				ApplyAoE(ROOTPART.Position + blade.CFrame.LookVector * 90, 70, 180, 70)
				Debris:AddItem(trail, 0.8)
			end

			CreatePositionalSound("energy_beam", ROOTPART.Position, 2, MRANDOM(7, 13)/10, false, "Slash sound")
			task.wait(0.1)
		end

		-- PHASE 3: REALITY FRACTURE RINGS
		for ring = 1, 20 do
			local ringAngle = ring * 18
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(90), 0, RAD(ringAngle)), 
				VT(30, 30, 5), VT(250 + ring*10, 250 + ring*10, 5), Color3.new(0, 1, 0.3), 1.5, nil, 4)
		end
		ApplyAoE(ROOTPART.Position, 130, 300, 120)

		-- Blades converge
		CreatePositionalSound("reality_tear", ROOTPART.Position, 4, 0.8, false, "Reality tear")

		for i, blade in ipairs(blades) do
			if blade.Parent then
				TweenService:Create(blade, TweenInfo.new(1), {
					CFrame = ROOTPART.CFrame * CF(0, 50, 0),
					Size = VT(0, 0, 0),
					Transparency = 1
				}):Play()
			end
		end

		-- PHASE 4: QUANTUM DETONATION
		task.wait(1)
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.4, false, "Massive explosion")

		-- Reality shatter explosion
		for explosion = 1, 30 do
			local expAngle = explosion * 12
			local distance = MRANDOM(20, 100)
			local expPos = ROOTPART.Position + VT(
				math.cos(RAD(expAngle)) * distance, 
				MRANDOM(-20, 40), 
				math.sin(RAD(expAngle)) * distance
			)
			CreateEffect("Sphere", CF(expPos), VT(15, 15, 15), VT(60, 60, 60), 
				Color3.new(0, 1, MRANDOM(3, 7)/10), 0.8, nil, 3)
			CreateEffect("Ring", CF(expPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(20, 20, 5), VT(70, 70, 5), Color3.new(0, 1, 0.4), 0.6, nil, 2)
			ApplyAoE(expPos, 40, 240, 100)
		end

		-- Central massive explosion
		CreateEffect("Sphere", ROOTPART.CFrame * CF(0, 50, 0), VT(50, 50, 50), VT(200, 200, 200), 
			Color3.new(0, 1, 0.5), 2.5, nil, 6)
		ApplyAoE(ROOTPART.Position, 110, 350, 140)

		-- Cleanup - Ensure all blades and lights are destroyed
		task.wait(1)
		for i, blade in ipairs(blades) do
			if blade.Parent then
				-- Destroy any lights attached
				local light = blade:FindFirstChild("PointLight")
				if light then
					light:Destroy()
				end
				blade:Destroy()
			end
		end

		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			FogEnd = originalFogEnd
		}):Play()
		workspace.Gravity = originalGravity

		task.wait(0.5)
		Attack = false
		AttackCooldowns.QuantumSlice = tick()
	end

	-- Attack 8: APOCALYPTIC STELLAR CONVERGENCE
	local function StellarConvergence()
		if not canUseAttack() then return end
		Attack = true

		-- Display random taunt
		DisplayTaunt(AttackTaunts.Stellar[MRANDOM(1, #AttackTaunts.Stellar)], 3, Color3.fromRGB(255, 200, 0))

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor

		-- PHASE 1: STELLAR AWAKENING - Environment turns golden/orange like a sun
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 2.5, 0.4, false, "Cosmic/space ambient sound")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 4,
			Ambient = Color3.fromRGB(255, 180, 50),
			ColorShift_Top = Color3.fromRGB(255, 220, 100),
			FogEnd = 300,
			FogColor = Color3.fromRGB(255, 200, 100)
		}):Play()

		-- Giant solar disc appears in sky
		local solarDisc = CreatePart(VT(200, 10, 200), ROOTPART.CFrame * CF(0, 150, 0), Color3.new(1, 0.8, 0.2), Enum.Material.Neon, 0, true)
		local discMesh = Instance.new("SpecialMesh")
		discMesh.MeshType = Enum.MeshType.Cylinder
		discMesh.Scale = VT(0.05, 1, 1)
		discMesh.Parent = solarDisc
		solarDisc.CFrame = solarDisc.CFrame * ANGLES(0, 0, RAD(90))

		-- Ultra-bright sun light
		local sunLight = Instance.new("PointLight")
		sunLight.Brightness = 100
		sunLight.Color = Color3.new(1, 0.8, 0.2)
		sunLight.Range = 500
		sunLight.Parent = solarDisc

		-- Pulsing sun effect
		coroutine.wrap(function()
			for i = 1, 100 do
				if solarDisc.Parent then
					sunLight.Brightness = 100 + math.sin(i * 0.3) * 30
					task.wait()
				end
			end
		end)()

		-- Solar flare pillars from sky
		for flare = 1, 8 do
			local angle = (flare / 8) * math.pi * 2
			local flarePos = ROOTPART.Position + VT(math.cos(angle) * 60, 0, math.sin(angle) * 60)
			local flarePillar = CreatePart(VT(15, 200, 15), CF(flarePos) * CF(0, 100, 0), Color3.new(1, 0.7, 0), Enum.Material.Neon, 0.3, true)

			TweenService:Create(flarePillar, TweenInfo.new(2), {
				Size = VT(25, 200, 25),
				Transparency = 0.6
			}):Play()

			Debris:AddItem(flarePillar, 10)
		end

		task.wait(2)

		-- PHASE 2: STELLAR CORE FORMATION - Create massive stellar cores
		CreatePositionalSound("energy_beam", ROOTPART.Position, 3, 0.5, false, "Energy beam/laser charging sound")

		local cores = {}
		for c = 1, 6 do -- Reduced for optimization
			local angle = (c / 12) * math.pi * 2
			local corePos = ROOTPART.Position + VT(math.cos(angle) * 70, 40, math.sin(angle) * 70)

			-- Massive stellar core with multiple layers
			local core = CreatePart(VT(25, 25, 25), CF(corePos), Color3.new(1, 0.7, 0), Enum.Material.Neon, 0, true)
			core.Shape = Enum.PartType.Ball

			-- Inner white-hot core
			local innerCore = CreatePart(VT(15, 15, 15), core.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)
			innerCore.Shape = Enum.PartType.Ball

			-- Core light
			local light = Instance.new("PointLight")
			light.Brightness = 50
			light.Color = Color3.new(1, 0.7, 0)
			light.Range = 120
			light.Parent = core

			table.insert(cores, core)

			-- Orbiting plasma rings around each core
			for ring = 1, 2 do -- Reduced rings for optimization
				local plasmaRing = CreatePart(VT(40 + ring*10, 3, 40 + ring*10), core.CFrame, Color3.new(1, 0.6, 0.1), Enum.Material.Neon, 0.5, true)
				local ringMesh = Instance.new("SpecialMesh")
				ringMesh.MeshType = Enum.MeshType.FileMesh
				ringMesh.MeshId = "rbxassetid://3270017"
				ringMesh.Scale = VT(40 + ring*10, 40 + ring*10, 3)
				ringMesh.Parent = plasmaRing

				coroutine.wrap(function()
					local rotation = 0
					while core.Parent do
						rotation = rotation + ring * 3
						plasmaRing.CFrame = core.CFrame * ANGLES(RAD(rotation), RAD(rotation * 0.8), 0)
						task.wait()
					end
				end)()

				Debris:AddItem(plasmaRing, 12)
			end

			-- Core pulsing and particle emission
			coroutine.wrap(function()
				for i = 1, 300 do
					if core.Parent and innerCore.Parent then
						local pulse = math.sin(i * 0.15)
						core.Size = VT(25, 25, 25) + VT(pulse, pulse, pulse) * 8
						innerCore.Size = VT(15, 15, 15) + VT(pulse, pulse, pulse) * 5
						innerCore.CFrame = core.CFrame

						-- Emit solar particles
						if i % 8 == 0 then
							local particle = CreatePart(VT(3, 3, 3), core.CFrame * CF(MRANDOM(-15, 15), MRANDOM(-15, 15), MRANDOM(-15, 15)), Color3.new(1, 0.8, 0.3), Enum.Material.Neon, 0, true)
							particle.Shape = Enum.PartType.Ball
							TweenService:Create(particle, TweenInfo.new(1.5), {
								Size = VT(0.5, 0.5, 0.5),
								Transparency = 1
							}):Play()
							Debris:AddItem(particle, 1.5)
						end

						task.wait()
					end
				end
			end)()

			Debris:AddItem(innerCore, 12)
		end

		task.wait(2)

		-- PHASE 3: STELLAR NETWORK - Connect all cores with massive energy beams
		DisplayTaunt("WITNESS THE POWER OF THE COSMOS!", 2, Color3.fromRGB(255, 200, 0))

		for i = 1, #cores do
			for j = i + 1, #cores do
				if cores[i].Parent and cores[j].Parent then
					local distance = (cores[i].Position - cores[j].Position).Magnitude
					local beam = CreatePart(VT(10, 10, distance), CF(cores[i].Position, cores[j].Position) * CF(0, 0, -distance/2), Color3.new(1, 0.7, 0), Enum.Material.Neon, 0.2, true)

					-- Beam core
					local beamCore = CreatePart(VT(5, 5, distance), beam.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)

					-- Pulsing beam effect (optimized - less frequent updates)
					coroutine.wrap(function()
						for pulse = 1, 25 do -- Reduced pulses
							if beam.Parent then
								beam.Transparency = 0.2 + math.sin(pulse * 0.6) * 0.15
								task.wait(0.1) -- Less frequent updates
							end
						end
					end)()

					TweenService:Create(beam, TweenInfo.new(5), {Transparency = 1}):Play()
					TweenService:Create(beamCore, TweenInfo.new(5), {Transparency = 1}):Play()
					Debris:AddItem(beam, 5)
					Debris:AddItem(beamCore, 5)
				end
			end
		end

		task.wait(1)

		-- PHASE 4: STELLAR BOMBARDMENT - Massive energy bolt chaos
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 4, 0.3, false, "Massive explosion sound")

		for wave = 1, 30 do -- Reduced waves for optimization
			for _, core in ipairs(cores) do
				if core.Parent then
					for bolt = 1, 1 do -- Reduced bolts per core
						-- Giant stellar bolt
						local stellarBolt = CreatePart(VT(8, 8, 8), core.CFrame, Color3.new(1, 0.8, 0.2), Enum.Material.Neon, 0, false)
						stellarBolt.Shape = Enum.PartType.Ball

						-- Bolt trail
						coroutine.wrap(function()
							while stellarBolt.Parent do
								local trail = CreatePart(VT(6, 6, 6), stellarBolt.CFrame, Color3.new(1, 0.7, 0), Enum.Material.Neon, 0.5, true)
								trail.Shape = Enum.PartType.Ball
								TweenService:Create(trail, TweenInfo.new(0.8), {
									Size = VT(2, 2, 2),
									Transparency = 1
								}):Play()
								Debris:AddItem(trail, 0.8)
								task.wait(0.08)
							end
						end)()

						local targetPos = ROOTPART.Position + VT(MRANDOM(-50, 50), MRANDOM(-10, 30), MRANDOM(-50, 50))
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = (targetPos - core.Position).Unit * 120
						bv.Parent = stellarBolt

						stellarBolt.Touched:Connect(function(hit)
							if hit.Parent ~= CHARACTER and hit.Parent ~= Effects then
								-- Massive stellar explosion
								CreateEffect("Sphere", CF(stellarBolt.Position), VT(8, 8, 8), VT(40, 40, 40), Color3.new(1, 0.7, 0), 0.3, 610359590, 2)

								-- Solar flare burst
								for flare = 1, 8 do
									local flareAngle = (flare / 8) * math.pi * 2
									local flarePos = stellarBolt.Position + VT(math.cos(flareAngle) * 15, 0, math.sin(flareAngle) * 15)
									CreateEffect("Sphere", CF(flarePos), VT(4, 4, 4), VT(12, 12, 12), Color3.new(1, 0.8, 0.3), 0.5, nil, 1.5)
								end

								-- Ground impact ring
								CreateEffect("Ring", CF(stellarBolt.Position), VT(10, 1, 10), VT(50, 1, 50), Color3.new(1, 0.8, 0.2), 0.4, nil, 2)

								ApplyAoE(stellarBolt.Position, 25, 85, 40)
								stellarBolt:Destroy()
							end
						end)

						Debris:AddItem(stellarBolt, 5)
					end
				end
			end
			task.wait(0.08)
		end

		task.wait(1)

		-- PHASE 5: SUPERNOVA DETONATION - All cores explode simultaneously
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.3, false, "Intro explosion sound")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 5, 0.5, false, "Plasma charge sound")

		DisplayTaunt("SUPERNOVA!!!", 3, Color3.fromRGB(255, 255, 255))

		-- Ultra-bright flash
		TweenService:Create(Lighting, TweenInfo.new(0.3), {
			Brightness = 10,
			Ambient = Color3.fromRGB(255, 255, 200)
		}):Play()

		for _, core in ipairs(cores) do
			if core.Parent then
				-- Pre-explosion charge up
				local chargeUp = CreatePart(VT(30, 30, 30), core.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)
				chargeUp.Shape = Enum.PartType.Ball
				TweenService:Create(chargeUp, TweenInfo.new(0.5), {Size = VT(5, 5, 5)}):Play()
				Debris:AddItem(chargeUp, 0.5)

				task.wait(0.1)

				-- Massive supernova explosion waves
				for burst = 1, 8 do
					CreateEffect("Sphere", core.CFrame, VT(20, 20, 20), VT(120 + burst*30, 120 + burst*30, 120 + burst*30), Color3.new(1, 0.7 - burst*0.05, 0), 0.8, nil, 4)
					task.wait(0.05)
				end

				-- Stellar shockwave ring
				for ring = 1, 5 do
					CreateEffect("Ring", core.CFrame, VT(30, 1, 30), VT(150 + ring*30, 1, 150 + ring*30), Color3.new(1, 0.8, 0.3), 0.5, nil, 3)
					task.wait(0.05)
				end

				-- Solar eruption pillars
				for pillar = 1, 12 do
					local pillarAngle = (pillar / 12) * math.pi * 2
					local pillarPos = core.Position + VT(math.cos(pillarAngle) * 30, 0, math.sin(pillarAngle) * 30)
					local solarPillar = CreatePart(VT(12, 100, 12), CF(pillarPos) * CF(0, 50, 0), Color3.new(1, 0.7, 0), Enum.Material.Neon, 0.3, true)
					TweenService:Create(solarPillar, TweenInfo.new(2), {
						Size = VT(20, 150, 20),
						Transparency = 1
					}):Play()
					Debris:AddItem(solarPillar, 2)
				end

				-- Massive damage
				ApplyAoE(core.Position, 60, 200, 100)
				core:Destroy()
			end
		end

		-- Destroy solar disc with final flash
		TweenService:Create(solarDisc, TweenInfo.new(2), {
			Size = VT(300, 10, 300),
			Transparency = 1
		}):Play()
		Debris:AddItem(solarDisc, 2)

		task.wait(2)

		-- Restore lighting gradually
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()

		task.wait(1)
		Attack = false
		AttackCooldowns.StellarConvergence = tick()
	end

	-- Attack 9: APOCALYPTIC VOID STORM
	local function VoidStorm()
		if not canUseAttack() then return end
		Attack = true

		-- Display random taunt
		DisplayTaunt(AttackTaunts.Void[MRANDOM(1, #AttackTaunts.Void)], 3, Color3.fromRGB(100, 0, 150))

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor
		local origGravity = workspace.Gravity

		-- PHASE 1: VOID REALM DESCENT - Environment turns dark purple/black
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 2.5, 0.3, false, "Dimensional rift/portal sound")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.1,
			Ambient = Color3.fromRGB(20, 0, 40),
			ColorShift_Top = Color3.fromRGB(80, 0, 120),
			FogEnd = 200,
			FogColor = Color3.fromRGB(10, 0, 30)
		}):Play()

		-- Gravity fluctuation
		TweenService:Create(workspace, TweenInfo.new(2), {Gravity = 150}):Play()

		-- Giant void portal opens in the sky
		local voidPortal = CreatePart(VT(250, 10, 250), ROOTPART.CFrame * CF(0, 180, 0), Color3.new(0.05, 0, 0.2), Enum.Material.ForceField, 0.3, true)
		local portalMesh = Instance.new("SpecialMesh")
		portalMesh.MeshType = Enum.MeshType.Cylinder
		portalMesh.Scale = VT(0.04, 1, 1)
		portalMesh.Parent = voidPortal
		voidPortal.CFrame = voidPortal.CFrame * ANGLES(0, 0, RAD(90))

		-- Portal rotation with eerie glow
		local portalLight = Instance.new("PointLight")
		portalLight.Brightness = 80
		portalLight.Color = Color3.new(0.2, 0, 0.5)
		portalLight.Range = 600
		portalLight.Parent = voidPortal

		coroutine.wrap(function()
			local rotation = 0
			while voidPortal.Parent do
				rotation = rotation + 2
				voidPortal.CFrame = voidPortal.CFrame * ANGLES(0, RAD(2), 0)
				portalLight.Brightness = 80 + math.sin(rotation * 0.1) * 20
				task.wait()
			end
		end)()

		-- Void tendrils reaching down from portal
		for tendril = 1, 12 do
			local tendrilAngle = (tendril / 12) * math.pi * 2
			local tendrilStart = voidPortal.Position + VT(math.cos(tendrilAngle) * 80, 0, math.sin(tendrilAngle) * 80)
			local tendrilPart = CreatePart(VT(15, 150, 15), CF(tendrilStart) * CF(0, -75, 0), Color3.new(0.1, 0, 0.3), Enum.Material.Neon, 0.4, true)

			-- Animate tendril
			coroutine.wrap(function()
				for i = 1, 100 do
					if tendrilPart.Parent then
						tendrilPart.Size = VT(15, 150, 15) + VT(math.sin(i * 0.2), 0, math.sin(i * 0.2)) * 5
						task.wait()
					end
				end
			end)()

			Debris:AddItem(tendrilPart, 12)
		end

		task.wait(2)

		-- PHASE 2: VOID STORM FORMATION - Create massive void storm spheres
		CreatePositionalSound("time_distortion", ROOTPART.Position, 3, 0.4, false, "Time distortion sound")
		DisplayTaunt("THE VOID CONSUMES ALL!", 2, Color3.fromRGB(150, 0, 200))

		local storms = {}
		for s = 1, 5 do -- Reduced storms for optimization
			local stormAngle = (s / 5) * math.pi * 2
			local stormPos = ROOTPART.Position + VT(math.cos(stormAngle) * 65, 100 + s*15, math.sin(stormAngle) * 65)

			-- Giant void storm sphere with multiple layers
			local storm = CreatePart(VT(120, 60, 120), CF(stormPos), Color3.new(0.08, 0, 0.25), Enum.Material.ForceField, 0.4, true)
			storm.Shape = Enum.PartType.Ball
			table.insert(storms, storm)

			-- Inner void core
			local voidCore = CreatePart(VT(70, 35, 70), storm.CFrame, Color3.new(0.15, 0, 0.4), Enum.Material.Neon, 0.2, true)
			voidCore.Shape = Enum.PartType.Ball

			-- Dark singularity at center
			local singularity = CreatePart(VT(30, 15, 30), storm.CFrame, Color3.new(0, 0, 0), Enum.Material.Neon, 0, true)
			singularity.Shape = Enum.PartType.Ball

			-- Storm light
			local stormLight = Instance.new("PointLight")
			stormLight.Brightness = 40
			stormLight.Color = Color3.new(0.15, 0, 0.4)
			stormLight.Range = 150
			stormLight.Parent = storm

			-- Void spiral rings
			for ring = 1, 2 do -- Reduced rings for optimization
				local voidRing = CreatePart(VT(90 + ring*20, 5, 90 + ring*20), storm.CFrame, Color3.new(0.1, 0, 0.3), Enum.Material.Neon, 0.6, true)
				local ringMesh = Instance.new("SpecialMesh")
				ringMesh.MeshType = Enum.MeshType.FileMesh
				ringMesh.MeshId = "rbxassetid://3270017"
				ringMesh.Scale = VT(90 + ring*20, 90 + ring*20, 5)
				ringMesh.Parent = voidRing

				coroutine.wrap(function()
					local rotation = 0
					while storm.Parent do
						rotation = rotation + ring * 2.5
						voidRing.CFrame = storm.CFrame * ANGLES(RAD(rotation), RAD(rotation * 0.7), RAD(rotation * 0.5))
						task.wait()
					end
				end)()

				Debris:AddItem(voidRing, 12)
			end

			-- Storm rotation and pulsing
			coroutine.wrap(function()
				local rotation = 0
				while storm.Parent do
					rotation = rotation + 2
					storm.CFrame = storm.CFrame * ANGLES(RAD(2), RAD(3), RAD(1.5))

					-- Void energy leaking
					if rotation % 12 == 0 then
						local voidLeak = CreatePart(VT(8, 8, 8), storm.CFrame * CF(MRANDOM(-50, 50), MRANDOM(-25, 25), MRANDOM(-50, 50)), Color3.new(0.1, 0, 0.3), Enum.Material.Neon, 0.3, true)
						voidLeak.Shape = Enum.PartType.Ball
						TweenService:Create(voidLeak, TweenInfo.new(2), {
							Size = VT(1, 1, 1),
							Transparency = 1
						}):Play()
						Debris:AddItem(voidLeak, 2)
					end

					-- Update cores
					if voidCore.Parent then
						voidCore.CFrame = storm.CFrame
						voidCore.Size = VT(70, 35, 70) + VT(math.sin(rotation * 0.1), math.sin(rotation * 0.1) * 0.5, math.sin(rotation * 0.1)) * 15
					end
					if singularity.Parent then
						singularity.CFrame = storm.CFrame
						singularity.Size = VT(30, 15, 30) + VT(math.sin(rotation * 0.15), math.sin(rotation * 0.15) * 0.5, math.sin(rotation * 0.15)) * 8
					end

					task.wait()
				end
			end)()

			Debris:AddItem(voidCore, 12)
			Debris:AddItem(singularity, 12)
		end

		task.wait(2)

		-- PHASE 3: VOID PROJECTILE APOCALYPSE - Massive void bombardment
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 4, 0.3, false, "Cosmic ambient sound")

		for wave = 1, 40 do -- Reduced waves for optimization
			for _, storm in ipairs(storms) do
				if storm.Parent then
					for proj = 1, 1 do -- Reduced projectiles per storm
						-- Giant void projectile
						local voidBall = CreatePart(VT(10, 10, 10), storm.CFrame * CF(MRANDOM(-55, 55), MRANDOM(-25, 25), MRANDOM(-55, 55)), Color3.new(0.15, 0, 0.4), Enum.Material.Neon, 0, false)
						voidBall.Shape = Enum.PartType.Ball

						-- Void energy core
						local ballCore = CreatePart(VT(6, 6, 6), voidBall.CFrame, Color3.new(0.3, 0, 0.6), Enum.Material.Neon, 0, true)
						ballCore.Shape = Enum.PartType.Ball

						local light = Instance.new("PointLight")
						light.Brightness = 25
						light.Color = Color3.new(0.15, 0, 0.4)
						light.Range = 50
						light.Parent = voidBall

						-- Attach core to ball
						coroutine.wrap(function()
							while voidBall.Parent and ballCore.Parent do
								ballCore.CFrame = voidBall.CFrame
								task.wait()
							end
						end)()

						-- Epic void trail (optimized - less frequent)
						coroutine.wrap(function()
							while voidBall.Parent do
								local trail = CreatePart(VT(8, 8, 8), voidBall.CFrame, Color3.new(0.1, 0, 0.3), Enum.Material.Neon, 0.5, true)
								trail.Shape = Enum.PartType.Ball
								TweenService:Create(trail, TweenInfo.new(1.2), {
									Size = VT(2, 2, 2),
									Transparency = 1
								}):Play()
								Debris:AddItem(trail, 1.2)

								task.wait(0.2) -- Less frequent trail updates
							end
						end)()

						-- Chaotic void trajectory
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = VT(MRANDOM(-100, 100), MRANDOM(-60, -20), MRANDOM(-100, 100))
						bv.Parent = voidBall

						local hitDebounce = false
						local lastY = voidBall.Position.Y

						-- Ground detection to prevent midair explosions
						coroutine.wrap(function()
							while voidBall.Parent do
								local currentY = voidBall.Position.Y
								-- Raycast to detect ground
								local groundRay = workspace:Raycast(voidBall.Position, VT(0, -voidBall.Size.Y, 0))
								if groundRay or (lastY - currentY < 0.1 and currentY < ROOTPART.Position.Y + 10) then
									if not hitDebounce and groundRay and isValidMeteorCollision(groundRay.Instance) then
										hitDebounce = true
										local impactPos = groundRay and groundRay.Position or voidBall.Position

										-- Void explosion
										CreatePositionalSound("explosion_impact", impactPos, 2, MRANDOM(7, 12)/10, false, "Void explosion")
										CreateEffect("Sphere", CF(impactPos), VT(10, 10, 10), VT(50, 50, 50), Color3.new(0.15, 0, 0.4), 0.4, nil, 2)

										-- Void implosion ring
										CreateEffect("Ring", CF(impactPos), VT(15, 1, 15), VT(60, 1, 60), Color3.new(0.2, 0, 0.5), 0.5, nil, 2)

										-- Void tendrils burst
										for tentacle = 1, 6 do
											local tentacleAngle = (tentacle / 6) * math.pi * 2
											local tentaclePos = impactPos + VT(math.cos(tentacleAngle) * 20, 0, math.sin(tentacleAngle) * 20)
											CreateEffect("Sphere", CF(tentaclePos), VT(5, 5, 5), VT(15, 15, 15), Color3.new(0.1, 0, 0.3), 0.6, nil, 1.5)
										end

										ApplyAoE(impactPos, 30, 90, 50)
										voidBall:Destroy()
										if ballCore.Parent then ballCore:Destroy() end
									end
								end
								lastY = currentY
								task.wait(0.05)
							end
						end)()

						voidBall.Touched:Connect(function(hit)
							if not hitDebounce and hit.Parent ~= CHARACTER and hit.Parent ~= Effects and hit.Name ~= "Base" then
								hitDebounce = true
								local impactPos = voidBall.Position
								local groundRay = workspace:Raycast(impactPos, VT(0, -50, 0))
								if groundRay then
									impactPos = groundRay.Position
								end

								-- Void explosion
								CreatePositionalSound("explosion_impact", impactPos, 2, MRANDOM(7, 12)/10, false, "Void explosion")
								CreateEffect("Sphere", CF(impactPos), VT(10, 10, 10), VT(50, 50, 50), Color3.new(0.15, 0, 0.4), 0.4, nil, 2)

								-- Void implosion ring
								CreateEffect("Ring", CF(impactPos), VT(15, 1, 15), VT(60, 1, 60), Color3.new(0.2, 0, 0.5), 0.5, nil, 2)

								-- Void tendrils burst
								for tentacle = 1, 6 do
									local tentacleAngle = (tentacle / 6) * math.pi * 2
									local tentaclePos = impactPos + VT(math.cos(tentacleAngle) * 20, 0, math.sin(tentacleAngle) * 20)
									CreateEffect("Sphere", CF(tentaclePos), VT(5, 5, 5), VT(15, 15, 15), Color3.new(0.1, 0, 0.3), 0.6, nil, 1.5)
								end

								ApplyAoE(impactPos, 30, 90, 50)
								voidBall:Destroy()
								if ballCore.Parent then ballCore:Destroy() end
							end
						end)

						Debris:AddItem(voidBall, 8)
						Debris:AddItem(ballCore, 8)
					end
				end
			end
			task.wait(0.1) -- Less frequent waves for optimization
		end

		task.wait(1)

		-- PHASE 4: VOID COLLAPSE - All storms implode catastrophically
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.3, false, "Massive explosion sound")
		DisplayTaunt("OBLIVION BECKONS!", 2, Color3.fromRGB(200, 0, 255))

		-- Gravity spike
		TweenService:Create(workspace, TweenInfo.new(1), {Gravity = 50}):Play()

		for _, storm in ipairs(storms) do
			if storm.Parent then
				-- Pre-implosion swell
				local swellEffect = CreatePart(storm.Size, storm.CFrame, Color3.new(0.2, 0, 0.5), Enum.Material.Neon, 0.3, true)
				swellEffect.Shape = Enum.PartType.Ball
				TweenService:Create(swellEffect, TweenInfo.new(0.8), {
					Size = storm.Size * 1.5,
					Transparency = 1
				}):Play()
				Debris:AddItem(swellEffect, 0.8)

				task.wait(0.15)

				-- Massive implosion
				for implosion = 1, 6 do
					CreateEffect("Sphere", storm.CFrame, storm.Size * (1 - implosion*0.15), VT(0, 0, 0), Color3.new(0.1, 0, 0.3), 1, nil, 2)
					task.wait(0.08)
				end

				-- Final void burst
				CreateEffect("Sphere", storm.CFrame, VT(20, 20, 20), VT(150, 150, 150), Color3.new(0.15, 0, 0.4), 0.5, nil, 3)

				-- Void shockwave rings
				for ring = 1, 4 do
					CreateEffect("Ring", storm.CFrame, VT(40, 1, 40), VT(180 + ring*40, 1, 180 + ring*40), Color3.new(0.2, 0, 0.5), 0.6, nil, 2.5)
					task.wait(0.08)
				end

				ApplyAoE(storm.Position, 70, 180, 90)
				storm:Destroy()
			end
		end

		-- Close void portal
		TweenService:Create(voidPortal, TweenInfo.new(3), {
			Size = VT(0, 10, 0),
			Transparency = 1
		}):Play()
		Debris:AddItem(voidPortal, 3)

		task.wait(2)

		-- Restore environment gradually
		TweenService:Create(Lighting, TweenInfo.new(4), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(4), {Gravity = origGravity}):Play()

		task.wait(2)
		Attack = false
		AttackCooldowns.VoidStorm = tick()
	end

	-- Attack 10: PLASMA TORNADO VORTEX - Completely redesigned unique attack
	local function PlasmaNova()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor

		-- PHASE 1: PLASMA VORTEX FORMATION - Electric blue/cyan environment
		CreatePositionalSound("energy_beam", ROOTPART.Position, 3, 0.6, false, "Plasma energy charging")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 2,
			Ambient = Color3.fromRGB(50, 150, 255),
			ColorShift_Top = Color3.fromRGB(100, 200, 255),
			FogEnd = 350,
			FogColor = Color3.fromRGB(80, 180, 255)
		}):Play()

		-- Create massive spinning plasma vortex
		local vortexCore = CreatePart(VT(40, 40, 40), ROOTPART.CFrame * CF(0, 30, 0), Color3.new(0, 0.5, 1), Enum.Material.Neon, 0, true)
		vortexCore.Shape = Enum.PartType.Ball

		local coreLight = Instance.new("PointLight")
		coreLight.Brightness = 80
		coreLight.Color = Color3.new(0.3, 0.7, 1)
		coreLight.Range = 200
		coreLight.Parent = vortexCore

		-- Spinning plasma rings around vortex
		local vortexRings = {}
		for r = 1, 8 do
			local ring = CreatePart(VT(60 + r*15, 3, 60 + r*15), vortexCore.CFrame, Color3.new(0.2, 0.6, 1), Enum.Material.Neon, 0.4, true)
			local ringMesh = Instance.new("SpecialMesh")
			ringMesh.MeshType = Enum.MeshType.FileMesh
			ringMesh.MeshId = "rbxassetid://3270017"
			ringMesh.Scale = VT(60 + r*15, 60 + r*15, 3)
			ringMesh.Parent = ring
			table.insert(vortexRings, {Part = ring, Mesh = ringMesh, Index = r})
		end

		task.wait(2)

		-- PHASE 2: PLASMA VORTEX EXPANSION - Vortex grows and pulls in players
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Plasma vortex expansion")

		-- Grow vortex
		TweenService:Create(vortexCore, TweenInfo.new(3), {Size = VT(100, 100, 100)}):Play()

		-- Spin and pull effect
		coroutine.wrap(function()
			local rotation = 0
			for i = 1, 200 do
				if vortexCore.Parent then
					rotation = rotation + 3
					vortexCore.CFrame = ROOTPART.CFrame * CF(0, 30, 0) * ANGLES(0, RAD(rotation), 0)

					-- Rotate rings
					for _, ringData in ipairs(vortexRings) do
						if ringData.Part.Parent then
							local ringRotation = rotation * (0.5 + ringData.Index * 0.2)
							ringData.Part.CFrame = vortexCore.CFrame * ANGLES(RAD(ringRotation), RAD(ringRotation * 0.7), RAD(ringRotation * 0.5))
						end
					end

					-- Pull players toward vortex
					if i % 3 == 0 then
						for _, playerData in pairs(cachedPlayers) do
							if playerData.RootPart and playerData.Model then
								local dist = (playerData.RootPart.Position - vortexCore.Position).Magnitude
								if dist <= 80 then
									local pullForce = Instance.new("BodyVelocity")
									pullForce.MaxForce = VT(1e9, 1e9, 1e9)
									pullForce.Velocity = (vortexCore.Position - playerData.RootPart.Position).Unit * 40
									pullForce.Parent = playerData.RootPart
									Debris:AddItem(pullForce, 0.2)
									ApplyDamage(playerData.Humanoid, 30, targetPlayer)
								end
							end
						end
					end

					-- Plasma particles spiraling
					if i % 4 == 0 then
						local particleAngle = (i / 200) * math.pi * 2
						local particleDist = 40 + math.sin(i * 0.1) * 20
						local particlePos = vortexCore.Position + VT(math.cos(particleAngle) * particleDist, math.sin(i * 0.2) * 10, math.sin(particleAngle) * particleDist)
						local particle = CreatePart(VT(4, 4, 4), CF(particlePos), Color3.new(0.5, 0.9, 1), Enum.Material.Neon, 0.3, true)
						particle.Shape = Enum.PartType.Ball
						TweenService:Create(particle, TweenInfo.new(1.5), {
							CFrame = vortexCore.CFrame,
							Size = VT(1, 1, 1),
							Transparency = 1
						}):Play()
						Debris:AddItem(particle, 1.5)
					end

					task.wait()
				end
			end
		end)()

		task.wait(3)

		-- PHASE 3: PLASMA BURST - Vortex releases massive energy waves
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 4, 0.4, false, "Plasma burst")

		-- Expanding energy waves
		for wave = 1, 12 do
			local waveRing = CreatePart(VT(1, 1, 1), vortexCore.CFrame, Color3.new(0.3, 0.8, 1), Enum.Material.Neon, 0.2, true)
			local waveMesh = Instance.new("SpecialMesh")
			waveMesh.MeshType = Enum.MeshType.FileMesh
			waveMesh.MeshId = "rbxassetid://3270017"
			waveMesh.Scale = VT(100, 100, 5)
			waveMesh.Parent = waveRing

			TweenService:Create(waveMesh, TweenInfo.new(2), {
				Scale = VT(300 + wave*30, 300 + wave*30, 5)
			}):Play()
			TweenService:Create(waveRing, TweenInfo.new(2), {
				Transparency = 1
			}):Play()

			-- Damage wave
			coroutine.wrap(function()
				task.wait(0.5)
				ApplyAoE(vortexCore.Position, 100 + wave*15, 180, 80)
			end)()

			Debris:AddItem(waveRing, 2)
			task.wait(0.15)
		end

		-- PHASE 4: VORTEX DISCHARGE - Plasma bolts shoot in all directions
		for bolt = 1, 40 do
			local boltAngle = (bolt / 40) * math.pi * 2
			local boltHeight = MRANDOM(-20, 40)
			local boltEnd = vortexCore.Position + VT(math.cos(boltAngle) * 120, boltHeight, math.sin(boltAngle) * 120)

			-- Realistic lightning bolt from vortex
			CreateLightningBolt(vortexCore.Position, boltEnd, 12, Color3.new(0.3, 0.8, 1), MRANDOM(2, 4), 0.5)

			-- Impact explosion
			coroutine.wrap(function()
				task.wait(0.3)
				CreatePositionalSound("explosion_impact", boltEnd, 2, MRANDOM(7, 12)/10, false, "Plasma bolt impact")
				CreateEffect("Sphere", CF(boltEnd), VT(15, 15, 15), VT(60, 60, 60), Color3.new(0.3, 0.8, 1), 0.6, nil, 3)
				ApplyAoE(boltEnd, 35, 200, 90)
			end)()

			task.wait(0.1)
		end

		-- Final vortex collapse
		task.wait(1)
		CreatePositionalSound("intro_explosion", vortexCore.Position, 5, 0.3, false, "Vortex collapse")

		-- Massive explosion
		CreateEffect("Sphere", vortexCore.CFrame, VT(50, 50, 50), VT(250, 250, 250), Color3.new(0.3, 0.8, 1), 2, nil, 6)
		for ring = 1, 8 do
			CreateEffect("Ring", vortexCore.CFrame * ANGLES(RAD(90), 0, 0), VT(80, 80, 5), VT(300 + ring*40, 300 + ring*40, 5), Color3.new(0.4, 0.9, 1), 1.5, nil, 4)
		end

		ApplyAoE(vortexCore.Position, 120, 300, 130)

		-- Cleanup
		for _, ringData in ipairs(vortexRings) do
			if ringData.Part.Parent then
				ringData.Part:Destroy()
			end
		end
		vortexCore:Destroy()

		task.wait(2)

		-- Restore lighting
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()

		task.wait(1.5)
		Attack = false
		AttackCooldowns.PlasmaNova = tick()
	end

	-- Attack 11: APOCALYPTIC CRYO BLAST
	local function CryoBlast()
		if not canUseAttack() then return end
		Attack = true

		-- Display random taunt
		DisplayTaunt(AttackTaunts.Cryo[MRANDOM(1, #AttackTaunts.Cryo)], 3, Color3.fromRGB(100, 200, 255))

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor

		-- PHASE 1: ETERNAL WINTER - Environment turns frozen blue/white
		CreatePositionalSound("ice_beam", ROOTPART.Position, 2.5, 0.7, false, "Ice beam/freeze ray sound")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 2,
			Ambient = Color3.fromRGB(150, 200, 255),
			ColorShift_Top = Color3.fromRGB(200, 230, 255),
			FogEnd = 250,
			FogColor = Color3.fromRGB(180, 220, 255)
		}):Play()

		-- Giant frozen crystal in sky
		local frozenCrystal = CreatePart(VT(100, 200, 100), ROOTPART.CFrame * CF(0, 160, 0), Color3.new(0.7, 0.9, 1), Enum.Material.Ice, 0.3, true)
		local crystalMesh = Instance.new("SpecialMesh")
		crystalMesh.MeshType = Enum.MeshType.FileMesh
		crystalMesh.MeshId = "rbxassetid://1033714"
		crystalMesh.Scale = VT(50, 100, 50)
		crystalMesh.Parent = frozenCrystal

		-- Crystal light
		local crystalLight = Instance.new("PointLight")
		crystalLight.Brightness = 100
		crystalLight.Color = Color3.new(0.7, 0.9, 1)
		crystalLight.Range = 600
		crystalLight.Parent = frozenCrystal

		-- Rotating crystal
		coroutine.wrap(function()
			for i = 1, 120 do
				if frozenCrystal.Parent then
					frozenCrystal.CFrame = frozenCrystal.CFrame * ANGLES(0, RAD(2), 0)
					crystalLight.Brightness = 100 + math.sin(i * 0.2) * 30
					task.wait()
				end
			end
		end)()

		-- Snowfall effect with ice particles
		for snow = 1, 80 do
			local snowflake = CreatePart(VT(2, 2, 2), ROOTPART.CFrame * CF(MRANDOM(-100, 100), MRANDOM(80, 120), MRANDOM(-100, 100)), Color3.new(1, 1, 1), Enum.Material.Neon, 0.4, true)
			snowflake.Shape = Enum.PartType.Ball

			coroutine.wrap(function()
				for i = 1, 150 do
					if snowflake.Parent then
						snowflake.Position = snowflake.Position + VT(math.sin(i * 0.1) * 0.5, -1, 0)
						task.wait()
					end
				end
			end)()

			Debris:AddItem(snowflake, 12)
		end

		task.wait(2)

		-- PHASE 2: FROZEN WAVE FORMATIONS - Giant ice waves emerge from ground
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Plasma charge sound")
		DisplayTaunt("ABSOLUTE ZERO!", 2, Color3.fromRGB(200, 230, 255))

		for wave = 1, 8 do
			local waveAngle = (wave / 8) * math.pi * 2
			local wavePos = ROOTPART.Position + VT(math.cos(waveAngle) * 45, 0, math.sin(waveAngle) * 45)

			-- Giant ice wave rising from ground
			local iceWave = CreatePart(VT(30, 5, 80), CF(wavePos) * ANGLES(0, waveAngle, RAD(90)), Color3.new(0.7, 0.85, 1), Enum.Material.Ice, 0.3, true)

			-- Ice crystals on wave
			for crystal = 1, 10 do
				local crystalPos = iceWave.Position + iceWave.CFrame.LookVector * MRANDOM(-35, 35) + VT(0, MRANDOM(-2, 15), 0)
				local miniCrystal = CreatePart(VT(5, 12, 5), CF(crystalPos), Color3.new(0.8, 0.9, 1), Enum.Material.Ice, 0.2, true)
				local miniMesh = Instance.new("SpecialMesh")
				miniMesh.MeshType = Enum.MeshType.FileMesh
				miniMesh.MeshId = "rbxassetid://1033714"
				miniMesh.Scale = VT(2.5, 6, 2.5)
				miniMesh.Parent = miniCrystal

				Debris:AddItem(miniCrystal, 8)
			end

			-- Wave grows upward
			TweenService:Create(iceWave, TweenInfo.new(2), {
				Size = VT(30, 50, 80)
			}):Play()

			Debris:AddItem(iceWave, 8)
			task.wait(0.15)
		end

		task.wait(1)

		-- PHASE 3: GLACIAL BEAM DEVASTATION - Massive freezing beams
		CreatePositionalSound("energy_beam", ROOTPART.Position, 4, 0.4, false, "Energy beam sound")

		for beam = 1, 10 do
			local beamAngle = (beam / 10) * math.pi * 2
			local beamDirection = VT(math.cos(beamAngle), 0, math.sin(beamAngle))

			-- Giant ice beam
			local megaBeam = CreatePart(VT(30, 30, 180), ROOTPART.CFrame * CF(beamDirection * 90), Color3.new(0.7, 0.8, 1), Enum.Material.Ice, 0.2, true)

			-- Beam core
			local beamCore = CreatePart(VT(18, 18, 180), megaBeam.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)

			-- Frozen mist layer
			local beamMist = CreatePart(VT(40, 40, 180), megaBeam.CFrame, Color3.new(0.8, 0.9, 1), Enum.Material.Neon, 0.6, true)

			-- Beam light
			local beamLight = Instance.new("PointLight")
			beamLight.Brightness = 40
			beamLight.Color = Color3.new(0.7, 0.9, 1)
			beamLight.Range = 150
			beamLight.Parent = megaBeam

			-- Beam freeze effect and damage
			coroutine.wrap(function()
				for i = 1, 65 do
					local checkPos = ROOTPART.Position + beamDirection * (i * 2.8)
					ApplyAoE(checkPos, 25, 60, 20)

					-- Massive ice spikes erupting
					if i % 3 == 0 then
						for spike = 1, 5 do
							local spikePos = checkPos + VT(MRANDOM(-22, 22), 0, MRANDOM(-22, 22))
							local ray = workspace:Raycast(spikePos + VT(0, 10, 0), VT(0, -30, 0))
							if ray then
								-- Ensure icicle is anchored to ground properly
								local groundPos = ray.Position
								local iceSpike = CreatePart(VT(8, 35, 8), CF(groundPos) * CF(0, 17.5, 0), Color3.new(0.7, 0.85, 1), Enum.Material.Ice, 0, true)
								iceSpike.Anchored = true -- Ensure it's anchored
								local spikeMesh = Instance.new("SpecialMesh")
								spikeMesh.MeshType = Enum.MeshType.FileMesh
								spikeMesh.MeshId = "rbxassetid://1033714"
								spikeMesh.Scale = VT(4, 17.5, 4)
								spikeMesh.Parent = iceSpike

								-- Ice spike grows
								iceSpike.Size = VT(1, 1, 1)
								TweenService:Create(iceSpike, TweenInfo.new(0.8), {Size = VT(8, 35, 8)}):Play()

								Debris:AddItem(iceSpike, 25)
							end
						end

						-- Frozen ground effect
						CreateEffect("Ring", CF(checkPos), VT(15, 1, 15), VT(60, 1, 60), Color3.new(0.7, 0.9, 1), 0.4, nil, 2)
					end

					task.wait(0.025)
				end
			end)()

			-- Beam fade
			TweenService:Create(megaBeam, TweenInfo.new(3), {
				Size = VT(8, 8, 180),
				Transparency = 1
			}):Play()
			TweenService:Create(beamCore, TweenInfo.new(3), {
				Size = VT(4, 4, 180),
				Transparency = 1
			}):Play()
			TweenService:Create(beamMist, TweenInfo.new(3), {
				Size = VT(12, 12, 180),
				Transparency = 1
			}):Play()
			TweenService:Create(beamLight, TweenInfo.new(3), {Brightness = 0}):Play()

			Debris:AddItem(megaBeam, 3)
			Debris:AddItem(beamCore, 3)
			Debris:AddItem(beamMist, 3)

			task.wait(0.2)
		end

		task.wait(1)

		-- PHASE 4: GLACIAL EXPLOSION - Crystal shatters with proper timing
		-- Play explosion sound first
		CreatePositionalSound("massive_explosion", frozenCrystal.Position, 5, 0.3, false, "Massive explosion sound")

		-- Wait a moment for sound to start, then begin shatter
		task.wait(0.2)

		-- Crystal explodes into shards - synchronized with explosion sound
		for shard = 1, 50 do
			local shardAngle = (shard / 50) * math.pi * 2
			local shardDir = VT(math.cos(shardAngle) * MRANDOM(50, 150), MRANDOM(-30, 100), math.sin(shardAngle) * MRANDOM(50, 150))

			local iceShard = CreatePart(VT(8, 20, 8), frozenCrystal.CFrame, Color3.new(0.7, 0.9, 1), Enum.Material.Ice, 0.2, false)
			local shardMesh = Instance.new("SpecialMesh")
			shardMesh.MeshType = Enum.MeshType.FileMesh
			shardMesh.MeshId = "rbxassetid://1033714"
			shardMesh.Scale = VT(4, 10, 4)
			shardMesh.Parent = iceShard

			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = VT(1e9, 1e9, 1e9)
			bv.Velocity = shardDir
			bv.Parent = iceShard

			iceShard.Touched:Connect(function(hit)
				if hit.Parent ~= CHARACTER and hit.Parent ~= Effects then
					-- Shard explosion
					CreateEffect("Sphere", CF(iceShard.Position), VT(8, 8, 8), VT(35, 35, 35), Color3.new(0.7, 0.9, 1), 0.4, nil, 2)
					ApplyAoE(iceShard.Position, 25, 110, 60)
					iceShard:Destroy()
				end
			end)

			Debris:AddItem(iceShard, 6)
		end

		-- Destroy crystal
		TweenService:Create(frozenCrystal, TweenInfo.new(1), {
			Size = VT(200, 300, 200),
			Transparency = 1
		}):Play()
		Debris:AddItem(frozenCrystal, 1)

		task.wait(2)

		-- Restore lighting gradually
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()

		task.wait(1.5)
		Attack = false
		AttackCooldowns.CryoBlast = tick()
	end

	-- Attack 12: APOCALYPTIC GRAVITY COLLAPSE
	local function GravityCollapse()
		if not canUseAttack() then return end
		Attack = true

		-- Store original environment
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor
		local origGravity = workspace.Gravity

		-- PHASE 1: SPACETIME DISTORTION - Environment warps
		DisplayTaunt("GRAVITY ITSELF BENDS TO MY WILL!", 3, Color3.fromRGB(100, 0, 100))
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2.5, 0.5, false, "Time distortion/slow effect sound")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.3,
			Ambient = Color3.fromRGB(30, 0, 60),
			ColorShift_Top = Color3.fromRGB(80, 0, 120),
			FogEnd = 180,
			FogColor = Color3.fromRGB(20, 0, 50)
		}):Play()

		-- Gravity fluctuation
		TweenService:Create(workspace, TweenInfo.new(2), {Gravity = 250}):Play()

		-- Create massive gravity well with layered cores
		local gravityCore = CreatePart(VT(20, 20, 20), ROOTPART.CFrame * CF(0, 35, 0), Color3.new(0.05, 0, 0.15), Enum.Material.ForceField, 0.1, true)
		gravityCore.Shape = Enum.PartType.Ball

		-- Inner core
		local innerCore = CreatePart(VT(12, 12, 12), gravityCore.CFrame, Color3.new(0.2, 0, 0.4), Enum.Material.Neon, 0, true)
		innerCore.Shape = Enum.PartType.Ball

		-- Singularity point
		local singularity = CreatePart(VT(4, 4, 4), gravityCore.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)
		singularity.Shape = Enum.PartType.Ball

		-- Massive point light
		local coreLight = Instance.new("PointLight")
		coreLight.Brightness = 25
		coreLight.Color = Color3.new(0.2, 0, 0.5)
		coreLight.Range = 150
		coreLight.Parent = gravityCore

		-- Pulsing gravity effect with space-time warping
		coroutine.wrap(function()
			for i = 1, 100 do
				if gravityCore.Parent then
					local pulse = math.sin(i * 0.3) * 8
					gravityCore.Size = VT(20, 20, 20) + VT(pulse, pulse, pulse)
					innerCore.CFrame = gravityCore.CFrame
					innerCore.Size = VT(12, 12, 12) + VT(pulse * 0.6, pulse * 0.6, pulse * 0.6)
					singularity.CFrame = gravityCore.CFrame

					-- Space-time distortion ripples
					if i % 8 == 0 then
						local ripple = CreatePart(VT(15, 15, 15), gravityCore.CFrame, Color3.new(0.1, 0, 0.3), Enum.Material.Neon, 0.7, true)
						ripple.Shape = Enum.PartType.Ball
						TweenService:Create(ripple, TweenInfo.new(1.2), {
							Size = VT(60, 60, 60),
							Transparency = 1
						}):Play()
						Debris:AddItem(ripple, 1.2)
					end
					task.wait()
				end
			end
		end)()

		-- OPTIMIZED: Reduced ring count
		for ring = 1, 8 do
			local gRing = CreatePart(VT(35 + ring*12, 4, 35 + ring*12), gravityCore.CFrame, Color3.new(0.15 + ring*0.01, 0, 0.3 + ring*0.02), Enum.Material.Neon, 0.4 + ring*0.02, true)
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://3270017"
			mesh.Scale = VT(35 + ring*12, 35 + ring*12, 4)
			mesh.Parent = gRing

			coroutine.wrap(function()
				local rotation = ring * 15
				while gravityCore.Parent do
					rotation = rotation + ring * 1.5
					gRing.CFrame = gravityCore.CFrame * ANGLES(RAD(rotation), RAD(rotation * 0.7), RAD(rotation * 0.5))
					task.wait()
				end
			end)()

			Debris:AddItem(gRing, 10)
		end

		-- OPTIMIZED: Reduced debris count
		for debris = 1, 12 do
			local debrisPart = CreatePart(VT(3, 3, 3), gravityCore.CFrame * CF(MRANDOM(-80, 80), MRANDOM(-40, 40), MRANDOM(-80, 80)), Color3.new(0.3, 0.3, 0.4), Enum.Material.Slate, 0, false)

			coroutine.wrap(function()
				while debrisPart.Parent and gravityCore.Parent do
					local direction = (gravityCore.Position - debrisPart.Position).Unit
					debrisPart.Position = debrisPart.Position + direction * 2
					debrisPart.CFrame = debrisPart.CFrame * ANGLES(RAD(5), RAD(3), RAD(4))

					if (debrisPart.Position - gravityCore.Position).Magnitude < 15 then
						CreateEffect("Sphere", CF(debrisPart.Position), VT(4, 4, 4), VT(12, 12, 12), Color3.new(0.2, 0, 0.4), 0.5, nil, 1.5)
						debrisPart:Destroy()
						break
					end
					task.wait()
				end
			end)()

			Debris:AddItem(debrisPart, 10)
		end

		task.wait(2.5)

		-- OPTIMIZED: Reduced pull iterations
		for pull = 1, 40 do
			-- Enhanced visual pull effects
			if pull % 2 == 0 then
				CreateEffect("Ring", gravityCore.CFrame * ANGLES(RAD(90), RAD(pull * 6), 0), VT(90, 90, 1), VT(8, 8, 1), Color3.new(0.1, 0, 0.3), 0.8, nil, 2)
			end

			-- Gravity waves
			if pull % 5 == 0 then
				for wave = 1, 3 do
					CreateEffect("Sphere", gravityCore.CFrame, VT(20 + wave*15, 20 + wave*15, 20 + wave*15), VT(25 + wave*15, 25 + wave*15, 25 + wave*15), Color3.new(0.15, 0, 0.35), 0.6, nil, 2)
				end
			end

			-- Pull and damage players - OPTIMIZED with crushing effect
			for _, playerData in pairs(cachedPlayers) do
				if playerData.RootPart and playerData.Model and not playerData.Model:FindFirstChild("Classification") then
					local dist = (playerData.RootPart.Position - gravityCore.Position).Magnitude
					if dist <= 120 then
						-- Stronger pull the closer they are
						local pullStrength = math.max(30, 100 - dist * 0.5)
						local pullForce = Instance.new("BodyVelocity")
						pullForce.MaxForce = VT(1e9, 1e9, 1e9)
						pullForce.Velocity = (gravityCore.Position - playerData.RootPart.Position).Unit * pullStrength
						pullForce.Parent = playerData.RootPart
						Debris:AddItem(pullForce, 0.15)

						-- Crushing damage based on proximity
						if dist <= 50 then
							ApplyDamage(playerData.Humanoid, 100 * (1 - dist/50), targetPlayer)

							-- Spaghettification visual near singularity
							if dist <= 25 and pull % 3 == 0 then
								local stretchEffect = CreatePart(VT(1, 8, 1), playerData.RootPart.CFrame, Color3.new(0.8, 0, 0.9), Enum.Material.Neon, 0.5, true)
								TweenService:Create(stretchEffect, TweenInfo.new(0.5), {
									Size = VT(0.2, 15, 0.2),
									Transparency = 1
								}):Play()
								Debris:AddItem(stretchEffect, 0.5)
							end
						end
					end
				end
			end
			task.wait(0.08)
		end

		-- PHASE 4: BLACK HOLE DETONATION - Massive gravitational explosion
		-- Use positional sounds to prevent cutoff
		CreatePositionalSound("intro_explosion", gravityCore.Position, 5, 0.2, false, "Massive explosion sound")
		CreatePositionalSound("dimensional_rift", gravityCore.Position, 4, 0.4, false, "Dimensional rift/portal sound")
		DisplayTaunt("COLLAPSE!!!", 2, Color3.fromRGB(200, 0, 255))

		-- Zero gravity moment
		TweenService:Create(workspace, TweenInfo.new(0.5), {Gravity = 0}):Play()

		-- Collapse animation
		TweenService:Create(gravityCore, TweenInfo.new(1.5), {Size = VT(2, 2, 2)}):Play()
		TweenService:Create(innerCore, TweenInfo.new(1.5), {Size = VT(1, 1, 1)}):Play()
		TweenService:Create(singularity, TweenInfo.new(1.5), {Size = VT(0.2, 0.2, 0.2)}):Play()

		task.wait(1.5)

		-- Massive gravitational explosions
		for explosion = 1, 30 do
			local expPos = gravityCore.Position + VT(MRANDOM(-70, 70), MRANDOM(-70, 70), MRANDOM(-70, 70))
			CreateEffect("Sphere", CF(expPos), VT(20, 20, 20), VT(70, 70, 70), Color3.new(0.1 + math.random()/5, 0, 0.3 + math.random()/5), 0.8, nil, 4)
			task.wait(0.04)
		end

		-- Epicenter blast
		ApplyAoE(gravityCore.Position, 120, 500, 250)

		-- Gravity shockwave rings
		for wave = 1, 8 do
			CreateEffect("Sphere", gravityCore.CFrame, VT(15, 15, 15), VT(120 + wave*50, 120 + wave*50, 120 + wave*50), Color3.new(0.2, 0, 0.5), 1, nil, 3)
			CreateEffect("Ring", gravityCore.CFrame * ANGLES(RAD(90), 0, 0), VT(30, 30, 1), VT(150 + wave*40, 150 + wave*40, 1), Color3.new(0.15, 0, 0.4), 0.8, nil, 2.5)
			task.wait(0.15)
		end

		gravityCore:Destroy()
		innerCore:Destroy()
		singularity:Destroy()

		task.wait(1)

		-- Restore environment
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(3), {Gravity = origGravity}):Play()

		task.wait(1)
		Attack = false
		AttackCooldowns.GravityCollapse = tick()
	end

	-- Attack 13: APOCALYPTIC PLASMA CASCADE
	local function PlasmaCascade()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor

		DisplayTaunt("PLASMA CASCADE UNLEASHED!", 3, Color3.fromRGB(150, 100, 255))
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 2.5, 0.8, false, "Plasma energy charging sound")

		-- PHASE 1: PLASMA STORM FORMATION - Environment turns purple/magenta
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Brightness = 2.5,
			Ambient = Color3.fromRGB(150, 60, 200),
			ColorShift_Top = Color3.fromRGB(200, 100, 255),
			FogEnd = 280,
			FogColor = Color3.fromRGB(140, 80, 190)
		}):Play()

		-- Giant plasma vortex in sky
		local plasmaVortex = CreatePart(VT(220, 15, 220), ROOTPART.CFrame * CF(0, 150, 0), Color3.new(0.8, 0.5, 1), Enum.Material.Neon, 0.4, true)
		local vortexMesh = Instance.new("SpecialMesh")
		vortexMesh.MeshType = Enum.MeshType.Cylinder
		vortexMesh.Scale = VT(0.07, 1, 1)
		vortexMesh.Parent = plasmaVortex
		plasmaVortex.CFrame = plasmaVortex.CFrame * ANGLES(0, 0, RAD(90))

		-- Vortex light
		local vortexLight = Instance.new("PointLight")
		vortexLight.Brightness = 90
		vortexLight.Color = Color3.new(0.9, 0.6, 1)
		vortexLight.Range = 550
		vortexLight.Parent = plasmaVortex

		-- Rotating vortex
		coroutine.wrap(function()
			for i = 1, 140 do
				if plasmaVortex.Parent then
					plasmaVortex.CFrame = plasmaVortex.CFrame * ANGLES(0, RAD(3), 0)
					vortexLight.Brightness = 90 + math.sin(i * 0.2) * 25
					task.wait()
				end
			end
		end)()

		-- Plasma pillars descending
		for pillar = 1, 12 do
			local pillarAngle = (pillar / 12) * math.pi * 2
			local pillarPos = ROOTPART.Position + VT(math.cos(pillarAngle) * 60, 0, math.sin(pillarAngle) * 60)
			local plasmaPillar = CreatePart(VT(15, 170, 15), CF(pillarPos) * CF(0, 85, 0), Color3.new(0.9, 0.6, 1), Enum.Material.Neon, 0.4, true)

			TweenService:Create(plasmaPillar, TweenInfo.new(1.8), {
				Size = VT(20, 170, 20),
				Transparency = 0.6
			}):Play()

			Debris:AddItem(plasmaPillar, 10)
		end

		task.wait(2)

		-- PHASE 2: PLASMA NODE NETWORK - Create massive plasma spheres
		CreatePositionalSound("energy_beam", ROOTPART.Position, 4, 0.5, false, "Energy beam sound")
		DisplayTaunt("PLASMA OVERLOAD!", 2, Color3.fromRGB(200, 100, 255))

		local plasmaNodes = {}
		for node = 1, 6 do -- Reduced nodes for optimization
			local nodeAngle = (node / 6) * math.pi * 2
			local nodePos = ROOTPART.Position + VT(math.cos(nodeAngle) * 55, 35 + node*8, math.sin(nodeAngle) * 55)

			-- Giant plasma node
			local plasmaNode = CreatePart(VT(35, 35, 35), CF(nodePos), Color3.new(0.8, 0.5, 1), Enum.Material.Neon, 0.3, true)
			plasmaNode.Shape = Enum.PartType.Ball
			table.insert(plasmaNodes, plasmaNode)

			-- Node core
			local nodeCore = CreatePart(VT(20, 20, 20), plasmaNode.CFrame, Color3.new(1, 0.9, 1), Enum.Material.Neon, 0, true)
			nodeCore.Shape = Enum.PartType.Ball

			-- Node light
			local nodeLight = Instance.new("PointLight")
			nodeLight.Brightness = 50
			nodeLight.Color = Color3.new(0.9, 0.6, 1)
			nodeLight.Range = 130
			nodeLight.Parent = plasmaNode

			-- Orbiting plasma rings
			for ring = 1, 2 do -- Reduced rings for optimization
				local plasmaRing = CreatePart(VT(50 + ring*12, 3, 50 + ring*12), plasmaNode.CFrame, Color3.new(0.9, 0.6, 1), Enum.Material.Neon, 0.6, true)
				local ringMesh = Instance.new("SpecialMesh")
				ringMesh.MeshType = Enum.MeshType.FileMesh
				ringMesh.MeshId = "rbxassetid://3270017"
				ringMesh.Scale = VT(50 + ring*12, 50 + ring*12, 3)
				ringMesh.Parent = plasmaRing

				coroutine.wrap(function()
					local rotation = 0
					while plasmaNode.Parent do
						rotation = rotation + ring * 2.5
						plasmaRing.CFrame = plasmaNode.CFrame * ANGLES(RAD(rotation), RAD(rotation * 0.8), RAD(rotation * 0.6))
						task.wait()
					end
				end)()

				Debris:AddItem(plasmaRing, 10)
			end

			-- Node pulsing
			coroutine.wrap(function()
				for i = 1, 200 do
					if plasmaNode.Parent and nodeCore.Parent then
						local pulse = math.sin(i * 0.16)
						plasmaNode.Size = VT(35, 35, 35) + VT(pulse, pulse, pulse) * 10
						nodeCore.Size = VT(20, 20, 20) + VT(pulse, pulse, pulse) * 6
						nodeCore.CFrame = plasmaNode.CFrame

						-- Emit plasma particles
						if i % 5 == 0 then
							local particle = CreatePart(VT(4, 4, 4), plasmaNode.CFrame * CF(MRANDOM(-18, 18), MRANDOM(-18, 18), MRANDOM(-18, 18)), Color3.new(0.9, 0.6, 1), Enum.Material.Neon, 0.3, true)
							particle.Shape = Enum.PartType.Ball
							TweenService:Create(particle, TweenInfo.new(1.2), {
								Size = VT(1, 1, 1),
								Transparency = 1
							}):Play()
							Debris:AddItem(particle, 1.2)
						end

						task.wait()
					end
				end
			end)()

			Debris:AddItem(nodeCore, 10)
		end

		task.wait(2)

		-- PHASE 3: PLASMA LIGHTNING NETWORK - Massive cascading lightning
		CreatePositionalSound("lightning_strike", ROOTPART.Position, 4, 0.4, false, "Lightning strike sound")

		for i = 1, #plasmaNodes do
			for j = i + 1, #plasmaNodes do
				if plasmaNodes[i].Parent and plasmaNodes[j].Parent then
					local distance = (plasmaNodes[i].Position - plasmaNodes[j].Position).Magnitude

					-- Giant plasma cascade bolt
					local bolt = CreatePart(VT(12, 12, distance), CF(plasmaNodes[i].Position, plasmaNodes[j].Position) * CF(0, 0, -distance/2), Color3.new(0.8, 0.5, 1), Enum.Material.Neon, 0.3, true)

					-- Bolt core
					local boltCore = CreatePart(VT(6, 6, distance), bolt.CFrame, Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)

					-- Pulsing effect
					coroutine.wrap(function()
						for pulse = 1, 50 do
							if bolt.Parent then
								bolt.Transparency = 0.3 + math.sin(pulse * 0.5) * 0.2
								task.wait()
							end
						end
					end)()

					TweenService:Create(bolt, TweenInfo.new(5), {Transparency = 1}):Play()
					TweenService:Create(boltCore, TweenInfo.new(5), {Transparency = 1}):Play()
					Debris:AddItem(bolt, 5)
					Debris:AddItem(boltCore, 5)
				end
			end
		end

		task.wait(1.5)

		-- PHASE 4: PLASMA RAIN APOCALYPSE - Massive plasma projectiles
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 4, 0.4, false, "Massive explosion sound")

		for wave = 1, 30 do -- Reduced waves for optimization
			for _, node in ipairs(plasmaNodes) do
				if node.Parent then
					for proj = 1, 1 do -- Reduced projectiles per node
						-- Giant plasma projectile
						local plasmaProj = CreatePart(VT(10, 10, 10), node.CFrame * CF(MRANDOM(-25, 25), MRANDOM(-15, 15), MRANDOM(-25, 25)), Color3.new(0.9, 0.6, 1), Enum.Material.Neon, 0.2, false)
						plasmaProj.Shape = Enum.PartType.Ball

						-- Projectile core
						local projCore = CreatePart(VT(5, 5, 5), plasmaProj.CFrame, Color3.new(1, 0.9, 1), Enum.Material.Neon, 0, true)
						projCore.Shape = Enum.PartType.Ball

						-- Attach core
						coroutine.wrap(function()
							while plasmaProj.Parent and projCore.Parent do
								projCore.CFrame = plasmaProj.CFrame
								task.wait()
							end
						end)()

						-- Epic plasma trail
						coroutine.wrap(function()
							while plasmaProj.Parent do
								local trail = CreatePart(VT(8, 8, 8), plasmaProj.CFrame, Color3.new(0.8, 0.5, 1), Enum.Material.Neon, 0.6, true)
								trail.Shape = Enum.PartType.Ball
								TweenService:Create(trail, TweenInfo.new(1), {
									Size = VT(2, 2, 2),
									Transparency = 1
								}):Play()
								Debris:AddItem(trail, 1)
								task.wait(0.1)
							end
						end)()

						local targetPos = ROOTPART.Position + VT(MRANDOM(-60, 60), MRANDOM(-20, 30), MRANDOM(-60, 60))
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = (targetPos - node.Position).Unit * 110
						bv.Parent = plasmaProj

						plasmaProj.Touched:Connect(function(hit)
							if hit.Parent ~= CHARACTER and hit.Parent ~= Effects then
								-- Plasma explosion
								CreateEffect("Sphere", CF(plasmaProj.Position), VT(10, 10, 10), VT(50, 50, 50), Color3.new(0.9, 0.6, 1), 0.4, nil, 2.5)

								-- Plasma burst ring
								CreateEffect("Ring", CF(plasmaProj.Position), VT(15, 1, 15), VT(70, 1, 70), Color3.new(0.8, 0.5, 1), 0.5, nil, 2)

								ApplyAoE(plasmaProj.Position, 30, 95, 50)
								plasmaProj:Destroy()
								if projCore.Parent then projCore:Destroy() end
							end
						end)

						Debris:AddItem(plasmaProj, 6)
						Debris:AddItem(projCore, 6)
					end
				end
			end
			task.wait(0.15) -- Less frequent waves for optimization
		end

		task.wait(1)

		-- PHASE 5: CASCADE DETONATION - All nodes explode
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.4, false, "Intro explosion sound")
		DisplayTaunt("CASCADE DETONATION!", 2, Color3.fromRGB(255, 255, 255))

		for _, node in ipairs(plasmaNodes) do
			if node.Parent then
				-- Massive plasma explosion
				for burst = 1, 10 do
					CreateEffect("Sphere", node.CFrame, VT(30, 30, 30), VT(100 + burst*25, 100 + burst*25, 100 + burst*25), Color3.new(0.9 - burst*0.05, 0.6, 1), 0.7, nil, 3)
					task.wait(0.05)
				end

				-- Plasma shockwave rings
				for ring = 1, 5 do
					CreateEffect("Ring", node.CFrame, VT(40, 1, 40), VT(180 + ring*40, 1, 180 + ring*40), Color3.new(0.8, 0.5, 1), 0.6, nil, 2.5)
					task.wait(0.06)
				end

				ApplyAoE(node.Position, 70, 220, 100)
				node:Destroy()
			end
		end

		-- Destroy vortex
		TweenService:Create(plasmaVortex, TweenInfo.new(2), {
			Size = VT(300, 15, 300),
			Transparency = 1
		}):Play()
		Debris:AddItem(plasmaVortex, 2)

		task.wait(2)

		-- Restore lighting
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()

		task.wait(1)
		Attack = false
		AttackCooldowns.PlasmaCascade = tick()
	end

	-- Attack 14: APOCALYPTIC REALITY SHATTER
	local function RealityShatter()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor
		local origGravity = workspace.Gravity

		DisplayTaunt("REALITY ITSELF FRACTURES!", 3, Color3.fromRGB(200, 0, 200))
		CreatePositionalSound("reality_tear", ROOTPART.Position, 2.5, 0.5, false, "Reality tear/fracture sound")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2, 0.3, false, "Time distortion/slow effect sound")
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 2, 0.4, false, "Dimensional rift sound")

		-- PHASE 1: REALITY DISTORTION - Environment glitches violently
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Brightness = 1.5,
			Ambient = Color3.fromRGB(100, 0, 150),
			ColorShift_Top = Color3.fromRGB(180, 0, 220),
			FogEnd = 200,
			FogColor = Color3.fromRGB(80, 0, 120)
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(1.5), {Gravity = 120}):Play()

		-- Giant dimensional rift in sky
		local dimensionalRift = CreatePart(VT(250, 12, 250), ROOTPART.CFrame * CF(0, 160, 0), Color3.new(0.3, 0, 0.5), Enum.Material.ForceField, 0.3, true)
		local riftMesh = Instance.new("SpecialMesh")
		riftMesh.MeshType = Enum.MeshType.Cylinder
		riftMesh.Scale = VT(0.05, 1, 1)
		riftMesh.Parent = dimensionalRift
		dimensionalRift.CFrame = dimensionalRift.CFrame * ANGLES(0, 0, RAD(90))

		-- Rift light
		local riftLight = Instance.new("PointLight")
		riftLight.Brightness = 100
		riftLight.Color = Color3.new(0.5, 0, 0.8)
		riftLight.Range = 650
		riftLight.Parent = dimensionalRift

		-- Pulsing rift
		coroutine.wrap(function()
			for i = 1, 150 do
				if dimensionalRift.Parent then
					dimensionalRift.CFrame = dimensionalRift.CFrame * ANGLES(0, RAD(2.5), 0)
					riftLight.Brightness = 100 + math.sin(i * 0.25) * 35
					task.wait()
				end
			end
		end)()

		-- Reality distortion waves from rift
		for wave = 1, 10 do
			local distortWave = CreatePart(VT(180 + wave*20, 8, 180 + wave*20), dimensionalRift.CFrame, Color3.new(0.4, 0, 0.7), Enum.Material.ForceField, 0.6, true)
			local waveMesh = Instance.new("SpecialMesh")
			waveMesh.MeshType = Enum.MeshType.Cylinder
			waveMesh.Scale = VT(0.04, 1, 1)
			waveMesh.Parent = distortWave

			TweenService:Create(distortWave, TweenInfo.new(2), {
				Size = VT(220 + wave*25, 8, 220 + wave*25),
				Transparency = 1
			}):Play()

			Debris:AddItem(distortWave, 2)
			task.wait(0.15)
		end

		task.wait(2)

		-- PHASE 2: MASSIVE REALITY FRACTURES - Giant dimensional tears
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 4, 0.4, false, "Dimensional rift sound")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.5, false, "Reality tear sound")
		CreatePositionalSound("energy_beam", ROOTPART.Position, 2, 0.3, false, "Energy beam sound")
		DisplayTaunt("REALITY FRACTURES!", 2, Color3.fromRGB(200, 0, 255))

		local fractures = {}
		for f = 1, 15 do
			local fractureAngle = (f / 15) * math.pi * 2
			local fracturePos = ROOTPART.Position + VT(math.cos(fractureAngle) * 60, 40 + f*6, math.sin(fractureAngle) * 60)

			-- Massive reality fracture disc
			local fracture = CreatePart(VT(50, 50, 3), CF(fracturePos) * ANGLES(RAD(MRANDOM(-45, 45)), RAD(MRANDOM(0, 360)), RAD(MRANDOM(-45, 45))), Color3.new(0, 0, 0), Enum.Material.Neon, 0, true)
			fracture.Shape = Enum.PartType.Ball

			-- Giant flattened disc
			local fractureMesh = Instance.new("SpecialMesh")
			fractureMesh.MeshType = Enum.MeshType.Sphere
			fractureMesh.Scale = VT(1, 1, 0.06)
			fractureMesh.Parent = fracture

			-- Multiple layers
			local fracture2 = CreatePart(VT(35, 35, 2), fracture.CFrame, Color3.new(0.3, 0, 0.5), Enum.Material.Neon, 0.3, true)
			fracture2.Shape = Enum.PartType.Ball
			local fractureMesh2 = Instance.new("SpecialMesh")
			fractureMesh2.MeshType = Enum.MeshType.Sphere
			fractureMesh2.Scale = VT(1, 1, 0.06)
			fractureMesh2.Parent = fracture2

			local fracture3 = CreatePart(VT(25, 25, 1.5), fracture.CFrame, Color3.new(0.5, 0, 0.8), Enum.Material.Neon, 0.5, true)
			fracture3.Shape = Enum.PartType.Ball
			local fractureMesh3 = Instance.new("SpecialMesh")
			fractureMesh3.MeshType = Enum.MeshType.Sphere
			fractureMesh3.Scale = VT(1, 1, 0.06)
			fractureMesh3.Parent = fracture3

			-- Reality glow
			local glowLight = Instance.new("PointLight")
			glowLight.Brightness = 45
			glowLight.Color = Color3.new(0.5, 0, 0.8)
			glowLight.Range = 90
			glowLight.Parent = fracture

			-- Glitching animation
			coroutine.wrap(function()
				for i = 1, 120 do
					if fracture.Parent then
						fracture.Color = Color3.new(MRANDOM(0, 10)/10, 0, MRANDOM(5, 10)/10)
						fracture.CFrame = fracture.CFrame * ANGLES(RAD(MRANDOM(-10, 10)), RAD(MRANDOM(-8, 8)), 0)
						fracture2.CFrame = fracture.CFrame
						fracture3.CFrame = fracture.CFrame

						-- Massive reality shards
						if i % 6 == 0 then
							local shard = CreatePart(VT(5, 15, 1), fracture.CFrame * CF(MRANDOM(-15, 15), MRANDOM(-20, 20), 0), Color3.new(MRANDOM(1, 8)/10, 0, MRANDOM(4, 10)/10), Enum.Material.Neon, 0.2, false)
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = VT(1e9, 1e9, 1e9)
							bv.Velocity = VT(MRANDOM(-50, 50), MRANDOM(-30, 30), MRANDOM(-50, 50))
							bv.Parent = shard
							TweenService:Create(shard, TweenInfo.new(2), {Transparency = 1}):Play()
							Debris:AddItem(shard, 2)
						end
						task.wait(0.03)
					end
				end
			end)()

			-- Damage and distortion around fracture
			coroutine.wrap(function()
				for wave = 1, 80 do
					ApplyAoE(fracturePos, 35, 45, 20)
					if wave % 4 == 0 then
						CreateEffect("Sphere", CF(fracturePos) * CF(MRANDOM(-20, 20), MRANDOM(-20, 20), MRANDOM(-20, 20)), VT(15, 15, 15), VT(35, 35, 35), Color3.new(0.4, 0, 0.7), 0.6, nil, 1.5)
					end
					task.wait(0.1)
				end
			end)()

			table.insert(fractures, fracture)
			Debris:AddItem(fracture, 10)
			Debris:AddItem(fracture2, 10)
			Debris:AddItem(fracture3, 10)
		end

		task.wait(3)

		-- PHASE 3: REALITY COLLAPSE - All fractures implode
		DisplayTaunt("REALITY COLLAPSE!", 2, Color3.fromRGB(255, 0, 255))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 5, 0.3, false, "Dimensional rift sound")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 4, 0.5, false, "Massive explosion")

		-- Gravity goes insane
		TweenService:Create(workspace, TweenInfo.new(0.5), {Gravity = 30}):Play()

		for _, fracture in ipairs(fractures) do
			if fracture.Parent then
				local fracturePos = fracture.Position

				-- Implosion sequence
				for implode = 1, 10 do
					CreateEffect("Sphere", CF(fracturePos), VT(60 - implode*5, 60 - implode*5, 60 - implode*5), VT(10, 10, 10), Color3.new(0.3 + implode*0.05, 0, 0.5 + implode*0.05), 0.5, nil, 2)
					task.wait(0.04)
				end

				-- Massive explosion with sound
				CreatePositionalSound("explosion_impact", fracturePos, 3, MRANDOM(7, 12)/10, false, "Reality fracture explosion")
				CreatePositionalSound("massive_explosion", fracturePos, 2, MRANDOM(6, 10)/10, false, "Massive explosion")
				CreateEffect("Sphere", CF(fracturePos), VT(15, 15, 15), VT(80, 80, 80), Color3.new(0.5, 0, 0.8), 0.7, nil, 3)

				-- Enhanced shockwave rings with better visuals
				for ring = 1, 8 do
					CreateEffect("Ring", CF(fracturePos) * ANGLES(RAD(MRANDOM(-10, 10)), RAD(MRANDOM(-10, 10)), 0), VT(30, 1, 30), VT(120 + ring*30, 1, 120 + ring*30), Color3.new(0.4, 0, 0.7), 0.6, nil, 2.5)
					task.wait(0.04)
				end

				-- Additional reality distortion particles
				for particle = 1, 8 do
					local particlePos = fracturePos + VT(MRANDOM(-30, 30), MRANDOM(-30, 30), MRANDOM(-30, 30))
					CreateEffect("Sphere", CF(particlePos), VT(8, 8, 8), VT(25, 25, 25), Color3.new(MRANDOM(3, 7)/10, 0, MRANDOM(5, 9)/10), 0.5, nil, 2)
				end

				ApplyAoE(fracturePos, 50, 250, 110)
				fracture:Destroy()
			end
		end

		-- Close dimensional rift
		TweenService:Create(dimensionalRift, TweenInfo.new(2), {
			Size = VT(350, 12, 350),
			Transparency = 1
		}):Play()
		Debris:AddItem(dimensionalRift, 2)

		task.wait(2)

		-- Restore environment
		TweenService:Create(Lighting, TweenInfo.new(2.5), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(2.5), {Gravity = origGravity}):Play()

		task.wait(1.5)
		Attack = false
		AttackCooldowns.RealityShatter = tick()
	end

	-- Attack 16: APOCALYPTIC SOLAR FLARE BURST
	local function SolarFlareBurst()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor

		DisplayTaunt("FEEL THE FURY OF A THOUSAND SUNS!", 3, Color3.fromRGB(255, 200, 0))
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 2, 0.8, false, "Cosmic/space ambient sound")

		-- Environment turns blazing orange/yellow like solar fire
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Brightness = 5,
			Ambient = Color3.fromRGB(255, 180, 50),
			ColorShift_Top = Color3.fromRGB(255, 220, 100),
			FogEnd = 320,
			FogColor = Color3.fromRGB(255, 200, 80)
		}):Play()

		-- Create sun above with multiple layers
		local sun = CreatePart(VT(28, 28, 28), ROOTPART.CFrame * CF(0, 65, 0), Color3.new(1, 0.9, 0), Enum.Material.Neon, 0, true)
		sun.Shape = Enum.PartType.Ball

		-- Inner core
		local core = CreatePart(VT(18, 18, 18), sun.CFrame, Color3.new(1, 1, 0.9), Enum.Material.Neon, 0, true)
		core.Shape = Enum.PartType.Ball

		-- Photosphere layer
		local photosphere = CreatePart(VT(32, 32, 32), sun.CFrame, Color3.new(1, 0.8, 0), Enum.Material.ForceField, 0.4, true)
		photosphere.Shape = Enum.PartType.Ball

		local sunLight = Instance.new("PointLight")
		sunLight.Brightness = 30
		sunLight.Color = Color3.new(1, 0.85, 0)
		sunLight.Range = 200
		sunLight.Parent = sun

		-- Enhanced sun corona effect with solar prominences - Tracked for cleanup
		local coronaParts = {}
		for i = 1, 18 do
			local corona = CreatePart(VT(10, 10, 10), sun.CFrame, Color3.new(1, 0.7 + math.random()/10, 0), Enum.Material.Neon, 0.3, true)
			corona.Shape = Enum.PartType.Ball

			-- Solar prominence (flame-like projection)
			local prominence = CreatePart(VT(6, 20, 6), corona.CFrame, Color3.new(1, 0.6, 0), Enum.Material.Neon, 0.5, true)
			prominence.Shape = Enum.PartType.Ball

			table.insert(coronaParts, {Corona = corona, Prominence = prominence})

			coroutine.wrap(function()
				local angle = (i / 18) * math.pi * 2
				while sun.Parent do
					angle = angle + 0.06
					local radius = 26 + math.sin(tick() * 2 + i) * 4
					corona.CFrame = sun.CFrame * CF(math.cos(angle) * radius, math.sin(angle * 1.3) * 10, math.sin(angle) * radius)
					prominence.CFrame = corona.CFrame * CF(0, 12, 0)
					corona.Size = VT(10, 10, 10) + VT(math.sin(tick() * 3 + i) * 2, math.sin(tick() * 3 + i) * 2, math.sin(tick() * 3 + i) * 2)
					task.wait()
				end
			end)()

			Debris:AddItem(corona, 10)
			Debris:AddItem(prominence, 10)
		end

		-- Solar surface activity (bubbling effect)
		coroutine.wrap(function()
			for bubble = 1, 40 do
				if sun.Parent then
					local surfaceBubble = CreatePart(VT(8, 8, 8), sun.CFrame * CF(MRANDOM(-20, 20), MRANDOM(-20, 20), MRANDOM(-20, 20)), Color3.new(1, 0.8 + math.random()/5, 0), Enum.Material.Neon, 0.4, true)
					surfaceBubble.Shape = Enum.PartType.Ball
					TweenService:Create(surfaceBubble, TweenInfo.new(1.5), {
						Size = VT(15, 15, 15),
						Transparency = 1
					}):Play()
					Debris:AddItem(surfaceBubble, 1.5)
					task.wait(0.15)
				end
			end
		end)()

		-- Charge up with pulsing
		coroutine.wrap(function()
			for pulse = 1, 30 do
				if sun.Parent then
					core.CFrame = sun.CFrame
					photosphere.CFrame = sun.CFrame
					core.Size = VT(18, 18, 18) + VT(math.sin(pulse * 0.4) * 3, math.sin(pulse * 0.4) * 3, math.sin(pulse * 0.4) * 3)
					task.wait(0.1)
				end
			end
		end)()

		TweenService:Create(sun, TweenInfo.new(3), {Size = VT(80, 80, 80)}):Play()
		TweenService:Create(core, TweenInfo.new(3), {Size = VT(50, 50, 50)}):Play()
		TweenService:Create(photosphere, TweenInfo.new(3), {Size = VT(100, 100, 100)}):Play()
		task.wait(3)

		-- PHASE 2: SOLAR FLARE APOCALYPSE
		DisplayTaunt("SOLAR ERUPTION!", 2, Color3.fromRGB(255, 255, 0))
		-- Use positional sounds to prevent cutoff
		CreatePositionalSound("intro_explosion", sun.Position, 4, 0.4, false, "Massive explosion sound")
		CreatePositionalSound("intro_buildup", sun.Position, 3, 0.5, false, "Epic orchestral buildup/charge sound")

		-- Enhanced multiple directional flares with CME (Coronal Mass Ejection) effects
		for flare = 1, 24 do
			local flareAngle = (flare / 24) * math.pi * 2
			local flareDir = VT(math.cos(flareAngle), -0.25 + math.sin(flareAngle * 2) * 0.2, math.sin(flareAngle))

			-- Main flare body
			local flarePart = CreatePart(VT(12, 12, 140), sun.CFrame * CF(flareDir * 70), Color3.new(1, 0.7, 0), Enum.Material.Neon, 0.2, true)

			-- Flare core (hotter center)
			local flareCore = CreatePart(VT(6, 6, 140), flarePart.CFrame, Color3.new(1, 1, 0.9), Enum.Material.Neon, 0, true)

			-- Plasma outer layer
			local plasmaLayer = CreatePart(VT(16, 16, 140), flarePart.CFrame, Color3.new(1, 0.5, 0), Enum.Material.ForceField, 0.6, true)

			-- Enhanced damage along flare path with heat waves
			coroutine.wrap(function()
				for segment = 1, 25 do
					local segmentPos = sun.Position + (flareDir * segment * 6)
					ApplyAoE(segmentPos, 14, 120, 50)

					-- Heat wave visual
					if segment % 3 == 0 then
						CreateEffect("Sphere", CF(segmentPos), VT(10, 10, 10), VT(25, 25, 25), Color3.new(1, 0.7, 0), 0.6, nil, 2)
					end
					task.wait(0.04)
				end
			end)()

			-- Plasma particles along flare
			for particle = 1, 8 do
				local plasmaPart = CreatePart(VT(5, 5, 5), sun.CFrame * CF(flareDir * (20 + particle * 12)), Color3.new(1, 0.6 + math.random()/4, 0), Enum.Material.Neon, 0.3, false)
				plasmaPart.Shape = Enum.PartType.Ball

				local pv = Instance.new("BodyVelocity")
				pv.MaxForce = VT(1e9, 1e9, 1e9)
				pv.Velocity = flareDir * (80 + particle * 10)
				pv.Parent = plasmaPart

				TweenService:Create(plasmaPart, TweenInfo.new(2), {Transparency = 1}):Play()
				Debris:AddItem(plasmaPart, 2)
			end

			TweenService:Create(flarePart, TweenInfo.new(2), {Transparency = 1}):Play()
			TweenService:Create(flareCore, TweenInfo.new(2), {Transparency = 1}):Play()
			TweenService:Create(plasmaLayer, TweenInfo.new(2), {Transparency = 1}):Play()
			Debris:AddItem(flarePart, 2)
			Debris:AddItem(flareCore, 2)
			Debris:AddItem(plasmaLayer, 2)
		end

		-- Central supernova explosion
		task.wait(1.2)
		DisplayTaunt("SUPERNOVA!", 2, Color3.fromRGB(255, 255, 255))

		-- Multi-stage explosion
		for stage = 1, 6 do
			CreateEffect("Sphere", sun.CFrame, VT(40 + stage*15, 40 + stage*15, 40 + stage*15), VT(60 + stage*25, 60 + stage*25, 60 + stage*25), Color3.new(1, 0.9 - stage*0.1, stage*0.15), 1, nil, 4)
			ApplyAoE(sun.Position, 50 + stage*12, 450, 180)
			task.wait(0.15)
		end

		-- Shockwave rings
		for ring = 1, 8 do
			CreateEffect("Ring", sun.CFrame * ANGLES(RAD(90), RAD(ring * 45), 0), VT(30, 30, 2), VT(120 + ring*25, 120 + ring*25, 2), Color3.new(1, 0.8, 0.2), 1.5, nil, 3)
		end

		-- Cleanup all sun parts including orbs
		sun:Destroy()
		core:Destroy()
		photosphere:Destroy()

		-- Cleanup all corona and prominence parts
		for _, coronaData in ipairs(coronaParts) do
			if coronaData.Corona.Parent then
				coronaData.Corona:Destroy()
			end
			if coronaData.Prominence.Parent then
				coronaData.Prominence:Destroy()
			end
		end

		task.wait(1)

		-- Restore lighting
		TweenService:Create(Lighting, TweenInfo.new(2.5), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()

		task.wait(1)
		Attack = false
		AttackCooldowns.SolarFlareBurst = tick()
	end

	-- Attack 17: APOCALYPTIC TEMPORAL DISTORTION
	local function TemporalDistortion()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor
		local origGravity = workspace.Gravity

		DisplayTaunt("TIME ITSELF OBEYS ME!", 3, Color3.fromRGB(100, 255, 200))

		-- PHASE 1: TEMPORAL AWAKENING - Time warps and reality distorts
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Brightness = 1.2,
			Ambient = Color3.fromRGB(50, 200, 180),
			ColorShift_Top = Color3.fromRGB(100, 230, 210),
			FogEnd = 240,
			FogColor = Color3.fromRGB(70, 180, 160)
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(1.5), {Gravity = 80}):Play()
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2, 0.4, false, "Time distortion/slow effect sound")

		-- PHASE 2: TIME FIELD NETWORK - Create massive temporal anomaly fields
		local distortionFields = {}
		for f = 1, 12 do
			local fieldPos = ROOTPART.Position + VT(MRANDOM(-60, 60), MRANDOM(8, 30), MRANDOM(-60, 60))
			local field = CreatePart(VT(25, 35, 25), CF(fieldPos), Color3.new(0.2, 0.8, 0.8), Enum.Material.ForceField, 0.2, true)
			field.Shape = Enum.PartType.Ball

			-- Time crystal core
			local timeCrystal = CreatePart(VT(12, 12, 12), field.CFrame, Color3.new(0.4, 1, 1), Enum.Material.Neon, 0, true)
			timeCrystal.Shape = Enum.PartType.Ball

			-- Temporal distortion light
			local fieldLight = Instance.new("PointLight")
			fieldLight.Brightness = 18
			fieldLight.Color = Color3.new(0.3, 0.9, 0.9)
			fieldLight.Range = 50
			fieldLight.Parent = field

			table.insert(distortionFields, {Field = field, Crystal = timeCrystal})

			-- Enhanced temporal rings with multiple layers
			for ring = 1, 10 do
				local timeRing = CreatePart(VT(30 + ring*6, 3, 30 + ring*6), field.CFrame, Color3.new(0.3 + ring*0.04, 0.9, 0.9 + ring*0.01), Enum.Material.Neon, 0.5 + ring*0.03, true)
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.FileMesh
				mesh.MeshId = "rbxassetid://3270017"
				mesh.Scale = VT(30 + ring*6, 30 + ring*6, 3)
				mesh.Parent = timeRing

				coroutine.wrap(function()
					local rotation = ring * 20
					while field.Parent do
						rotation = rotation - ring * 2.5
						timeRing.CFrame = field.CFrame * ANGLES(RAD(rotation), RAD(rotation * 0.6), 0)
						timeCrystal.CFrame = field.CFrame
						task.wait()
					end
				end)()

				Debris:AddItem(timeRing, 15)
			end

			-- Time shards orbiting
			for shard = 1, 8 do
				local timeShard = CreatePart(VT(2, 8, 1), field.CFrame, Color3.new(0.3, 0.9, 1), Enum.Material.Neon, 0.3, true)

				coroutine.wrap(function()
					local angle = (shard / 8) * math.pi * 2
					while field.Parent do
						angle = angle + 0.08
						local radius = 18 + math.sin(angle * 2) * 4
						timeShard.CFrame = field.CFrame * CF(math.cos(angle) * radius, math.sin(angle * 1.5) * 10, math.sin(angle) * radius) * ANGLES(RAD(angle * 50), RAD(angle * 30), 0)
						task.wait()
					end
				end)()

				Debris:AddItem(timeShard, 15)
			end

			-- Time freeze bubbles
			coroutine.wrap(function()
				for bubble = 1, 50 do
					if field.Parent then
						local freezeBubble = CreatePart(VT(4, 4, 4), field.CFrame * CF(MRANDOM(-12, 12), MRANDOM(-15, 15), MRANDOM(-12, 12)), Color3.new(0.4, 1, 1), Enum.Material.Neon, 0.5, true)
						freezeBubble.Shape = Enum.PartType.Ball

						-- Freeze in place briefly then disappear
						task.wait(MRANDOM(5, 15) / 10)
						TweenService:Create(freezeBubble, TweenInfo.new(1), {Transparency = 1}):Play()
						Debris:AddItem(freezeBubble, 1)
						task.wait(0.2)
					end
				end
			end)()

			-- Enhanced time slow effect on players inside
			coroutine.wrap(function()
				for i = 1, 150 do
					if field.Parent then
						-- Pulsing field size
						field.Size = VT(25, 35, 25) + VT(math.sin(i * 0.3) * 5, math.sin(i * 0.3) * 7, math.sin(i * 0.3) * 5)
						field.CFrame = CF(fieldPos)

						-- OPTIMIZED: Use cached players
						for _, playerData in pairs(cachedPlayers) do
							if playerData.RootPart and playerData.Model and not playerData.Model:FindFirstChild("Classification") then
								local dist = (playerData.RootPart.Position - fieldPos).Magnitude
								if dist <= 25 then
									-- Time slow damage
									ApplyDamage(playerData.Humanoid, 20, targetPlayer)

									-- Time skip effect (random teleport)
									if MRANDOM(1, 15) == 1 then
										local oldPos = playerData.RootPart.Position
										playerData.RootPart.CFrame = playerData.RootPart.CFrame * CF(MRANDOM(-8, 8), 0, MRANDOM(-8, 8))

										-- Time skip visual
										CreateEffect("Sphere", CF(oldPos), VT(5, 5, 5), VT(12, 12, 12), Color3.new(0.3, 0.9, 1), 0.4, nil, 1)
										CreateEffect("Sphere", playerData.RootPart.CFrame, VT(5, 5, 5), VT(12, 12, 12), Color3.new(0.3, 0.9, 1), 0.4, nil, 1)
									end

									-- Time rewind visual
									if i % 8 == 0 then
										local rewindEffect = CreatePart(VT(6, 6, 6), playerData.RootPart.CFrame, Color3.new(0.3, 1, 1), Enum.Material.Neon, 0.4, true)
										rewindEffect.Shape = Enum.PartType.Ball
										TweenService:Create(rewindEffect, TweenInfo.new(0.6), {
											Size = VT(1, 12, 1),
											Transparency = 1
										}):Play()
										Debris:AddItem(rewindEffect, 0.6)
									end
								end
							end
						end
					end
					task.wait(0.1)
				end
			end)()

			Debris:AddItem(field, 15)
			Debris:AddItem(timeCrystal, 15)
		end

		task.wait(5)

		-- PHASE 3: TEMPORAL COLLAPSE - Time paradox causes all fields to implode
		DisplayTaunt("TIME COLLAPSES!", 2, Color3.fromRGB(0, 255, 255))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.5, false, "Dimensional rift/portal sound")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 3, 0.3, false, "Time distortion/slow effect sound")

		for _, fieldData in ipairs(distortionFields) do
			if fieldData.Field and fieldData.Field.Parent then
				local fieldPos = fieldData.Field.Position

				-- Temporal implosion
				for implode = 1, 8 do
					CreateEffect("Sphere", CF(fieldPos), VT(50 - implode*5, 50 - implode*5, 50 - implode*5), VT(10, 10, 10), Color3.new(0.2 + implode*0.06, 0.8 + implode*0.02, 0.9), 0.5, nil, 2)
					task.wait(0.05)
				end

				-- Time explosion
				CreateEffect("Sphere", CF(fieldPos), VT(15, 15, 15), VT(60, 60, 60), Color3.new(0.3, 0.9, 1), 1.5, nil, 4)

				-- Temporal shockwaves (flat on ground)
				for shockwave = 1, 5 do
					CreateEffect("Ring", CF(fieldPos), VT(20, 1, 20), VT(60 + shockwave*15, 1, 60 + shockwave*15), Color3.new(0.3, 1, 1), 1.2, nil, 3)
				end

				ApplyAoE(fieldPos, 35, 250, 90)

				-- Time fragments
				for fragment = 1, 15 do
					local timeFragment = CreatePart(VT(3, 6, 0.5), CF(fieldPos), Color3.new(0.3 + math.random()/3, 0.9, 1), Enum.Material.Neon, 0.2, false)

					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = VT(1e9, 1e9, 1e9)
					bv.Velocity = VT(MRANDOM(-50, 50), MRANDOM(-30, 30), MRANDOM(-50, 50))
					bv.Parent = timeFragment

					TweenService:Create(timeFragment, TweenInfo.new(2), {Transparency = 1}):Play()
					Debris:AddItem(timeFragment, 2)
				end
			end
		end

		task.wait(1)

		-- Restore environment
		TweenService:Create(Lighting, TweenInfo.new(2.5), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(2.5), {Gravity = origGravity}):Play()

		task.wait(2)
		Attack = false
		AttackCooldowns.TemporalDistortion = tick()
	end

	-- Attack 18: APOCALYPTIC VOLCANIC ERUPTION
	local function VolcanicEruption()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor

		DisplayTaunt("THE EARTH ITSELF ERUPTS!", 3, Color3.fromRGB(255, 80, 0))

		-- PHASE 1: VOLCANIC AWAKENING - Ground cracks and magma chambers form
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Brightness = 1.8,
			Ambient = Color3.fromRGB(200, 60, 20),
			ColorShift_Top = Color3.fromRGB(255, 120, 40),
			FogEnd = 220,
			FogColor = Color3.fromRGB(180, 50, 10)
		}):Play()
		CreatePositionalSound("explosion_impact", ROOTPART.Position, 2, 0.4, false, "Deep explosion/impact sound")

		-- Create massive volcanic vents with underground magma chambers
		local vents = {}
		for v = 1, 12 do
			local ventPos = ROOTPART.Position + VT(MRANDOM(-70, 70), 0, MRANDOM(-70, 70))

			-- Ground crack effect with multiple layers
			local crack = CreatePart(VT(10, 2, 35), CF(ventPos) * ANGLES(0, RAD(MRANDOM(0, 360)), 0), Color3.new(0.3, 0.15, 0.1), Enum.Material.Neon, 0.2, true)

			-- Inner glow (magma visible through crack)
			local glow = CreatePart(VT(8, 3, 30), crack.CFrame, Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.1, true)

			-- Magma chamber underground
			local chamber = CreatePart(VT(15, 8, 15), CF(ventPos + VT(0, -4, 0)), Color3.new(1, 0.2, 0), Enum.Material.Neon, 0.3, true)
			chamber.Shape = Enum.PartType.Ball

			-- Chamber light
			local chamberLight = Instance.new("PointLight")
			chamberLight.Brightness = 15
			chamberLight.Color = Color3.new(1, 0.4, 0)
			chamberLight.Range = 40
			chamberLight.Parent = chamber

			-- Pulsing magma chamber
			coroutine.wrap(function()
				for pulse = 1, 40 do
					if chamber.Parent then
						chamber.Size = VT(15, 8, 15) + VT(math.sin(pulse * 0.5) * 4, math.sin(pulse * 0.5) * 2, math.sin(pulse * 0.5) * 4)

						-- Magma bubbles rising
						if pulse % 3 == 0 then
							local bubble = CreatePart(VT(3, 3, 3), chamber.CFrame, Color3.new(1, 0.4 + math.random()/5, 0), Enum.Material.Neon, 0.3, true)
							bubble.Shape = Enum.PartType.Ball
							TweenService:Create(bubble, TweenInfo.new(1.2), {
								CFrame = bubble.CFrame + VT(0, 10, 0),
								Size = VT(5, 5, 5),
								Transparency = 1
							}):Play()
							Debris:AddItem(bubble, 1.2)
						end
						task.wait(0.1)
					end
				end
			end)()

			table.insert(vents, {Position = ventPos, Crack = crack, Glow = glow, Chamber = chamber})

			Debris:AddItem(crack, 15)
			Debris:AddItem(glow, 15)
			Debris:AddItem(chamber, 15)
		end

		task.wait(2)

		-- PHASE 2: CATACLYSMIC ERUPTION - All vents explode with lava and pyroclastic fury
		DisplayTaunt("VOLCANIC FURY!", 2, Color3.fromRGB(255, 100, 0))
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 4, 0.2, false, "Massive explosion sound")
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.4, false, "Fire/flame whoosh sound")

		for _, vent in ipairs(vents) do
			coroutine.wrap(function()
				-- Initial eruption burst
				CreateEffect("Sphere", CF(vent.Position), VT(15, 15, 15), VT(40, 80, 40), Color3.new(1, 0.4, 0), 1, nil, 3)
				ApplyAoE(vent.Position, 25, 150, 70)

				-- Shoot enhanced lava bombs upward
				for bomb = 1, MRANDOM(10, 15) do
					local lavaBomb = CreatePart(VT(6, 6, 6), CF(vent.Position + VT(0, 3, 0)), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0, false)
					lavaBomb.Shape = Enum.PartType.Ball

					-- Molten core
					local core = CreatePart(VT(3, 3, 3), lavaBomb.CFrame, Color3.new(1, 0.8, 0.2), Enum.Material.Neon, 0, false)
					core.Shape = Enum.PartType.Ball

					coroutine.wrap(function()
						while lavaBomb.Parent do
							core.CFrame = lavaBomb.CFrame
							task.wait()
						end
					end)()

					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = VT(1e9, 1e9, 1e9)
					bv.Velocity = VT(MRANDOM(-50, 50), MRANDOM(90, 140), MRANDOM(-50, 50))
					bv.Parent = lavaBomb

					-- Enhanced light
					local light = Instance.new("PointLight")
					light.Brightness = 15
					light.Color = Color3.new(1, 0.5, 0)
					light.Range = 40
					light.Parent = lavaBomb

					-- Trail effect
					coroutine.wrap(function()
						while lavaBomb.Parent do
							local trail = CreatePart(VT(4, 4, 4), lavaBomb.CFrame, Color3.new(1, 0.4 + math.random()/5, 0), Enum.Material.Neon, 0.4, true)
							trail.Shape = Enum.PartType.Ball
							TweenService:Create(trail, TweenInfo.new(1), {
								Size = VT(2, 2, 2),
								Transparency = 1
							}):Play()
							Debris:AddItem(trail, 1)
							task.wait(0.08)
						end
					end)()

					local hitDebounce = false
					local lastY = lavaBomb.Position.Y

					-- Enhanced ground detection for lava bombs
					coroutine.wrap(function()
						while lavaBomb.Parent do
							local currentY = lavaBomb.Position.Y
							local groundRay = workspace:Raycast(lavaBomb.Position, VT(0, -lavaBomb.Size.Y, 0))
							if groundRay or (lastY - currentY < 0.1 and currentY < ROOTPART.Position.Y + 10) then
								if not hitDebounce and groundRay and isValidMeteorCollision(groundRay.Instance) then
									hitDebounce = true
									local impactPos = groundRay and groundRay.Position or lavaBomb.Position

									-- Enhanced explosion with multiple sounds and lava splash
									CreatePositionalSound("explosion_impact", impactPos, 2, MRANDOM(7, 12)/10, false, "Lava bomb impact")
									CreatePositionalSound("fire_whoosh", impactPos, 1.5, MRANDOM(6, 10)/10, false, "Lava splash")
									CreateEffect("Sphere", CF(impactPos), VT(10, 10, 10), VT(40, 40, 40), Color3.new(1, 0.3, 0), 1, nil, 2.5)

									-- Ground impact ring
									CreateEffect("Ring", CF(impactPos), VT(15, 1, 15), VT(50, 1, 50), Color3.new(1, 0.4, 0), 0.8, nil, 2)

									ApplyAoE(impactPos, 18, 100, 50)

									-- Enhanced lava splash particles with glow
									for splash = 1, 12 do
										local splashPart = CreatePart(VT(3, 3, 3), CF(impactPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, false)
										splashPart.Shape = Enum.PartType.Ball

										local splashLight = Instance.new("PointLight")
										splashLight.Brightness = 8
										splashLight.Color = Color3.new(1, 0.5, 0)
										splashLight.Range = 20
										splashLight.Parent = splashPart

										local splashVel = Instance.new("BodyVelocity")
										splashVel.MaxForce = VT(1e9, 1e9, 1e9)
										splashVel.Velocity = VT(MRANDOM(-40, 40), MRANDOM(20, 40), MRANDOM(-40, 40))
										splashVel.Parent = splashPart

										TweenService:Create(splashPart, TweenInfo.new(1.5), {
											Size = VT(1, 1, 1),
											Transparency = 1
										}):Play()
										TweenService:Create(splashLight, TweenInfo.new(1.5), {Brightness = 0}):Play()
										Debris:AddItem(splashPart, 1.5)
									end

									lavaBomb:Destroy()
									core:Destroy()
								end
							end
							lastY = currentY
							task.wait(0.05)
						end
					end)()

					lavaBomb.Touched:Connect(function(hit)
						if not hitDebounce and hit.Parent ~= CHARACTER and hit.Parent ~= Effects and hit.Name ~= "Base" then
							hitDebounce = true
							local impactPos = lavaBomb.Position
							local groundRay = workspace:Raycast(impactPos, VT(0, -50, 0))
							if groundRay then
								impactPos = groundRay.Position
							end

							CreatePositionalSound("explosion_impact", impactPos, 2, MRANDOM(7, 12)/10, false, "Lava bomb impact")
							CreateEffect("Sphere", CF(impactPos), VT(10, 10, 10), VT(40, 40, 40), Color3.new(1, 0.3, 0), 1, nil, 2.5)
							ApplyAoE(impactPos, 18, 100, 50)
							lavaBomb:Destroy()
							core:Destroy()
						end
					end)

					Debris:AddItem(lavaBomb, 10)
					Debris:AddItem(core, 10)
					task.wait(0.04)
				end

				-- Enhanced pyroclastic flow
				for flow = 1, 20 do
					local flowDir = VT(MRANDOM(-35, 35), 1, MRANDOM(-35, 35))
					local flowPart = CreatePart(VT(12, 8, 12), CF(vent.Position) * CF(flowDir), Color3.new(0.9, 0.2 + math.random()/3, 0), Enum.Material.Neon, 0.3, true)
					flowPart.Shape = Enum.PartType.Ball

					-- Pyroclastic flow light
					local flowLight = Instance.new("PointLight")
					flowLight.Brightness = 10
					flowLight.Color = Color3.new(1, 0.4, 0)
					flowLight.Range = 30
					flowLight.Parent = flowPart

					ApplyAoE(flowPart.Position, 10, 35, 18)

					-- Ash and ember particles
					for particle = 1, 5 do
						local ember = CreatePart(VT(1.5, 1.5, 1.5), flowPart.CFrame * CF(MRANDOM(-6, 6), MRANDOM(-4, 4), MRANDOM(-6, 6)), Color3.new(1, 0.5 + math.random()/3, 0), Enum.Material.Neon, 0.4, true)
						ember.Shape = Enum.PartType.Ball
						TweenService:Create(ember, TweenInfo.new(2.5), {
							CFrame = ember.CFrame + VT(MRANDOM(-15, 15), MRANDOM(8, 15), MRANDOM(-15, 15)),
							Size = VT(0.5, 0.5, 0.5),
							Transparency = 1
						}):Play()
						Debris:AddItem(ember, 2.5)
					end

					TweenService:Create(flowPart, TweenInfo.new(3.5), {
						Size = VT(18, 10, 18),
						Transparency = 1
					}):Play()

					Debris:AddItem(flowPart, 3.5)
					task.wait(0.08)
				end

				-- Enhanced lingering lava pool with filled ring mesh
				local lavaPool = CreatePart(VT(20, 4, 20), CF(vent.Position + VT(0, -1, 0)), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
				lavaPool.Shape = Enum.PartType.Ball

				-- Add filled ring mesh for better visual
				local lavaMesh = Instance.new("SpecialMesh")
				lavaMesh.MeshType = Enum.MeshType.FileMesh
				lavaMesh.MeshId = "rbxassetid://166062098" -- Filled ring mesh
				lavaMesh.Scale = VT(1, 0.1, 1)
				lavaMesh.Parent = lavaPool

				-- Lava pool light
				local poolLight = Instance.new("PointLight")
				poolLight.Brightness = 20
				poolLight.Color = Color3.new(1, 0.4, 0)
				poolLight.Range = 50
				poolLight.Parent = lavaPool

				-- Enhanced damage over time from lava pool with better visuals
				coroutine.wrap(function()
					for i = 1, 30 do
						ApplyAoE(vent.Position, 15, 25, 10)

						-- Enhanced lava bubbles with glow
						if i % 2 == 0 then
							for bubble = 1, 2 do
								local lavaBubble = CreatePart(VT(4, 4, 4), lavaPool.CFrame * CF(MRANDOM(-8, 8), 2, MRANDOM(-8, 8)), Color3.new(1, 0.4, 0), Enum.Material.Neon, 0.2, true)
								lavaBubble.Shape = Enum.PartType.Ball
								local bubbleLight = Instance.new("PointLight")
								bubbleLight.Brightness = 10
								bubbleLight.Color = Color3.new(1, 0.5, 0)
								bubbleLight.Range = 15
								bubbleLight.Parent = lavaBubble
								TweenService:Create(lavaBubble, TweenInfo.new(1.2), {
									CFrame = lavaBubble.CFrame + VT(0, 8, 0),
									Size = VT(2, 2, 2),
									Transparency = 1
								}):Play()
								TweenService:Create(bubbleLight, TweenInfo.new(1.2), {Brightness = 0}):Play()
								Debris:AddItem(lavaBubble, 1.2)
							end
						end

						-- Pulsing glow effect
						poolLight.Brightness = 20 + math.sin(i * 0.5) * 5
						task.wait(0.5)
					end
				end)()

				TweenService:Create(lavaPool, TweenInfo.new(15), {Transparency = 1}):Play()
				TweenService:Create(poolLight, TweenInfo.new(15), {Brightness = 0}):Play()
				Debris:AddItem(lavaPool, 15)
			end)()
		end

		task.wait(2)

		-- Restore lighting
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()

		task.wait(2)
		Attack = false
		AttackCooldowns.VolcanicEruption = tick()
	end

	-- Attack 19: ANTIMATTER VORTEX ANNIHILATION - Completely redesigned unique attack
	local function AntimatterAnnihilation()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor
		local origGravity = workspace.Gravity

		-- PHASE 1: ANTIMATTER VORTEX FORMATION - Massive spinning void vortex
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.5, false, "Dimensional rift sound")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2, 0.4, false, "Time distortion")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.2,
			Ambient = Color3.fromRGB(20, 0, 40),
			ColorShift_Top = Color3.fromRGB(100, 0, 150),
			FogEnd = 200,
			FogColor = Color3.fromRGB(10, 0, 30)
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(2), {Gravity = 120}):Play()

		-- Create massive antimatter vortex core
		local vortexCore = CreatePart(VT(50, 50, 50), ROOTPART.CFrame * CF(0, 40, 0), Color3.new(0.1, 0, 0.3), Enum.Material.ForceField, 0.3, true)
		vortexCore.Shape = Enum.PartType.Ball

		local coreLight = Instance.new("PointLight")
		coreLight.Brightness = 60
		coreLight.Color = Color3.new(0.3, 0, 0.6)
		coreLight.Range = 250
		coreLight.Parent = vortexCore

		-- Spinning antimatter rings
		local vortexRings = {}
		for r = 1, 10 do
			local ring = CreatePart(VT(70 + r*15, 4, 70 + r*15), vortexCore.CFrame, Color3.new(0.2 - r*0.01, 0, 0.4 - r*0.02), Enum.Material.Neon, 0.5, true)
			local ringMesh = Instance.new("SpecialMesh")
			ringMesh.MeshType = Enum.MeshType.FileMesh
			ringMesh.MeshId = "rbxassetid://3270017"
			ringMesh.Scale = VT(70 + r*15, 70 + r*15, 4)
			ringMesh.Parent = ring
			table.insert(vortexRings, {Part = ring, Mesh = ringMesh, Index = r})
		end

		task.wait(2)

		-- PHASE 2: ANTIMATTER VORTEX EXPANSION - Pulls matter in and annihilates
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.4, false, "Cosmic ambient")

		-- Grow vortex
		TweenService:Create(vortexCore, TweenInfo.new(3), {Size = VT(120, 120, 120)}):Play()

		-- Spin and annihilation effect
		coroutine.wrap(function()
			local rotation = 0
			for i = 1, 200 do
				if vortexCore.Parent then
					rotation = rotation + 4
					vortexCore.CFrame = ROOTPART.CFrame * CF(0, 40, 0) * ANGLES(0, RAD(rotation), 0)

					-- Rotate rings
					for _, ringData in ipairs(vortexRings) do
						if ringData.Part.Parent then
							local ringRotation = rotation * (0.3 + ringData.Index * 0.15)
							ringData.Part.CFrame = vortexCore.CFrame * ANGLES(RAD(ringRotation), RAD(ringRotation * 0.8), RAD(ringRotation * 0.6))
						end
					end

					-- Pull players and matter toward vortex
					if i % 3 == 0 then
						for _, playerData in pairs(cachedPlayers) do
							if playerData.RootPart and playerData.Model then
								local dist = (playerData.RootPart.Position - vortexCore.Position).Magnitude
								if dist <= 100 then
									local pullForce = Instance.new("BodyVelocity")
									pullForce.MaxForce = VT(1e9, 1e9, 1e9)
									pullForce.Velocity = (vortexCore.Position - playerData.RootPart.Position).Unit * 50
									pullForce.Parent = playerData.RootPart
									Debris:AddItem(pullForce, 0.2)
									ApplyDamage(playerData.Humanoid, 40, targetPlayer)
								end
							end
						end
					end

					-- Antimatter particles being annihilated
					if i % 2 == 0 then
						local particleAngle = (i / 200) * math.pi * 2
						local particleDist = 50 + math.sin(i * 0.1) * 30
						local particlePos = vortexCore.Position + VT(math.cos(particleAngle) * particleDist, math.sin(i * 0.2) * 15, math.sin(particleAngle) * particleDist)
						local particle = CreatePart(VT(5, 5, 5), CF(particlePos), Color3.new(0.5, 0, 0.8), Enum.Material.Neon, 0.3, true)
						particle.Shape = Enum.PartType.Ball
						TweenService:Create(particle, TweenInfo.new(1.5), {
							CFrame = vortexCore.CFrame,
							Size = VT(1, 1, 1),
							Transparency = 1
						}):Play()
						Debris:AddItem(particle, 1.5)

						-- Annihilation flash
						if i % 10 == 0 then
							CreateEffect("Sphere", CF(vortexCore.Position + VT(MRANDOM(-30, 30), MRANDOM(-30, 30), MRANDOM(-30, 30))), VT(8, 8, 8), VT(25, 25, 25), Color3.new(0.6, 0, 1), 0.5, nil, 2)
						end
					end

					task.wait()
				end
			end
		end)()

		task.wait(3)

		-- PHASE 3: TOTAL ANNIHILATION - Massive explosion cascade
		CreatePositionalSound("massive_explosion", vortexCore.Position, 5, 0.3, false, "Massive explosion")
		CreatePositionalSound("intro_explosion", vortexCore.Position, 5, 0.4, false, "Massive explosion")

		-- Expanding annihilation waves
		for wave = 1, 15 do
			local waveRing = CreatePart(VT(1, 1, 1), vortexCore.CFrame, Color3.new(0.3, 0, 0.6), Enum.Material.Neon, 0.2, true)
			local waveMesh = Instance.new("SpecialMesh")
			waveMesh.MeshType = Enum.MeshType.FileMesh
			waveMesh.MeshId = "rbxassetid://3270017"
			waveMesh.Scale = VT(120, 120, 5)
			waveMesh.Parent = waveRing

			TweenService:Create(waveMesh, TweenInfo.new(2.5), {
				Scale = VT(400 + wave*40, 400 + wave*40, 5)
			}):Play()
			TweenService:Create(waveRing, TweenInfo.new(2.5), {
				Transparency = 1
			}):Play()

			-- Damage wave
			coroutine.wrap(function()
				task.wait(0.6)
				ApplyAoE(vortexCore.Position, 120 + wave*20, 250, 120)
			end)()

			Debris:AddItem(waveRing, 2.5)
			task.wait(0.15)
		end

		-- PHASE 4: VOID ERASURE - Reality tears and void explosions
		for explosion = 1, 40 do
			local expAngle = (explosion / 40) * math.pi * 2
			local expDist = MRANDOM(20, 120)
			local expHeight = MRANDOM(-20, 40)
			local expPos = vortexCore.Position + VT(math.cos(expAngle) * expDist, expHeight, math.sin(expAngle) * expDist)

			-- Void explosion
			CreatePositionalSound("explosion_impact", expPos, 2, MRANDOM(7, 12)/10, false, "Void explosion")
			CreateEffect("Sphere", CF(expPos), VT(15, 15, 15), VT(60, 60, 60), Color3.new(0.2, 0, 0.5), 0.6, nil, 3)

			-- Void tears
			for tear = 1, 3 do
				local tearPos = expPos + VT(MRANDOM(-15, 15), MRANDOM(-15, 15), MRANDOM(-15, 15))
				local voidTear = CreatePart(VT(6, 15, 2), CF(tearPos) * ANGLES(RAD(MRANDOM(-45, 45)), RAD(MRANDOM(0, 360)), 0), Color3.new(0, 0, 0), Enum.Material.Neon, 0.2, true)
				TweenService:Create(voidTear, TweenInfo.new(2), {Transparency = 1}):Play()
				Debris:AddItem(voidTear, 2)
			end

			ApplyAoE(expPos, 35, 200, 90)
			task.wait(0.1)
		end

		-- Final massive annihilation
		task.wait(1)
		CreatePositionalSound("intro_explosion", vortexCore.Position, 6, 0.3, false, "Ultimate annihilation")

		-- Massive explosion
		CreateEffect("Sphere", vortexCore.CFrame, VT(60, 60, 60), VT(300, 300, 300), Color3.new(0.3, 0, 0.6), 2.5, nil, 7)
		for ring = 1, 10 do
			CreateEffect("Ring", vortexCore.CFrame * ANGLES(RAD(90), 0, 0), VT(100, 100, 5), VT(400 + ring*50, 400 + ring*50, 5), Color3.new(0.4, 0, 0.7), 2, nil, 5)
		end

		ApplyAoE(vortexCore.Position, 150, 400, 180)

		-- Cleanup
		for _, ringData in ipairs(vortexRings) do
			if ringData.Part.Parent then
				ringData.Part:Destroy()
			end
		end
		vortexCore:Destroy()

		task.wait(2)

		-- Restore environment
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(3), {Gravity = origGravity}):Play()

		task.wait(1.5)
		Attack = false
		AttackCooldowns.AntimatterAnnihilation = tick()
	end

	-- Attack 20: APOCALYPTIC TYPHOON CYCLONE
	local function TyphoonCyclone()
		if not canUseAttack() then return end
		Attack = true

		-- Store original lighting
		local origBrightness = Lighting.Brightness
		local origAmbient = Lighting.Ambient
		local origColorShift = Lighting.ColorShift_Top
		local origFogEnd = Lighting.FogEnd
		local origFogColor = Lighting.FogColor
		local origGravity = workspace.Gravity

		DisplayTaunt("WINDS OF DESTRUCTION!", 3, Color3.fromRGB(150, 200, 255))

		-- PHASE 1: STORM GENESIS - The sky darkens and the storm awakens
		TweenService:Create(Lighting, TweenInfo.new(1.5), {
			Brightness = 0.5,
			Ambient = Color3.fromRGB(60, 80, 100),
			ColorShift_Top = Color3.fromRGB(120, 150, 180),
			FogEnd = 180,
			FogColor = Color3.fromRGB(50, 70, 90)
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(1.5), {Gravity = 150}):Play()
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 2, 0.4, false, "Fire/flame whoosh sound")

		-- Create massive storm system at the center
		local stormCenter = CreatePart(VT(60, 60, 60), ROOTPART.CFrame * CF(0, 80, 0), Color3.new(0.3, 0.4, 0.6), Enum.Material.ForceField, 0.6, true)
		stormCenter.Shape = Enum.PartType.Ball

		-- Storm eye with lightning
		local stormEye = CreatePart(VT(30, 30, 30), stormCenter.CFrame, Color3.new(0.2, 0.3, 0.5), Enum.Material.Neon, 0.3, true)
		stormEye.Shape = Enum.PartType.Ball

		-- Storm light (LESS BRIGHT)
		local stormLight = Instance.new("PointLight")
		stormLight.Brightness = 12  -- Reduced from 25
		stormLight.Color = Color3.new(0.6, 0.7, 0.9)
		stormLight.Range = 100  -- Reduced from 150
		stormLight.Parent = stormCenter

		-- Rotating storm clouds
		coroutine.wrap(function()
			for i = 1, 150 do
				if stormCenter.Parent then
					stormCenter.CFrame = ROOTPART.CFrame * CF(0, 80, 0) * ANGLES(0, RAD(i * 2), 0)
					stormEye.CFrame = stormCenter.CFrame

					-- Lightning flashes (LESS FREQUENT)
					if i % 20 == 0 then  -- Changed from 10 to 20
						local lightning = CreatePart(VT(2, 80, 2), stormCenter.CFrame * CF(MRANDOM(-30, 30), -40, MRANDOM(-30, 30)), Color3.new(0.9, 0.9, 1), Enum.Material.Neon, 0.4, true)  -- More transparent
						lightning.Shape = Enum.PartType.Ball
						TweenService:Create(lightning, TweenInfo.new(0.3), {Transparency = 1}):Play()
						Debris:AddItem(lightning, 0.3)
					end
					task.wait()
				end
			end
		end)()

		Debris:AddItem(stormCenter, 20)
		Debris:AddItem(stormEye, 20)

		-- PHASE 2: CYCLONE FORMATION - Massive tornadoes spawn across the battlefield
		for c = 1, 6 do
			coroutine.wrap(function()
				local cyclonePos = ROOTPART.Position + VT(MRANDOM(-35, 35), 0, MRANDOM(-35, 35))
				local cyclone = CreatePart(VT(25, 140, 25), CF(cyclonePos), Color3.new(0.7, 0.8, 1), Enum.Material.ForceField, 0.3, true)

				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.FileMesh
				mesh.MeshId = "rbxassetid://1083825"
				mesh.Scale = VT(25, 140, 25)
				mesh.Parent = cyclone

				-- Cyclone core with lightning
				local cycloneCore = CreatePart(VT(15, 140, 15), cyclone.CFrame, Color3.new(0.8, 0.9, 1), Enum.Material.Neon, 0.5, true)
				local coreMesh = Instance.new("SpecialMesh")
				coreMesh.MeshType = Enum.MeshType.FileMesh
				coreMesh.MeshId = "rbxassetid://1083825"
				coreMesh.Scale = VT(15, 140, 15)
				coreMesh.Parent = cycloneCore

				-- Cyclone light (LESS BRIGHT)
				local cycloneLight = Instance.new("PointLight")
				cycloneLight.Brightness = 8  -- Reduced from 15
				cycloneLight.Color = Color3.new(0.6, 0.7, 0.9)
				cycloneLight.Range = 50  -- Reduced from 80
				cycloneLight.Parent = cyclone

				-- Reduced wind particles and debris (LESS FLASHY)
				coroutine.wrap(function()
					while cyclone.Parent do
						-- Wind particles (REDUCED COUNT)
						for p = 1, 2 do  -- Changed from 4 to 2
							local windPart = CreatePart(VT(3, 8, 3), cyclone.CFrame * CF(MRANDOM(-15, 15), MRANDOM(0, 130), MRANDOM(-15, 15)), Color3.new(0.7, 0.8, 0.9), Enum.Material.Neon, 0.6, true)  -- More transparent
							windPart.Shape = Enum.PartType.Ball
							TweenService:Create(windPart, TweenInfo.new(1), {
								Size = VT(6, 12, 6),  -- Smaller final size
								Transparency = 1
							}):Play()
							Debris:AddItem(windPart, 1)
						end

						-- Flying debris (LESS FREQUENT)
						if math.random(1, 5) == 1 then  -- Changed from 1/3 to 1/5 chance
							local debris = CreatePart(VT(2, 2, 2), cyclone.CFrame * CF(MRANDOM(-12, 12), MRANDOM(20, 100), MRANDOM(-12, 12)), Color3.new(0.5, 0.5, 0.6), Enum.Material.Slate, 0.3, false)

							local debrisVel = Instance.new("BodyVelocity")
							debrisVel.MaxForce = VT(1e9, 1e9, 1e9)
							debrisVel.Velocity = VT(MRANDOM(-40, 40), MRANDOM(10, 30), MRANDOM(-40, 40))
							debrisVel.Parent = debris

							Debris:AddItem(debris, 3)
						end

						task.wait(0.15)  -- Slightly longer wait
					end
				end)()

				-- Enhanced movement with more erratic pattern
				local angle = c * 60
				for i = 1, 300 do
					angle = angle + 4
					-- More chaotic spiral pattern
					local radius = 40 + math.sin(i * 0.08) * 15 + math.cos(i * 0.12) * 10
					local height = math.sin(i * 0.05) * 5
					cyclone.CFrame = ROOTPART.CFrame * CF(math.sin(RAD(angle)) * radius, height, math.cos(RAD(angle)) * radius) * ANGLES(RAD(10), RAD(i * 10), RAD(15))
					cycloneCore.CFrame = cyclone.CFrame

					-- Enhanced pull and damage - OPTIMIZED
					for _, playerData in pairs(cachedPlayers) do
						if playerData.RootPart and playerData.Model and not playerData.Model:FindFirstChild("Classification") then
							local dist = (playerData.RootPart.Position - cyclone.Position).Magnitude
							if dist <= 30 then
								-- Stronger pull with upward spiral
								local toCenter = (cyclone.Position - playerData.RootPart.Position).Unit
								local pullForce = Instance.new("BodyVelocity")
								pullForce.MaxForce = VT(1e9, 1e9, 1e9)
								pullForce.Velocity = toCenter * (60 - dist) + VT(0, 40, 0)
								pullForce.Parent = playerData.RootPart
								Debris:AddItem(pullForce, 0.15)

								ApplyDamage(playerData.Humanoid, 30, targetPlayer)

								-- Wind visual around player (LESS FREQUENT)
								if i % 10 == 0 then  -- Changed from 5 to 10
									local windRing = CreatePart(VT(5, 5, 5), playerData.RootPart.CFrame, Color3.new(0.7, 0.8, 0.9), Enum.Material.Neon, 0.7, true)  -- More transparent
									windRing.Shape = Enum.PartType.Ball
									TweenService:Create(windRing, TweenInfo.new(0.5), {
										Size = VT(10, 10, 10),  -- Smaller final size
										Transparency = 1
									}):Play()
									Debris:AddItem(windRing, 0.5)
								end
							end
						end
					end

					-- Lightning strikes from cyclone (LESS FREQUENT)
					if i % 40 == 0 then  -- Changed from 25 to 40
						local strikePos = cyclone.Position + VT(MRANDOM(-15, 15), 0, MRANDOM(-15, 15))
						local lightningBolt = CreatePart(VT(3, 140, 3), CF(strikePos + VT(0, 70, 0)), Color3.new(0.9, 0.9, 1), Enum.Material.Neon, 0.4, true)  -- More transparent
						lightningBolt.Shape = Enum.PartType.Ball

						CreateEffect("Sphere", CF(strikePos), VT(6, 6, 6), VT(15, 15, 15), Color3.new(0.9, 0.9, 1), 0.4, 821439273, 1.2)  -- Smaller, less bright
						ApplyAoE(strikePos, 15, 80, 40)

						TweenService:Create(lightningBolt, TweenInfo.new(0.2), {Transparency = 1}):Play()
						Debris:AddItem(lightningBolt, 0.2)
					end

					task.wait(0.015)
				end

				-- PHASE 3: STORM COLLAPSE - All cyclones detonate in sequence
				DisplayTaunt("CYCLONE DETONATION!", 1.5, Color3.fromRGB(200, 220, 255))
				CreateSound("intro_explosion", cyclone, 4, 0.4, false, "Massive explosion sound")

				-- Multi-stage explosion
				for explosion = 1, 10 do
					CreateEffect("Sphere", cyclone.CFrame * CF(0, (explosion - 5) * 15, 0), VT(20 + explosion*5, 20 + explosion*5, 20 + explosion*5), VT(40 + explosion*8, 40 + explosion*8, 40 + explosion*8), Color3.new(0.7, 0.8, 1), 0.8, nil, 3)
					task.wait(0.05)
				end

				ApplyAoE(cyclone.Position, 50, 280, 130)

				-- Shockwave rings
				for ring = 1, 6 do
					CreateEffect("Ring", cyclone.CFrame * ANGLES(RAD(90), RAD(ring * 60), 0), VT(25, 25, 1), VT(70 + ring*20, 70 + ring*20, 1), Color3.new(0.8, 0.9, 1), 1.5, nil, 2.5)
				end

				cyclone:Destroy()
				cycloneCore:Destroy()
			end)()
		end

		task.wait(3)

		-- Restore environment
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = origBrightness,
			Ambient = origAmbient,
			ColorShift_Top = origColorShift,
			FogEnd = origFogEnd,
			FogColor = origFogColor
		}):Play()
		TweenService:Create(workspace, TweenInfo.new(3), {Gravity = origGravity}):Play()

		task.wait(3)
		Attack = false
		AttackCooldowns.TyphoonCyclone = tick()
	end

	-- ===== NPC AND MINION ABILITY FUNCTIONS FOR FINALE =====

	-- Create rope between two characters
	local function CreateRope(from, to)
		local attachment0 = Instance.new("Attachment")
		attachment0.Position = VT(0, 1, 0)
		attachment0.Parent = from

		local attachment1 = Instance.new("Attachment")
		attachment1.Position = VT(0, 1, 0)
		attachment1.Parent = to

		local rope = Instance.new("Beam")
		rope.Attachment0 = attachment0
		rope.Attachment1 = attachment1
		rope.Color = ColorSequence.new(ROPE_COLOR)
		rope.FaceCamera = true
		rope.Width0 = 0.5
		rope.Width1 = 0.5
		rope.Texture = "rbxasset://textures/particles/smoke_main.dds"
		rope.TextureMode = Enum.TextureMode.Stretch
		rope.TextureSpeed = 1
		rope.Transparency = NumberSequence.new(0.3)
		rope.LightEmission = 0.8
		rope.Parent = from

		return {Beam = rope, Att0 = attachment0, Att1 = attachment1}
	end

	-- Display minion taunt above a minion's head
	local function DisplayMinionTaunt(minionCharacter)
		if not minionCharacter or not minionCharacter:FindFirstChild("Head") then return end

		local head = minionCharacter.Head
		local message = MinionTaunts[MRANDOM(1, #MinionTaunts)]

		-- Create billboard GUI for minion taunt
		local tauntBillboard = Instance.new("BillboardGui")
		tauntBillboard.Name = "MinionTauntBillboard"
		tauntBillboard.Adornee = head
		tauntBillboard.Size = UDim2.new(0, 350, 0, 70)
		tauntBillboard.StudsOffset = Vector3.new(0, 4, 0)  -- Above minion's head
		tauntBillboard.AlwaysOnTop = true
		tauntBillboard.MaxDistance = 150
		tauntBillboard.LightInfluence = 0
		tauntBillboard.Parent = minionCharacter

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.fromRGB(20, 0, 30)
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel = 0
		frame.Parent = tauntBillboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(150, 0, 255)
		stroke.Thickness = 2
		stroke.Transparency = 0.3
		stroke.Parent = frame

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, -10, 1, -10)
		text.Position = UDim2.new(0, 5, 0, 5)
		text.BackgroundTransparency = 1
		text.Text = message
		text.TextColor3 = Color3.fromRGB(200, 150, 255)
		text.TextSize = 18
		text.Font = Enum.Font.GothamBold
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		text.TextWrapped = true
		text.TextXAlignment = Enum.TextXAlignment.Center
		text.TextYAlignment = Enum.TextYAlignment.Center
		text.Parent = frame

		-- Auto remove after 3 seconds
		Debris:AddItem(tauntBillboard, 3)
	end

	-- Recruit a player as a minion
	local function recruitMinion(recruiter, targetPlayerToRecruit)
		if not MinionConfig.Active then return end
		if not targetPlayerToRecruit or not targetPlayerToRecruit.Character then return end
		if MinionConfig.Minions[targetPlayerToRecruit.UserId] then return end  -- Already a minion
		if targetPlayerToRecruit == recruiter then return end  -- Can't recruit self
		if targetPlayerToRecruit == targetPlayer then return end  -- Can't recruit boss (using outer targetPlayer variable)

		local targetChar = targetPlayerToRecruit.Character
		local targetHuman = targetChar:FindFirstChild("Humanoid")
		local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
		if not targetHuman or not targetRoot then return end

		-- Transfer HP to Nexus
		local hpGain = targetHuman.Health
		if HUMANOID then
			HUMANOID.Health = math.min(HUMANOID.Health + hpGain, HUMANOID.MaxHealth)
			DisplayTaunt("ABSORBED " .. math.floor(hpGain) .. " HP!", 2, Color3.fromRGB(0, 255, 0))
		end

		-- Create rope link
		local recruiterRoot = recruiter == targetPlayer and ROOTPART or (MinionConfig.Minions[recruiter.UserId] and MinionConfig.Minions[recruiter.UserId].RootPart)
		local ropeData = nil
		if recruiterRoot then
			ropeData = CreateRope(recruiterRoot, targetRoot)
		end

		-- Add to minions
		MinionConfig.Minions[targetPlayerToRecruit.UserId] = {
			Player = targetPlayerToRecruit,
			RootPart = targetRoot,
			Humanoid = targetHuman,
			Rope = ropeData,
			RecruitedBy = recruiter,
			RecruitedMinions = {}
		}

		-- Track recruitment chain
		if recruiter ~= targetPlayer then
			if MinionConfig.Minions[recruiter.UserId] then
				table.insert(MinionConfig.Minions[recruiter.UserId].RecruitedMinions, targetPlayerToRecruit.UserId)
			end
		end

		-- Visual effect
		for i = 1, 20 do
			local particle = CreatePart(VT(1, 1, 1), targetRoot.CFrame * CF(MRANDOM(-3, 3), MRANDOM(-3, 3), MRANDOM(-3, 3)), ROPE_COLOR, Enum.Material.Neon, 0.3, true)
			particle.Shape = Enum.PartType.Ball
			TweenService:Create(particle, TweenInfo.new(1), {
				CFrame = targetRoot.CFrame,
				Transparency = 1
			}):Play()
			Debris:AddItem(particle, 1)
		end

		CreateSound("dimensional_rift", targetRoot, 1.5, 1.1, false, "Minion recruited")

		-- Display initial taunt when recruited
		task.wait(0.5)
		DisplayMinionTaunt(targetChar)

		-- Periodic taunt display for this minion
		local tauntCoroutine = coroutine.wrap(function()
			while MinionConfig.Minions[targetPlayerToRecruit.UserId] and targetChar.Parent do
				task.wait(MRANDOM(10, 20))  -- Random interval between 10-20 seconds
				if MinionConfig.Minions[targetPlayerToRecruit.UserId] and targetChar.Parent then
					DisplayMinionTaunt(targetChar)
				end
			end
		end)
		tauntCoroutine()

		-- Minion touch recruitment
		local touchConn = targetRoot.Touched:Connect(function(hit)
			local hitChar = hit.Parent
			if hitChar and hitChar:FindFirstChild("Humanoid") then
				local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
				if hitPlayer and hitPlayer ~= targetPlayerToRecruit and not MinionConfig.Minions[hitPlayer.UserId] then
					local currentTime = tick()
					if not MinionConfig.TouchDebounce[hitPlayer.UserId] or currentTime - MinionConfig.TouchDebounce[hitPlayer.UserId] > MINION_TOUCH_COOLDOWN then
						MinionConfig.TouchDebounce[hitPlayer.UserId] = currentTime
						recruitMinion(targetPlayerToRecruit, hitPlayer)
					end
				end
			end
		end)

		table.insert(MinionConfig.Connections, touchConn)
	end

	-- Start minion hire mode (Nexus boss touches to recruit)
	local function startMinionMode()
		if MinionConfig.Active then return "Minion mode already active" end

		MinionConfig.Active = true

		-- Nexus boss touch to recruit
		local bossTouch = ROOTPART.Touched:Connect(function(hit)
			local hitChar = hit.Parent
			if hitChar and hitChar:FindFirstChild("Humanoid") then
				local hitPlayer = Players:GetPlayerFromCharacter(hitChar)
				if hitPlayer and hitPlayer ~= targetPlayer and not MinionConfig.Minions[hitPlayer.UserId] then
					local currentTime = tick()
					if not MinionConfig.TouchDebounce[hitPlayer.UserId] or currentTime - MinionConfig.TouchDebounce[hitPlayer.UserId] > MINION_TOUCH_COOLDOWN then
						MinionConfig.TouchDebounce[hitPlayer.UserId] = currentTime
						recruitMinion(targetPlayer, hitPlayer)
					end
				end
			end
		end)

		table.insert(MinionConfig.Connections, bossTouch)

		return "Minion Hire Mode activated!"
	end

	-- Free a minion (only that minion, not chain death)
	local function freeMinion(userId)
		local minionData = MinionConfig.Minions[userId]
		if not minionData then return end

		-- Destroy rope
		if minionData.Rope then
			if minionData.Rope.Beam then minionData.Rope.Beam:Destroy() end
			if minionData.Rope.Att0 then minionData.Rope.Att0:Destroy() end
			if minionData.Rope.Att1 then minionData.Rope.Att1:Destroy() end
		end

		-- Free this minion's recruited minions (they become independent)
		for _, recruitedId in ipairs(minionData.RecruitedMinions) do
			if MinionConfig.Minions[recruitedId] then
				-- Update their recruiter to be the boss instead
				MinionConfig.Minions[recruitedId].RecruitedBy = targetPlayer
			end
		end

		-- Remove from parent's recruited list
		if minionData.RecruitedBy and minionData.RecruitedBy ~= targetPlayer then
			local parentData = MinionConfig.Minions[minionData.RecruitedBy.UserId]
			if parentData then
				for i, recId in ipairs(parentData.RecruitedMinions) do
					if recId == userId then
						table.remove(parentData.RecruitedMinions, i)
						break
					end
				end
			end
		end

		-- Remove from minions
		MinionConfig.Minions[userId] = nil

		-- Visual effect
		if minionData.RootPart and minionData.RootPart.Parent then
			for i = 1, 15 do
				local particle = CreatePart(VT(1, 1, 1), minionData.RootPart.CFrame * CF(MRANDOM(-3, 3), MRANDOM(-3, 3), MRANDOM(-3, 3)), Color3.fromRGB(100, 255, 100), Enum.Material.Neon, 0.3, true)
				particle.Shape = Enum.PartType.Ball
				TweenService:Create(particle, TweenInfo.new(1), {
					CFrame = particle.CFrame + VT(0, 5, 0),
					Transparency = 1
				}):Play()
				Debris:AddItem(particle, 1)
			end
		end
	end

	-- Stop minion mode
	local function stopMinionMode()
		if not MinionConfig.Active then return "Minion mode not active" end

		MinionConfig.Active = false

		-- Disconnect all connections
		for _, connection in ipairs(MinionConfig.Connections) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end

		-- Free all minions
		for userId, _ in pairs(MinionConfig.Minions) do
			freeMinion(userId)
		end

		-- Reset tables
		MinionConfig.Connections = {}
		MinionConfig.Minions = {}
		MinionConfig.TouchDebounce = {}

		return "Minion mode stopped"
	end

	-- Spawn an enemy NPC
	local function spawnNPC(npcType, position)
		if not NPCConfig.Active then return end

		local npcData = NPCTypes[npcType]
		if not npcData then return end

		-- Create NPC model
		local npcModel = Instance.new("Model")
		npcModel.Name = npcData.Name .. "_" .. NPCConfig.NextNPCId
		npcModel.Parent = workspace

		-- Create HumanoidRootPart (torso)
		local npcBody = CreatePart(VT(2, 2, 1), CF(position), npcData.Color, Enum.Material.Neon, 0, false)
		npcBody.Name = "HumanoidRootPart"
		npcBody.Parent = npcModel

		-- Add classification
		local classValue = Instance.new("StringValue")
		classValue.Name = "Classification"
		classValue.Value = "NexusNPC"
		classValue.Parent = npcModel

		-- Create head
		local npcHead = CreatePart(VT(2, 1, 1), 
			CF(position + VT(0, 1.5, 0)), npcData.Color, Enum.Material.Neon, 0, false)
		npcHead.Name = "Head"
		npcHead.Parent = npcModel

		-- Create proper body parts (R6 style)
		-- Torso (already created as npcBody)
		local torso = npcBody

		-- Left Arm (R6 - single part)
		local leftArm = CreatePart(VT(1, 2, 1), CF(position + VT(-1.5, 0, 0)), npcData.Color, Enum.Material.Neon, 0, false)
		leftArm.Name = "Left Arm"
		leftArm.Parent = npcModel

		-- Right Arm (R6 - single part)
		local rightArm = CreatePart(VT(1, 2, 1), CF(position + VT(1.5, 0, 0)), npcData.Color, Enum.Material.Neon, 0, false)
		rightArm.Name = "Right Arm"
		rightArm.Parent = npcModel

		-- Left Leg (R6 - single part)
		local leftLeg = CreatePart(VT(1, 2, 1), CF(position + VT(-0.5, -2, 0)), npcData.Color, Enum.Material.Neon, 0, false)
		leftLeg.Name = "Left Leg"
		leftLeg.Parent = npcModel

		-- Right Leg (R6 - single part)
		local rightLeg = CreatePart(VT(1, 2, 1), CF(position + VT(0.5, -2, 0)), npcData.Color, Enum.Material.Neon, 0, false)
		rightLeg.Name = "Right Leg"
		rightLeg.Parent = npcModel

		-- Weld all parts to torso
		local function weldToTorso(part, offset)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = part
			weld.Parent = torso
		end

		weldToTorso(npcHead, VT(0, 1.5, 0))
		weldToTorso(leftArm, VT(-1.5, 0, 0))
		weldToTorso(rightArm, VT(1.5, 0, 0))
		weldToTorso(leftLeg, VT(-0.5, -2, 0))
		weldToTorso(rightLeg, VT(0.5, -2, 0))

		-- Add glowing eyes
		local leftEye = CreatePart(VT(0.3, 0.3, 0.3), npcHead.CFrame * CF(-0.3, 0.1, -0.5), 
			Color3.new(1, 0, 0), Enum.Material.Neon, 0, false)
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Parent = npcModel
		local eyeWeld1 = Instance.new("WeldConstraint")
		eyeWeld1.Part0 = npcHead
		eyeWeld1.Part1 = leftEye
		eyeWeld1.Parent = npcHead

		local rightEye = CreatePart(VT(0.3, 0.3, 0.3), npcHead.CFrame * CF(0.3, 0.1, -0.5), 
			Color3.new(1, 0, 0), Enum.Material.Neon, 0, false)
		rightEye.Shape = Enum.PartType.Ball
		rightEye.Parent = npcModel
		local eyeWeld2 = Instance.new("WeldConstraint")
		eyeWeld2.Part0 = npcHead
		eyeWeld2.Part1 = rightEye
		eyeWeld2.Parent = npcHead

		-- Add dark aura
		local aura = CreatePart(npcData.Size * 1.5, npcBody.CFrame, npcData.Color, Enum.Material.Neon, 0.7, true)
		aura.Shape = Enum.PartType.Ball
		aura.Parent = npcModel

		-- Aura pulsing animation
		coroutine.wrap(function()
			local size1 = npcData.Size * 1.5
			local size2 = npcData.Size * 1.8
			while aura.Parent and npcBody.Parent do
				TweenService:Create(aura, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = size2}):Play()
				task.wait(1)
				if aura.Parent then
					TweenService:Create(aura, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = size1}):Play()
				end
				task.wait(1)
			end
		end)()

		coroutine.wrap(function()
			while aura.Parent and npcBody.Parent do
				aura.CFrame = npcBody.CFrame
				task.wait()
			end
		end)()

		-- Add point light
		local npcLight = Instance.new("PointLight")
		npcLight.Brightness = 15
		npcLight.Color = npcData.Color
		npcLight.Range = 30
		npcLight.Parent = npcBody

		-- Create humanoid
		local npcHumanoid = Instance.new("Humanoid")
		npcHumanoid.MaxHealth = npcData.Health
		npcHumanoid.Health = npcData.Health
		npcHumanoid.WalkSpeed = npcData.MoveSpeed
		npcHumanoid.Parent = npcModel

		-- Store NPC data
		local npcId = NPCConfig.NextNPCId
		NPCConfig.NextNPCId = NPCConfig.NextNPCId + 1

		-- Mark NPC as minion
		local minionValue = Instance.new("BoolValue")
		minionValue.Name = "IsNexusMinion"
		minionValue.Value = true
		minionValue.Parent = npcModel

		NPCConfig.NPCs[npcId] = {
			Model = npcModel,
			Humanoid = npcHumanoid,
			RootPart = npcBody,
			Target = nil,
			LastAttackTime = 0,
			Type = npcType,
			Data = npcData,
			PatrolTarget = position + VT(MRANDOM(-50, 50), 0, MRANDOM(-50, 50)), -- Initial patrol target
			IsPatrolling = false
		}

		-- NPC AI behavior
		coroutine.wrap(function()
			while npcHumanoid.Health > 0 and npcModel.Parent and NPCConfig.Active do
				local npc = NPCConfig.NPCs[npcId]
				if not npc then break end

				-- Find closest non-minion player
				local closestPlayer = nil
				local closestDist = math.huge

				for _, playerData in pairs(cachedPlayers) do
					if playerData.RootPart and playerData.Humanoid and playerData.Humanoid.Health > 0 then
						local player = Players:GetPlayerFromCharacter(playerData.Model)
						if player and not MinionConfig.Minions[player.UserId] and player ~= targetPlayer then
							local dist = (playerData.RootPart.Position - npcBody.Position).Magnitude
							if dist < closestDist then
								closestDist = dist
								closestPlayer = playerData
							end
						end
					end
				end

				if closestPlayer and closestPlayer.RootPart then
					npc.Target = closestPlayer
					npc.IsPatrolling = false

					-- Move toward target
					local direction = (closestPlayer.RootPart.Position - npcBody.Position).Unit
					npcBody.CFrame = npcBody.CFrame + direction * npcData.MoveSpeed * 0.05
					npcBody.CFrame = CF(npcBody.CFrame.Position, closestPlayer.RootPart.Position)

					-- Attack if in range
					if closestDist < npcData.AttackRange and tick() - npc.LastAttackTime > npcData.AttackCooldown then
						npc.LastAttackTime = tick()

						-- Fire projectile at target
						local projectile = CreatePart(VT(3, 3, 3), npcBody.CFrame, npcData.Color, Enum.Material.Neon, 0, false)
						projectile.Shape = Enum.PartType.Ball

						local projLight = Instance.new("PointLight")
						projLight.Brightness = 10
						projLight.Color = npcData.Color
						projLight.Range = 20
						projLight.Parent = projectile

						local dir = (closestPlayer.RootPart.Position - projectile.Position).Unit
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = dir * 120
						bv.Parent = projectile

						-- Add attack sound
						CreatePositionalSound("energy_beam", npcBody.Position, 1.5, MRANDOM(8, 12)/10, false, "NPC attack")

						local hitDebounce = false
						projectile.Touched:Connect(function(hit)
							if not hitDebounce and hit.Parent ~= npcModel and hit.Parent ~= CHARACTER then
								hitDebounce = true
								local hitHuman = hit.Parent:FindFirstChild("Humanoid")
								if hitHuman then
									local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
									if hitPlayer and not MinionConfig.Minions[hitPlayer.UserId] then
										ApplyDamage(hitHuman, npcData.Damage, targetPlayer)
										CreateEffect("Sphere", CF(projectile.Position), VT(3, 3, 3), VT(12, 12, 12), npcData.Color, 0.5, "explosion_impact", 1.5)
									end
								end
								projectile:Destroy()
							end
						end)

						Debris:AddItem(projectile, 3)
					end

					-- Heal nearby minions
					for userId, minionData in pairs(MinionConfig.Minions) do
						if minionData.RootPart and minionData.Humanoid then
							local dist = (minionData.RootPart.Position - npcBody.Position).Magnitude
							if dist < 25 and minionData.Humanoid.Health < minionData.Humanoid.MaxHealth then
								minionData.Humanoid.Health = math.min(minionData.Humanoid.Health + 5, minionData.Humanoid.MaxHealth)

								-- Healing visual
								if MRANDOM(1, 3) == 1 then
									local healParticle = CreatePart(VT(1, 1, 1), minionData.RootPart.CFrame, Color3.new(0, 1, 0), Enum.Material.Neon, 0.3, true)
									healParticle.Shape = Enum.PartType.Ball
									TweenService:Create(healParticle, TweenInfo.new(0.5), {
										CFrame = healParticle.CFrame + VT(0, 3, 0),
										Transparency = 1
									}):Play()
									Debris:AddItem(healParticle, 0.5)
								end
							end
						end
					end

					-- Touch recruitment assistance
					for _, playerData in pairs(cachedPlayers) do
						if playerData.RootPart and playerData.Humanoid then
							local player = Players:GetPlayerFromCharacter(playerData.Model)
							if player and not MinionConfig.Minions[player.UserId] and player ~= targetPlayer then
								local dist = (playerData.RootPart.Position - npcBody.Position).Magnitude
								if dist < 5 then
									recruitMinion(targetPlayer, player)
								end
							end
						end
					end
				else
					-- No players found - idle patrolling behavior
					npc.Target = nil

					-- Check if reached patrol target or need new one
					local distToPatrol = (npc.PatrolTarget - npcBody.Position).Magnitude
					if distToPatrol < 5 or not npc.IsPatrolling then
						-- Get new patrol target (wander around spawn area)
						local spawnRadius = 80
						npc.PatrolTarget = position + VT(MRANDOM(-spawnRadius, spawnRadius), 0, MRANDOM(-spawnRadius, spawnRadius))
						npc.IsPatrolling = true
					end

					-- Move toward patrol target
					local patrolDir = (npc.PatrolTarget - npcBody.Position).Unit
					npcBody.CFrame = npcBody.CFrame + patrolDir * npcData.MoveSpeed * 0.03 -- Slower patrol speed

					-- Occasionally change direction
					if MRANDOM(1, 20) == 1 then
						local spawnRadius = 80
						npc.PatrolTarget = position + VT(MRANDOM(-spawnRadius, spawnRadius), 0, MRANDOM(-spawnRadius, spawnRadius))
					end
				end

				task.wait(0.1)
			end

			-- Death effect
			if npcModel.Parent then
				CreateEffect("Sphere", npcBody.CFrame, npcData.Size, npcData.Size * 3, npcData.Color, 1, nil, 2)
				CreatePositionalSound("explosion_impact", npcBody.Position, 1.5, 1, false, "NPC death")
			end

			-- Cleanup
			NPCConfig.NPCs[npcId] = nil
			npcModel:Destroy()
		end)()

		-- Death listener
		npcHumanoid.Died:Connect(function()
			task.wait(0.5)
			if npcModel.Parent then
				npcModel:Destroy()
			end
		end)

		return npcId
	end

	-- Grant minion abilities based on current phase
	local function grantMinionAbility(minionUserId)
		local minionData = MinionConfig.Minions[minionUserId]
		if not minionData or not minionData.RootPart or not minionData.Humanoid then return end

		local phase = CurrentFinalePhase
		local rootPart = minionData.RootPart

		-- AUTOMATIC MINION ATTACK: Find nearby non-minion players and attack them
		local nearbyPlayers = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= minionData.Player and player ~= targetPlayer and not MinionConfig.Minions[player.UserId] then
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local dist = (player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
					if dist < 100 then  -- Detection range
						table.insert(nearbyPlayers, {Player = player, Distance = dist})
					end
				end
			end
		end

		-- Sort by distance to attack closest player
		table.sort(nearbyPlayers, function(a, b) return a.Distance < b.Distance end)
		if #nearbyPlayers > 0 then
			local targetPlayer_Auto = nearbyPlayers[1].Player
			if targetPlayer_Auto and targetPlayer_Auto.Character then
				local targetHumanoid = targetPlayer_Auto.Character:FindFirstChild("Humanoid")
				if targetHumanoid then
					-- Damage the player
					ApplyDamage(targetHumanoid, MRANDOM(15, 35), minionData.Player)
					-- Try to convert them to minion
					recruitMinion(minionData.Player, targetPlayer_Auto)
				end
			end
		end

		-- Phase 1-5: Lightning strikes
		if phase >= 1 and phase <= 5 then
			local targetPos = rootPart.Position + VT(MRANDOM(-30, 30), 0, MRANDOM(-30, 30))
			CreateLightningBolt(rootPart.Position + VT(0, 50, 0), targetPos, 10, Color3.new(1, 1, 0.8), 3, 0.3)
			CreateEffect("Sphere", CF(targetPos), VT(8, 8, 8), VT(20, 20, 20), Color3.new(1, 1, 0), 0.5, nil, 1.5)
			ApplyAoE(targetPos, 15, 80, 40)
			CreatePositionalSound("lightning_strike", rootPart.Position, 1, MRANDOM(8, 12)/10, false, "Minion lightning")

			-- Phase 6-10: Fire/Ice projectiles
		elseif phase >= 6 and phase <= 10 then
			CreatePositionalSound("fire_whoosh", rootPart.Position, 1.5, MRANDOM(8, 12)/10, false, "Minion fire/ice attack")
			for i = 1, 3 do
				local element = i % 2 == 0 and "fire" or "ice"
				local color = element == "fire" and Color3.new(1, 0.3, 0) or Color3.new(0, 0.8, 1)

				local projectile = CreatePart(VT(4, 4, 4), rootPart.CFrame, color, Enum.Material.Neon, 0, false)
				projectile.Shape = Enum.PartType.Ball

				local angle = RAD(i * 120)
				local dir = VT(math.cos(angle), 0.2, math.sin(angle))

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = dir * 100
				bv.Parent = projectile

				local hitDebounce = false
				projectile.Touched:Connect(function(hit)
					if not hitDebounce and hit.Parent ~= minionData.Player.Character then
						hitDebounce = true
						CreateEffect("Sphere", CF(projectile.Position), VT(4, 4, 4), VT(15, 15, 15), color, 0.5, nil, 1)
						ApplyAoE(projectile.Position, 12, 60, 30)
						CreatePositionalSound("explosion_impact", projectile.Position, 1, MRANDOM(8, 12)/10, false, "Projectile impact")
						projectile:Destroy()
					end
				end)

				Debris:AddItem(projectile, 3)
			end

			-- Phase 11-15: Void orbs and rifts
		elseif phase >= 11 and phase <= 15 then
			local riftPos = rootPart.Position + VT(MRANDOM(-20, 20), 10, MRANDOM(-20, 20))
			local rift = CreatePart(VT(10, 20, 3), CF(riftPos), Color3.new(0.1, 0, 0.5), Enum.Material.ForceField, 0.3, true)
			CreatePositionalSound("dimensional_rift", riftPos, 1.5, MRANDOM(8, 12)/10, false, "Minion void rift")

			for p = 1, 5 do
				task.wait(0.2)
				local voidOrb = CreatePart(VT(3, 3, 3), rift.CFrame, Color3.new(0.2, 0, 0.4), Enum.Material.Neon, 0, false)
				voidOrb.Shape = Enum.PartType.Ball

				local dir = (ROOTPART.Position + VT(MRANDOM(-40, 40), 0, MRANDOM(-40, 40)) - voidOrb.Position).Unit
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = dir * 70
				bv.Parent = voidOrb

				local hitDebounce = false
				voidOrb.Touched:Connect(function(hit)
					if not hitDebounce and isValidMeteorCollision(hit) then
						hitDebounce = true
						ApplyAoE(voidOrb.Position, 10, 70, 35)
						CreatePositionalSound("explosion_impact", voidOrb.Position, 1.2, MRANDOM(8, 12)/10, false, "Void orb impact")
						voidOrb:Destroy()
					end
				end)

				Debris:AddItem(voidOrb, 3)
			end

			Debris:AddItem(rift, 3)

			-- Phase 16-25: Meteor summons and plasma beams
		elseif phase >= 16 and phase <= 25 then
			CreatePositionalSound("cosmic_ambient", rootPart.Position, 1.5, MRANDOM(8, 12)/10, false, "Minion meteor summon")
			for m = 1, 2 do
				local meteorPos = rootPart.Position + VT(MRANDOM(-40, 40), 0, MRANDOM(-40, 40))
				local meteor = CreatePart(VT(8, 8, 8), CF(meteorPos + VT(0, 100, 0)), Color3.new(1, 0.4, 0), Enum.Material.Neon, 0, false)
				meteor.Shape = Enum.PartType.Ball

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = VT(0, -200, 0)
				bv.Parent = meteor

				local hitDebounce = false
				meteor.Touched:Connect(function(hit)
					if not hitDebounce and isValidMeteorCollision(hit) then
						hitDebounce = true
						CreateEffect("Sphere", CF(meteor.Position), VT(8, 8, 8), VT(30, 30, 30), Color3.new(1, 0.4, 0), 0.8, nil, 2)
						ApplyAoE(meteor.Position, 18, 100, 50)
						CreatePositionalSound("explosion_impact", meteor.Position, 2, MRANDOM(6, 10)/10, false, "Meteor impact")
						meteor:Destroy()
					end
				end)

				Debris:AddItem(meteor, 2)
			end

			-- Phase 26-30: Reality tears and explosive nova
		elseif phase >= 26 then
			-- Reality tear
			local tearPos = rootPart.Position + VT(MRANDOM(-25, 25), 20, MRANDOM(-25, 25))
			local tear = CreatePart(VT(15, 30, 4), CF(tearPos), Color3.new(0.1, 0, 0.6), Enum.Material.ForceField, 0.2, true)
			CreatePositionalSound("reality_tear", tearPos, 1.5, MRANDOM(8, 12)/10, false, "Minion reality tear")

			task.wait(0.5)

			-- Explosive nova from minion
			CreateEffect("Sphere", rootPart.CFrame, VT(5, 5, 5), VT(40, 40, 40), Color3.new(1, 0, 1), 1, nil, 2)
			ApplyAoE(rootPart.Position, 25, 120, 60)
			CreatePositionalSound("massive_explosion", rootPart.Position, 1.5, MRANDOM(8, 12)/10, false, "Minion nova explosion")

			Debris:AddItem(tear, 2)
		end

		-- Visual indicator - change aura color based on phase
		local auraColor
		if phase <= 5 then auraColor = Color3.new(1, 1, 0)
		elseif phase <= 10 then auraColor = Color3.new(1, 0.3, 0)
		elseif phase <= 15 then auraColor = Color3.new(0.2, 0, 0.5)
		elseif phase <= 25 then auraColor = Color3.new(0, 1, 1)
		else auraColor = Color3.new(1, 0, 1)
		end

		local auraEffect = CreatePart(VT(6, 6, 6), rootPart.CFrame, auraColor, Enum.Material.Neon, 0.5, true)
		auraEffect.Shape = Enum.PartType.Ball
		TweenService:Create(auraEffect, TweenInfo.new(0.8), {
			Size = VT(12, 12, 12),
			Transparency = 1
		}):Play()
		Debris:AddItem(auraEffect, 0.8)
	end

	-- Trigger minion abilities periodically
	coroutine.wrap(function()
		while not DEAD do
			task.wait(5)  -- Minions use abilities every 5 seconds
			if CurrentFinalePhase > 0 and MinionConfig.Active then
				for userId, minionData in pairs(MinionConfig.Minions) do
					if minionData.Humanoid and minionData.Humanoid.Health > 0 then
						coroutine.wrap(function()
							grantMinionAbility(userId)
						end)()
					end
				end
			end
		end
	end)()

	-- Clean up all NPCs
	local function cleanupNPCs()
		for npcId, npcData in pairs(NPCConfig.NPCs) do
			if npcData.Model then
				npcData.Model:Destroy()
			end
		end
		NPCConfig.NPCs = {}
		NPCConfig.Active = false
	end

	-- Attack 21: ULTIMATE NEXUS FINALE - 10 MINUTES OF TOTAL DEVASTATION (30 PHASES)
	local function NexusFinale()
		if not canUseAttack() then return end
		Attack = true

		-- Store ALL original environment values
		local originalBrightness = Lighting.Brightness
		local originalAmbient = Lighting.Ambient
		local originalColorShift = Lighting.ColorShift_Top
		local originalFogEnd = Lighting.FogEnd
		local originalFogColor = Lighting.FogColor
		local originalClockTime = Lighting.ClockTime
		local originalOutdoorAmbient = Lighting.OutdoorAmbient
		local originalGravity = workspace.Gravity

		-- ACTIVATE ALL SYSTEMS FOR FINALE
		startMinionMode()  -- Enable minion recruitment
		NPCConfig.Active = true  -- Enable NPC spawning
		CurrentFinalePhase = 0  -- Reset phase tracker

		-- ===== PHASE 1: THE AWAKENING OF CHAOS =====
		CurrentFinalePhase = 1
		DisplayTaunt("WITNESS THE ULTIMATE POWER OF THE NEXUS!", 6, Color3.fromRGB(255, 0, 255))
		CreatePositionalSound("intro_buildup", ROOTPART.Position, 3, 0.4, false, "Epic orchestral buildup")

		-- Dramatic sky changes - Turn to midnight
		TweenService:Create(Lighting, TweenInfo.new(4), {
			ClockTime = 0,
			Brightness = 0,
			Ambient = Color3.new(0.1, 0, 0.2),
			OutdoorAmbient = Color3.new(0.05, 0, 0.15),
			ColorShift_Top = Color3.new(0.3, 0, 0.5),
			FogEnd = 300,
			FogColor = Color3.new(0.1, 0, 0.15)
		}):Play()

		-- Reduce gravity slightly
		local gravityTween = TweenService:Create(workspace, TweenInfo.new(4), {Gravity = 150})
		gravityTween:Play()

		task.wait(3)

		-- Create the ultimate nexus core
		local ultimateCore = CreatePart(VT(25, 25, 25), ROOTPART.CFrame * CF(0, 50, 0), Color3.new(0.7, 0.1, 1), Enum.Material.Neon, 0, true)
		ultimateCore.Shape = Enum.PartType.Ball

		-- Energy pillars rising from ground (ENHANCED)
		for pillar = 1, 24 do  -- DOUBLED
			local angle = pillar * 15
			local distance = 80
			local pillarPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * distance, 0, math.sin(RAD(angle)) * distance)

			local energyPillar = CreatePart(VT(12, 5, 12), CF(pillarPos), Color3.new(0.5, 0, 1), Enum.Material.Neon, 0.2, true)
			TweenService:Create(energyPillar, TweenInfo.new(3), {
				Size = VT(12, 120, 12),
				CFrame = CF(pillarPos) * CF(0, 60, 0)
			}):Play()

			-- Energy explosions at pillar tops
			coroutine.wrap(function()
				task.wait(2)
				for exp = 1, 5 do
					CreateEffect("Sphere", CF(pillarPos + VT(0, 120, 0)), VT(10, 10, 10), VT(35, 35, 35), Color3.new(0.7, 0, 1), 0.6, nil, 2)
					ApplyAoE(pillarPos + VT(0, 120, 0), 25, 180, 70)
					task.wait(0.4)
				end
			end)()

			ApplyAoE(pillarPos, 20, 150, 50)
			Debris:AddItem(energyPillar, 45)
			task.wait(0.15)
		end

		-- Massive ground fissures with energy
		for fissure = 1, 8 do
			local fissureAngle = fissure * 45
			local fissureDir = VT(math.cos(RAD(fissureAngle)), 0, math.sin(RAD(fissureAngle)))

			for dist = 20, 100, 10 do
				local fissurePos = ROOTPART.Position + fissureDir * dist
				local crack = CreatePart(VT(8, 15, 8), CF(fissurePos), Color3.new(0.6, 0, 1), Enum.Material.Neon, 0.3, true)
				TweenService:Create(crack, TweenInfo.new(2), {
					Size = VT(8, 40, 8),
					Transparency = 0.6
				}):Play()
				ApplyAoE(fissurePos, 12, 120, 45)
				Debris:AddItem(crack, 25)
				task.wait(0.08)
			end
		end

		-- Chaos energy waves
		for wave = 1, 15 do
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(90), 0, 0), 
				VT(20, 20, 5), VT(80 + wave*20, 80 + wave*20, 5), Color3.new(0.6, 0, 1), 0.5, nil, 2)
			ApplyAoE(ROOTPART.Position, 40 + wave*5, 140, 50)
			task.wait(0.2)
		end

		task.wait(2)
		DisplayTaunt("ALL DIMENSIONS CONVERGE INTO ONE!", 5, Color3.fromRGB(255, 100, 0))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.4, false, "Dimensional rift")

		-- Create orbiting planetary spheres
		local orbs = {}
		for o = 1, 10 do
			local orb = CreatePart(VT(10, 10, 10), ultimateCore.CFrame, 
				Color3.new(MRANDOM(5, 10)/10, MRANDOM(0, 5)/10, MRANDOM(8, 10)/10), Enum.Material.Neon, 0, true)
			orb.Shape = Enum.PartType.Ball
			table.insert(orbs, orb)
		end

		-- Orbiting animation
		coroutine.wrap(function()
			local angle = 0
			local radius = 25
			while ultimateCore.Parent do
				angle = angle + 2
				radius = math.min(radius + 0.4, 60)
				for i, orb in ipairs(orbs) do
					if orb.Parent then
						local orbAngle = angle + (i * 36)
						orb.CFrame = ultimateCore.CFrame * CF(
							math.cos(RAD(orbAngle)) * radius,
							math.sin(RAD(orbAngle * 1.5)) * 20,
							math.sin(RAD(orbAngle)) * radius
						)
					end
				end
				task.wait()
			end
		end)()

		-- Grow the core
		TweenService:Create(ultimateCore, TweenInfo.new(5), {Size = VT(80, 80, 80)}):Play()

		task.wait(5)  -- Longer wait for Phase 1

		-- ===== PHASE 2: ELEMENTAL CONVERGENCE =====
		DisplayTaunt("THE ELEMENTS BOW TO MY WILL!", 5, Color3.fromRGB(255, 255, 100))
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 3, 0.6, false, "Lightning")

		-- Change lighting to stormy purple
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.15, 0, 0.25),
			ColorShift_Top = Color3.new(0.5, 0.2, 0.7),
			FogColor = Color3.new(0.2, 0, 0.3)
		}):Play()

		-- Enhanced lightning storm from core using realistic lightning (MASSIVELY ENHANCED)
		CurrentFinalePhase = 2
		for lightning = 1, 70 do  -- DOUBLED lightning strikes
			local targetPos = ROOTPART.Position + VT(MRANDOM(-140, 140), 0, MRANDOM(-140, 140))
			local startPos = ultimateCore.Position

			-- Use realistic lightning bolts
			CreateLightningBolt(startPos, targetPos, 25, Color3.new(1, 1, 0.8), MRANDOM(5, 9), 0.4)

			-- Chain lightning effect
			if lightning % 3 == 0 then
				for chain = 1, 3 do
					local chainPos = targetPos + VT(MRANDOM(-40, 40), 0, MRANDOM(-40, 40))
					CreateLightningBolt(targetPos, chainPos, 15, Color3.new(0.8, 0.8, 1), 4, 0.3)
					ApplyAoE(chainPos, 20, 180, 60)
				end
			end

			CreatePositionalSound("explosion_impact", targetPos, 2, MRANDOM(7, 12)/10, false, "Lightning impact")
			CreateEffect("Sphere", CF(targetPos), VT(15, 15, 15), VT(50, 50, 50), Color3.new(1, 1, 0.8), 0.5, nil, 2)
			CreateEffect("Ring", CF(targetPos) * ANGLES(RAD(90), 0, 0), VT(20, 20, 5), VT(60, 60, 5), Color3.new(1, 1, 0), 0.4, nil, 1.5)
			ApplyAoE(targetPos, 35, 320, 130)
			task.wait(0.06)
		end

		-- Elemental orb barrage
		for orb = 1, 40 do
			local orbPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 60, MRANDOM(-100, 100))
			local element = MRANDOM(1, 4)
			local color
			if element == 1 then color = Color3.new(1, 0.3, 0) -- Fire
			elseif element == 2 then color = Color3.new(0, 0.8, 1) -- Ice
			elseif element == 3 then color = Color3.new(1, 1, 0) -- Lightning
			else color = Color3.new(0, 1, 1) end -- Plasma

			local elemOrb = CreatePart(VT(8, 8, 8), CF(orbPos), color, Enum.Material.Neon, 0, false)
			elemOrb.Shape = Enum.PartType.Ball

			local targetDir = (ROOTPART.Position + VT(MRANDOM(-60, 60), 0, MRANDOM(-60, 60)) - orbPos).Unit
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = VT(1e9, 1e9, 1e9)
			bv.Velocity = targetDir * 140
			bv.Parent = elemOrb

			local hitDebounce = false
			elemOrb.Touched:Connect(function(hit)
				if not hitDebounce and isValidMeteorCollision(hit) then
					hitDebounce = true
					CreateEffect("Sphere", CF(elemOrb.Position), VT(8, 8, 8), VT(35, 35, 35), color, 0.6, nil, 2)
					ApplyAoE(elemOrb.Position, 25, 280, 100)
					elemOrb:Destroy()
				end
			end)

			Debris:AddItem(elemOrb, 4)
			task.wait(0.1)
		end

		-- Thunderstorm columns
		for column = 1, 12 do
			local colPos = ROOTPART.Position + VT(MRANDOM(-90, 90), 0, MRANDOM(-90, 90))

			for strike = 1, 8 do
				CreateLightningBolt(colPos + VT(0, 200, 0), colPos, 20, Color3.new(1, 1, 0.9), 6, 0.35)
				CreateEffect("Sphere", CF(colPos), VT(12, 12, 12), VT(40, 40, 40), Color3.new(1, 1, 0), 0.5, nil, 1.8)
				ApplyAoE(colPos, 30, 290, 110)
				task.wait(0.15)
			end
		end

		task.wait(2)

		-- ===== PHASE 3: METEOR APOCALYPSE =====
		DisplayTaunt("THE COSMOS ITSELF ATTACKS!", 5, Color3.fromRGB(255, 80, 0))
		CreatePositionalSound("explosion_impact", ROOTPART.Position, 3, 0.5, false, "Impact")

		-- Change to fiery orange
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.3, 0.1, 0),
			ColorShift_Top = Color3.new(0.8, 0.3, 0),
			FogColor = Color3.new(0.3, 0.1, 0)
		}):Play()

		-- Enhanced realistic meteor shower with ground collision
		for wave = 1, 8 do  -- More waves for longer finale
			for m = 1, 12 do  -- More meteors per wave
				coroutine.wrap(function()
					local pos = ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120))
					local meteorSize = MRANDOM(15, 25)
					local meteor = CreatePart(VT(meteorSize, meteorSize, meteorSize), CF(pos + VT(0, 200, 0)), 
						Color3.new(0.3, 0.2, 0.15), Enum.Material.Concrete, 0, false)
					meteor.Shape = Enum.PartType.Ball

					-- Fire core
					local fireCore = CreatePart(VT(meteorSize*0.6, meteorSize*0.6, meteorSize*0.6), meteor.CFrame,
						Color3.new(1, MRANDOM(5, 8)/10, 0), Enum.Material.Neon, 0, false)
					fireCore.Shape = Enum.PartType.Ball

					local coreWeld = Instance.new("WeldConstraint")
					coreWeld.Part0 = meteor
					coreWeld.Part1 = fireCore
					coreWeld.Parent = meteor

					-- Bright light
					local light = Instance.new("PointLight")
					light.Brightness = 25
					light.Color = Color3.new(1, 0.5, 0.2)
					light.Range = 100
					light.Parent = meteor

					-- Realistic fire trail
					coroutine.wrap(function()
						while meteor.Parent do
							local trail = CreatePart(VT(meteorSize*1.2, meteorSize*1.2, meteorSize*1.2), meteor.CFrame,
								Color3.new(1, MRANDOM(4, 7)/10, 0), Enum.Material.Neon, 0.2, true)
							trail.Shape = Enum.PartType.Ball
							TweenService:Create(trail, TweenInfo.new(1.2), {
								Size = VT(meteorSize*0.3, meteorSize*0.3, meteorSize*0.3),
								Transparency = 1
							}):Play()
							Debris:AddItem(trail, 1.2)
							task.wait(0.04)
						end
					end)()

					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = VT(1e9, 1e9, 1e9)
					bv.Velocity = VT(0, -250, 0)
					bv.Parent = meteor

					local hitDebounce = false
					local lastY = meteor.Position.Y

					-- Ground detection
					coroutine.wrap(function()
						while meteor.Parent do
							local currentY = meteor.Position.Y
							local groundRay = workspace:Raycast(meteor.Position, VT(0, -meteor.Size.Y, 0))
							if groundRay or (lastY - currentY < 0.1 and currentY < ROOTPART.Position.Y + 10) then
								if not hitDebounce and groundRay and isValidMeteorCollision(groundRay.Instance) then
									hitDebounce = true
									local impactPos = groundRay and groundRay.Position or meteor.Position

									CreatePositionalSound("explosion_impact", impactPos, 3, MRANDOM(8, 13)/10, false, "Meteor impact")
									CreatePositionalSound("massive_explosion", impactPos, 2, MRANDOM(7, 12)/10, false, "Meteor explosion")
									CreateEffect("Sphere", CF(impactPos), VT(meteorSize, meteorSize, meteorSize), VT(meteorSize*4, meteorSize*4, meteorSize*4), Color3.new(1, 0.4, 0), 1, nil, 4)
									CreateEffect("Ring", CF(impactPos), VT(meteorSize*2, 1, meteorSize*2), VT(meteorSize*6, 1, meteorSize*6), Color3.new(1, 0.5, 0), 1.2, nil, 3)
									ApplyAoE(impactPos, meteorSize*2, 400, 180)

									meteor:Destroy()
									if fireCore.Parent then fireCore:Destroy() end
								end
							end
							lastY = currentY
							task.wait(0.05)
						end
					end)()

					meteor.Touched:Connect(function(hit)
						if not hitDebounce and hit.Parent ~= CHARACTER and hit.Parent ~= Effects and hit.Name ~= "Base" then
							hitDebounce = true
							local impactPos = meteor.Position
							local groundRay = workspace:Raycast(impactPos, VT(0, -50, 0))
							if groundRay then
								impactPos = groundRay.Position
							end
							CreatePositionalSound("explosion_impact", impactPos, 3, MRANDOM(8, 13)/10, false, "Meteor impact")
							CreateEffect("Sphere", CF(impactPos), VT(meteorSize, meteorSize, meteorSize), VT(meteorSize*4, meteorSize*4, meteorSize*4), Color3.new(1, 0.4, 0), 1, nil, 4)
							ApplyAoE(impactPos, meteorSize*2, 400, 180)
							meteor:Destroy()
							if fireCore.Parent then fireCore:Destroy() end
						end
					end)

					Debris:AddItem(meteor, 8)
					Debris:AddItem(fireCore, 8)
				end)()
			end
			task.wait(1.5)  -- Longer between waves for 5 minute finale
		end

		task.wait(2)  -- Longer wait between phases

		-- ===== PHASE 4: DIMENSIONAL RIFT CHAOS =====
		DisplayTaunt("REALITY TEARS AT THE SEAMS!", 5, Color3.fromRGB(150, 0, 255))
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.7, false, "Reality tear")

		-- Change to void purple
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.1, 0, 0.3),
			ColorShift_Top = Color3.new(0.3, 0, 0.8),
			FogColor = Color3.new(0.1, 0, 0.2)
		}):Play()

		-- Gravity fluctuation
		workspace.Gravity = 100

		-- Dimensional rifts with optimized projectiles
		for r = 1, 12 do
			local riftPos = ROOTPART.Position + VT(MRANDOM(-80, 80), MRANDOM(20, 40), MRANDOM(-80, 80))
			local rift = CreatePart(VT(20, 40, 6), CF(riftPos) * ANGLES(RAD(MRANDOM(-45, 45)), RAD(MRANDOM(-180, 180)), 0), 
				Color3.new(0.1, 0, 0.6), Enum.Material.ForceField, 0.2, true)

			-- Void projectiles from rift
			coroutine.wrap(function()
				for projectile = 1, 12 do
					local voidBall = CreatePart(VT(6, 6, 6), rift.CFrame, Color3.new(0.2, 0, 0.5), Enum.Material.Neon, 0, false)
					voidBall.Shape = Enum.PartType.Ball

					local direction = (ROOTPART.Position + VT(MRANDOM(-50, 50), 0, MRANDOM(-50, 50)) - voidBall.Position).Unit
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = VT(1e9, 1e9, 1e9)
					bv.Velocity = direction * 80
					bv.Parent = voidBall

					local hitDebounce = false
					voidBall.Touched:Connect(function(hit)
						if not hitDebounce and hit.Parent ~= CHARACTER then
							hitDebounce = true
							CreateEffect("Sphere", CF(voidBall.Position), VT(6, 6, 6), VT(25, 25, 25), Color3.new(0.2, 0, 0.5), 0.5, nil, 2)
							ApplyAoE(voidBall.Position, 20, 250, 90)
							voidBall:Destroy()
						end
					end)
					Debris:AddItem(voidBall, 4)
					task.wait(0.2)
				end
			end)()
			Debris:AddItem(rift, 6)
		end

		task.wait(3)  -- Longer wait between phases

		-- ===== PHASE 5: PLASMA NOVA =====
		DisplayTaunt("STELLAR CORE ENERGY UNLEASHED!", 5, Color3.fromRGB(0, 255, 255))
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Plasma")

		-- Change to cyan/plasma colors
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0, 0.2, 0.3),
			ColorShift_Top = Color3.new(0, 0.5, 1),
			FogColor = Color3.new(0, 0.15, 0.25)
		}):Play()

		-- Restore some gravity
		workspace.Gravity = 120

		-- Enhanced plasma explosions in grid pattern with more explosions
		for x = -3, 3 do
			for z = -3, 3 do
				local pos = ROOTPART.Position + VT(x * 50, 0, z * 50)
				CreatePositionalSound("explosion_impact", pos, 1.5, MRANDOM(6, 10)/10, false, "Plasma explosion")
				CreateEffect("Sphere", CF(pos), VT(12, 12, 12), VT(55, 55, 55), Color3.new(0.2, 0.8, 1), 0.7, nil, 3)
				ApplyAoE(pos, 35, 300, 110)
			end
			task.wait(0.2)
		end

		-- Enhanced plasma beams from core
		for beam = 1, 24 do  -- More beams
			local angle = beam * 15
			local beamLength = 150
			local endPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * beamLength, 0, math.sin(RAD(angle)) * beamLength)

			local plasmBeam = CreatePart(VT(15, 15, beamLength), CF(ROOTPART.Position, endPos) * CF(0, 0, -beamLength/2), 
				Color3.new(0, 1, 1), Enum.Material.Neon, 0.3, true)
			TweenService:Create(plasmBeam, TweenInfo.new(1.5), {Transparency = 1}):Play()
			Debris:AddItem(plasmBeam, 1.5)

			CreatePositionalSound("energy_beam", endPos, 1.5, MRANDOM(5, 9)/10, false, "Plasma beam")
			ApplyAoE(endPos, 30, 280, 100)
			task.wait(0.05)
		end

		task.wait(3)  -- Longer wait

		-- ===== PHASE 6: QUANTUM COLLAPSE =====
		DisplayTaunt("SPACE AND TIME ITSELF SHATTERS!", 5, Color3.fromRGB(0, 255, 100))
		CreatePositionalSound("time_distortion", ROOTPART.Position, 3, 0.6, false, "Time distortion")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 2, 0.5, false, "Reality tear")

		-- Change to green quantum colors
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0, 0.25, 0.15),
			ColorShift_Top = Color3.new(0, 0.8, 0.4),
			FogColor = Color3.new(0, 0.2, 0.1)
		}):Play()

		-- Gravity becomes very low
		workspace.Gravity = 50

		-- Enhanced quantum slices in all directions
		for slice = 1, 35 do  -- More slices
			local sliceAngle = slice * 12
			local slicePart = CreatePart(VT(3, 100, 120), ROOTPART.CFrame * ANGLES(RAD(MRANDOM(-30, 30)), RAD(sliceAngle), RAD(MRANDOM(-30, 30))), 
				Color3.new(0, 1, MRANDOM(3, 8)/10), Enum.Material.Neon, 0.3, true)

			TweenService:Create(slicePart, TweenInfo.new(1.2), {
				Transparency = 1,
				Size = VT(3, 100, 150)
			}):Play()
			Debris:AddItem(slicePart, 1.2)

			CreatePositionalSound("energy_beam", ROOTPART.Position, 1, MRANDOM(4, 8)/10, false, "Quantum slice")
			ApplyAoE(ROOTPART.Position, 80, 300, 90)
			task.wait(0.08)
		end

		task.wait(2.5)  -- Longer wait

		-- ===== PHASE 7: INFERNO APOCALYPSE =====
		DisplayTaunt("BURN IN ETERNAL HELLFIRE!", 5, Color3.fromRGB(255, 100, 0))
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.5, false, "Fire whoosh")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 2, 0.4, false, "Fire explosion")

		-- Change to fiery red
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.4, 0.1, 0),
			ColorShift_Top = Color3.new(1, 0.3, 0),
			FogColor = Color3.new(0.3, 0.05, 0)
		}):Play()

		-- Enhanced fire tornadoes around the arena
		for tornado = 1, 18 do  -- More tornadoes
			local tornadoPos = ROOTPART.Position + VT(MRANDOM(-80, 80), 0, MRANDOM(-80, 80))

			for segment = 1, 20 do
				local fire = CreatePart(VT(20 - segment*0.6, 10, 20 - segment*0.6), 
					CF(tornadoPos) * CF(0, segment*7, 0) * ANGLES(0, RAD(segment*18), 0), 
					Color3.new(1, MRANDOM(2, 6)/10, 0), Enum.Material.Neon, 0.3, true)
				fire.Shape = Enum.PartType.Cylinder
				TweenService:Create(fire, TweenInfo.new(3), {Transparency = 1}):Play()
				Debris:AddItem(fire, 3)
			end

			CreatePositionalSound("fire_whoosh", tornadoPos, 1.5, MRANDOM(5, 9)/10, false, "Fire tornado")
			ApplyAoE(tornadoPos, 35, 320, 100)
		end

		task.wait(3)  -- Longer wait

		-- ===== PHASE 8: THE CONVERGENCE - BUILDING TO FINALE =====
		DisplayTaunt("ALL POWERS CONVERGE... THE END IS NEAR!", 6, Color3.fromRGB(255, 0, 255))
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 4, 0.4, false, "Cosmic")

		-- Core starts shrinking (preparing for explosion)
		TweenService:Create(ultimateCore, TweenInfo.new(4), {
			Size = VT(10, 10, 10),
			Transparency = 0,
			Color = Color3.new(1, 1, 1)
		}):Play()

		-- All orbs rush to center
		for _, orb in ipairs(orbs) do
			if orb.Parent then
				TweenService:Create(orb, TweenInfo.new(4), {
					CFrame = ultimateCore.CFrame,
					Size = VT(0, 0, 0),
					Transparency = 1
				}):Play()
			end
		end

		-- Lighting becomes extremely dark
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = 0,
			Ambient = Color3.new(0, 0, 0),
			ColorShift_Top = Color3.new(0, 0, 0),
			FogColor = Color3.new(0, 0, 0),
			FogEnd = 150
		}):Play()

		-- Gravity returns to low
		workspace.Gravity = 80

		-- Enhanced energy spiraling into core
		for spiral = 1, 60 do  -- More energy orbs for spectacular effect
			local spiralOrb = CreatePart(VT(8, 8, 8), ROOTPART.CFrame * CF(MRANDOM(-60, 60), MRANDOM(-20, 40), MRANDOM(-60, 60)), 
				Color3.new(MRANDOM(8, 10)/10, MRANDOM(0, 5)/10, MRANDOM(8, 10)/10), Enum.Material.Neon, 0, true)
			spiralOrb.Shape = Enum.PartType.Ball

			local spiralLight = Instance.new("PointLight")
			spiralLight.Brightness = 15
			spiralLight.Color = Color3.new(MRANDOM(8, 10)/10, MRANDOM(0, 5)/10, MRANDOM(8, 10)/10)
			spiralLight.Range = 30
			spiralLight.Parent = spiralOrb

			TweenService:Create(spiralOrb, TweenInfo.new(3), {
				CFrame = ultimateCore.CFrame,
				Size = VT(0, 0, 0)
			}):Play()
			TweenService:Create(spiralLight, TweenInfo.new(3), {Brightness = 0}):Play()
			Debris:AddItem(spiralOrb, 3)
			task.wait(0.05)
		end

		task.wait(4)  -- Longer wait for dramatic buildup

		-- ===== PHASE 9: THE ULTIMATE CATACLYSMIC EXPLOSION =====
		DisplayTaunt("WITNESS... TOTAL... ANNIHILATION!!!", 7, Color3.fromRGB(255, 255, 255))

		-- ALL SOUNDS PLAY AT ONCE FOR ULTIMATE IMPACT
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.3, false, "Massive explosion")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.3, false, "Explosion")
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 4, 0.5, false, "Lightning")
		CreatePositionalSound("explosion_impact", ROOTPART.Position, 4, 0.4, false, "Impact")
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.4, false, "Rift")

		-- Destroy core and orbs
		ultimateCore:Destroy()
		for _, orb in ipairs(orbs) do
			if orb.Parent then orb:Destroy() end
		end

		-- Blinding white flash
		local flash = Instance.new("ColorCorrectionEffect")
		flash.Brightness = 1.5
		flash.Contrast = 1
		flash.Saturation = -1
		flash.Parent = Lighting
		TweenService:Create(flash, TweenInfo.new(1), {Brightness = 0, Saturation = 0, Contrast = 0}):Play()
		Debris:AddItem(flash, 2)

		-- Zero gravity for dramatic effect
		workspace.Gravity = 0

		-- MASSIVE EXPLOSION WAVES (optimized but still spectacular)
		for explosion = 1, 50 do  -- More explosions for finale
			local pos = ROOTPART.Position + VT(MRANDOM(-150, 150), MRANDOM(-30, 30), MRANDOM(-150, 150))
			local randomColor = Color3.new(MRANDOM(7, 10)/10, MRANDOM(5, 10)/10, MRANDOM(7, 10)/10)

			-- Giant sphere with sound
			CreatePositionalSound("explosion_impact", pos, 2, MRANDOM(6, 11)/10, false, "Finale explosion")
			CreateEffect("Sphere", CF(pos), VT(25, 25, 25), VT(100, 100, 100), randomColor, 1.2, nil, 5)

			-- Ring wave
			CreateEffect("Ring", CF(pos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(20, 20, 5), VT(90, 90, 5), randomColor, 1, nil, 4)

			ApplyAoE(pos, 50, 650, 250)
			task.wait(0.08)
		end

		-- Enhanced lightning apocalypse using realistic lightning
		for lightning = 1, 60 do  -- More lightning
			local targetPos = ROOTPART.Position + VT(MRANDOM(-140, 140), 0, MRANDOM(-140, 140))
			local startPos = targetPos + VT(0, 200, 0)

			-- Realistic lightning from sky
			CreateLightningBolt(startPos, targetPos, 25, Color3.new(1, 1, 0.9), MRANDOM(5, 8), 0.4)

			CreatePositionalSound("lightning_strike", targetPos, 2, MRANDOM(6, 11)/10, false, "Lightning strike")
			CreateEffect("Sphere", CF(targetPos), VT(20, 20, 20), VT(60, 60, 60), Color3.new(1, 1, 0.9), 0.6, nil, 2.5)
			ApplyAoE(targetPos, 35, 400, 150)
			task.wait(0.05)
		end

		-- Enhanced ground shockwaves
		for shockwave = 1, 60 do  -- More shockwaves
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(90), 0, 0), 
				VT(15, 15, 15), VT(60 + shockwave*30, 60 + shockwave*30, 15), 
				Color3.new(MRANDOM(8, 10)/10, MRANDOM(5, 8)/10, MRANDOM(3, 7)/10), 0.4, nil, 2)
			task.wait(0.05)
		end

		-- Enhanced dimensional tears across the battlefield
		for tear = 1, 35 do  -- More tears
			local tearPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(-15, 40), MRANDOM(-120, 120))
			local rift = CreatePart(VT(30, 60, 8), CF(tearPos) * ANGLES(RAD(MRANDOM(-60, 60)), RAD(MRANDOM(-180, 180)), 0), 
				Color3.new(0.1, 0, 0.5), Enum.Material.ForceField, 0.2, true)

			CreatePositionalSound("dimensional_rift", tearPos, 1.5, MRANDOM(5, 9)/10, false, "Dimensional tear")
			TweenService:Create(rift, TweenInfo.new(2), {Transparency = 1}):Play()
			Debris:AddItem(rift, 2)
			ApplyAoE(tearPos, 40, 500, 180)
			task.wait(0.08)
		end

		task.wait(2.5)  -- Longer wait

		-- FINAL ULTIMATE DEVASTATION
		DisplayTaunt("THIS... IS... THE END!!!", 5, Color3.fromRGB(255, 255, 255))

		-- One last massive explosion
		CreateEffect("Sphere", ROOTPART.CFrame, VT(100, 100, 100), VT(400, 400, 400), Color3.new(1, 1, 1), 5, nil, 15)
		ApplyAoE(ROOTPART.Position, 200, 2000, 500)

		-- Enhanced multiple colored explosion rings with sounds
		for ring = 1, 40 do  -- More rings
			local ringColor = Color3.new(MRANDOM(7, 10)/10, MRANDOM(5, 10)/10, MRANDOM(7, 10)/10)
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180))), 
				VT(50, 50, 10), VT(200 + ring*20, 200 + ring*20, 10), ringColor, 1.5, nil, 8)

			if ring % 5 == 0 then
				CreatePositionalSound("massive_explosion", ROOTPART.Position, 2, MRANDOM(5, 9)/10, false, "Shockwave")
			end
			task.wait(0.1)
		end

		task.wait(2)  -- Brief wait before continuing

		-- ===== PHASE 10: SINGULARITY VORTEX =====
		CurrentFinalePhase = 10
		DisplayTaunt("BLACK HOLES CONSUME ALL!", 5, Color3.fromRGB(0, 0, 0))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.3, false, "Singularity")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.4, false, "Reality tear")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2.5, 0.6, false, "Time distortion")

		-- Massive explosion waves to signal NPC phase beginning
		for exp = 1, 15 do
			local pos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(0, 40), MRANDOM(-100, 100))
			CreateEffect("Sphere", CF(pos), VT(15, 15, 15), VT(50, 50, 50), Color3.new(0.1, 0, 0.3), 0.7, nil, 2)
			CreatePositionalSound("explosion_impact", pos, 1.5, MRANDOM(6, 10)/10, false, "Chaos explosion")
			ApplyAoE(pos, 28, 200, 80)
			task.wait(0.08)
		end

		-- Spawn Dark Heralds with dramatic effects
		for i = 1, 6 do  -- Increased from 4 to 6
			local spawnPos = ROOTPART.Position + VT(MRANDOM(-60, 60), 0, MRANDOM(-60, 60))

			-- Dramatic spawn effect
			CreateEffect("Sphere", CF(spawnPos), VT(5, 5, 5), VT(25, 25, 25), Color3.fromRGB(80, 0, 120), 0.6, nil, 2)
			CreateEffect("Ring", CF(spawnPos) * ANGLES(RAD(90), 0, 0), VT(10, 10, 3), VT(40, 40, 3), Color3.fromRGB(80, 0, 120), 0.5, nil, 1.5)
			CreatePositionalSound("dimensional_rift", spawnPos, 2, MRANDOM(8, 12)/10, false, "Herald spawn")
			CreatePositionalSound("intro_explosion", spawnPos, 1.5, MRANDOM(7, 11)/10, false, "Spawn explosion")
			ApplyAoE(spawnPos, 20, 180, 70)

			spawnNPC("DarkHerald", spawnPos)

			-- Lightning strikes around spawn
			for l = 1, 3 do
				local lightningPos = spawnPos + VT(MRANDOM(-30, 30), 0, MRANDOM(-30, 30))
				CreateLightningBolt(spawnPos + VT(0, 50, 0), lightningPos, 12, Color3.new(0.5, 0, 0.8), 4, 0.3)
				CreatePositionalSound("lightning_crack", lightningPos, 1.2, MRANDOM(9, 13)/10, false, "Spawn lightning")
			end

			task.wait(0.5)
		end

		-- Black hole lighting
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0,
			Ambient = Color3.new(0, 0, 0),
			ColorShift_Top = Color3.new(0.05, 0.05, 0.05),
			FogColor = Color3.new(0, 0, 0),
			FogEnd = 200
		}):Play()

		-- Create singularities
		local singularities = {}
		for s = 1, 5 do
			local singPos = ROOTPART.Position + VT(MRANDOM(-80, 80), 30, MRANDOM(-80, 80))
			local singularity = CreatePart(VT(15, 15, 15), CF(singPos), Color3.new(0, 0, 0), Enum.Material.Neon, 0, true)
			singularity.Shape = Enum.PartType.Ball

			-- Event horizon
			local horizon = CreatePart(VT(25, 25, 25), singularity.CFrame, Color3.new(0.3, 0, 0.6), Enum.Material.Neon, 0.7, true)
			horizon.Shape = Enum.PartType.Ball

			table.insert(singularities, {Core = singularity, Horizon = horizon})

			-- Pull players toward singularity
			coroutine.wrap(function()
				for pull = 1, 100 do
					if not singularity.Parent then break end

					for _, playerData in pairs(cachedPlayers) do
						if playerData.RootPart and playerData.Humanoid then
							local dist = (playerData.RootPart.Position - singularity.Position).Magnitude
							if dist < 60 then
								local pullStrength = (60 - dist) / 60 * 150
								local direction = (singularity.Position - playerData.RootPart.Position).Unit

								local pullForce = Instance.new("BodyVelocity")
								pullForce.MaxForce = VT(1e9, 1e9, 1e9)
								pullForce.Velocity = direction * pullStrength
								pullForce.Parent = playerData.RootPart
								Debris:AddItem(pullForce, 0.1)

								if dist < 15 then
									ApplyDamage(playerData.Humanoid, 80, targetPlayer)
								end
							end
						end
					end

					-- Chaos effects around singularities
					if pull % 10 == 0 then
						local chaosPos = singularity.Position + VT(MRANDOM(-40, 40), MRANDOM(-20, 20), MRANDOM(-40, 40))
						CreateEffect("Sphere", CF(chaosPos), VT(8, 8, 8), VT(20, 20, 20), Color3.new(0.2, 0, 0.5), 0.5, nil, 1.5)
						CreatePositionalSound("time_distortion", chaosPos, 1, MRANDOM(7, 13)/10, false, "Singularity distortion")
						ApplyAoE(chaosPos, 15, 120, 50)
					end

					horizon.CFrame = singularity.CFrame
					task.wait(0.1)
				end
			end)()

			Debris:AddItem(singularity, 20)
			Debris:AddItem(horizon, 20)
		end

		-- Additional chaos during singularities
		coroutine.wrap(function()
			for chaos = 1, 60 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(5, 50), MRANDOM(-120, 120))
				CreateEffect("Sphere", CF(chaosPos), VT(10, 10, 10), VT(30, 30, 30), Color3.new(0.1, 0, 0.4), 0.6, nil, 1.8)
				CreatePositionalSound("reality_tear", chaosPos, 1.2, MRANDOM(6, 11)/10, false, "Reality chaos")
				ApplyAoE(chaosPos, 20, 180, 70)
				task.wait(0.35)
			end
		end)()

		task.wait(20)

		-- ===== PHASE 11: REALITY FRACTURE =====
		CurrentFinalePhase = 11
		DisplayTaunt("REALITY ITSELF SHATTERS!", 5, Color3.fromRGB(150, 0, 255))
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.5, false, "Reality fracture")
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.6, false, "Dimensional rift")
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 2.5, 0.4, false, "Cosmic ambient")

		-- Reality breaking effects
		for break_effect = 1, 20 do
			local breakPos = ROOTPART.Position + VT(MRANDOM(-110, 110), MRANDOM(10, 60), MRANDOM(-110, 110))
			CreateEffect("Sphere", CF(breakPos), VT(12, 12, 12), VT(40, 40, 40), Color3.new(0.2, 0, 0.6), 0.8, nil, 2.5)
			CreateEffect("Ring", CF(breakPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(15, 15, 5), VT(50, 50, 5), Color3.new(0.3, 0, 0.8), 0.6, nil, 2)
			CreatePositionalSound("explosion_impact", breakPos, 1.8, MRANDOM(5, 10)/10, false, "Reality break")
			ApplyAoE(breakPos, 30, 220, 85)
			task.wait(0.12)
		end

		-- Spawn Void Sentinels with dramatic effects
		for i = 1, 7 do  -- Increased from 5 to 7
			local spawnPos = ROOTPART.Position + VT(MRANDOM(-70, 70), 0, MRANDOM(-70, 70))

			-- Massive spawn effect with reality tear
			CreateEffect("Sphere", CF(spawnPos), VT(8, 8, 8), VT(35, 35, 35), Color3.fromRGB(50, 0, 150), 0.7, nil, 2.5)
			CreateEffect("Ring", CF(spawnPos) * ANGLES(RAD(90), 0, 0), VT(12, 12, 5), VT(50, 50, 5), Color3.fromRGB(100, 0, 200), 0.6, nil, 2)
			CreatePositionalSound("reality_tear", spawnPos, 2.5, MRANDOM(7, 12)/10, false, "Sentinel spawn")
			CreatePositionalSound("dimensional_rift", spawnPos, 2, MRANDOM(8, 13)/10, false, "Void portal")
			CreatePositionalSound("time_distortion", spawnPos, 1.5, MRANDOM(6, 10)/10, false, "Time break")

			-- Reality cracks spreading from spawn
			for crack = 1, 5 do
				local crackAngle = crack * 72
				local crackDir = VT(math.cos(RAD(crackAngle)), 0, math.sin(RAD(crackAngle)))
				for dist = 10, 40, 10 do
					local crackPos = spawnPos + crackDir * dist
					CreateEffect("Sphere", CF(crackPos), VT(5, 5, 5), VT(15, 15, 15), Color3.new(0.15, 0, 0.5), 0.5, nil, 1.2)
					CreatePositionalSound("reality_tear", crackPos, 1, MRANDOM(8, 14)/10, false, "Reality crack")
				end
			end

			ApplyAoE(spawnPos, 25, 200, 80)
			spawnNPC("VoidSentinel", spawnPos)
			task.wait(0.6)
		end

		-- Trippy lighting
		coroutine.wrap(function()
			for flicker = 1, 40 do
				TweenService:Create(Lighting, TweenInfo.new(0.5), {
					Ambient = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 5)/10, MRANDOM(5, 10)/10),
					ColorShift_Top = Color3.new(MRANDOM(0, 10)/10, 0, MRANDOM(5, 10)/10)
				}):Play()
				task.wait(0.5)
			end
		end)()

		-- Gravity randomization with chaos
		for grav = 1, 40 do
			workspace.Gravity = MRANDOM(0, 200)

			-- Chaos explosions during gravity shifts
			if grav % 3 == 0 then
				local gravChaosPos = ROOTPART.Position + VT(MRANDOM(-90, 90), MRANDOM(10, 50), MRANDOM(-90, 90))
				CreateEffect("Sphere", CF(gravChaosPos), VT(10, 10, 10), VT(35, 35, 35), Color3.new(MRANDOM(2, 6)/10, 0, MRANDOM(5, 9)/10), 0.7, nil, 2)
				CreatePositionalSound("time_distortion", gravChaosPos, 1.5, MRANDOM(5, 11)/10, false, "Gravity chaos")
				ApplyAoE(gravChaosPos, 25, 190, 75)
			end

			task.wait(0.5)
		end

		-- Reality tears with enhanced chaos
		for tear = 1, 30 do  -- Increased from 20 to 30
			local tearPos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(-10, 50), MRANDOM(-100, 100))
			local rift = CreatePart(VT(25, 50, 5), CF(tearPos) * ANGLES(RAD(MRANDOM(-90, 90)), RAD(MRANDOM(-180, 180)), 0), 
				Color3.new(0.1, 0, 0.6), Enum.Material.ForceField, 0.2, true)

			CreatePositionalSound("dimensional_rift", tearPos, 2, MRANDOM(6, 12)/10, false, "Reality tear")
			CreatePositionalSound("reality_tear", tearPos, 1.8, MRANDOM(7, 13)/10, false, "Tear sound")

			-- Void projectiles from tears
			for proj = 1, 4 do
				local voidProj = CreatePart(VT(6, 6, 6), rift.CFrame, Color3.new(0.15, 0, 0.5), Enum.Material.Neon, 0, false)
				voidProj.Shape = Enum.PartType.Ball

				local projDir = (ROOTPART.Position + VT(MRANDOM(-50, 50), 0, MRANDOM(-50, 50)) - voidProj.Position).Unit
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = projDir * 85
				bv.Parent = voidProj

				local hitDebounce = false
				voidProj.Touched:Connect(function(hit)
					if not hitDebounce and isValidMeteorCollision(hit) then
						hitDebounce = true
						CreateEffect("Sphere", CF(voidProj.Position), VT(6, 6, 6), VT(20, 20, 20), Color3.new(0.15, 0, 0.5), 0.5, nil, 1.5)
						ApplyAoE(voidProj.Position, 18, 160, 65)
						voidProj:Destroy()
					end
				end)

				Debris:AddItem(voidProj, 3.5)
			end

			ApplyAoE(tearPos, 35, 350, 120)
			Debris:AddItem(rift, 3)
			task.wait(0.7)
		end

		task.wait(2)

		-- ===== PHASE 12: ELEMENTAL CONVERGENCE =====
		CurrentFinalePhase = 12
		DisplayTaunt("ALL ELEMENTS UNITE IN DESTRUCTION!", 5, Color3.fromRGB(255, 128, 0))
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Elemental")
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.6, false, "Fire")
		CreatePositionalSound("ice_beam", ROOTPART.Position, 2.5, 0.7, false, "Ice")
		CreatePositionalSound("lightning_charge", ROOTPART.Position, 2.8, 0.8, false, "Lightning")

		-- Elemental chaos pre-spawn
		local elementColors = {
			{Color = Color3.new(1, 0.3, 0), Sound = "fire_whoosh"},  -- Fire
			{Color = Color3.new(0, 0.8, 1), Sound = "ice_beam"},     -- Ice
			{Color = Color3.new(1, 1, 0), Sound = "lightning_crack"}, -- Lightning
			{Color = Color3.new(0, 1, 1), Sound = "plasma_charge"}   -- Plasma
		}

		for elem = 1, 25 do
			local element = elementColors[MRANDOM(1, 4)]
			local elemPos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(15, 55), MRANDOM(-100, 100))
			CreateEffect("Sphere", CF(elemPos), VT(10, 10, 10), VT(35, 35, 35), element.Color, 0.7, nil, 2.2)
			CreatePositionalSound(element.Sound, elemPos, 1.5, MRANDOM(7, 12)/10, false, "Elemental chaos")
			ApplyAoE(elemPos, 25, 210, 80)
			task.wait(0.1)
		end

		-- Spawn Elemental Titans with massive effects
		for i = 1, 5 do  -- Increased from 3 to 5
			local spawnPos = ROOTPART.Position + VT(MRANDOM(-80, 80), 0, MRANDOM(-80, 80))
			local titanElement = elementColors[MRANDOM(1, 4)]

			-- Colossal spawn effect
			CreateEffect("Sphere", CF(spawnPos), VT(10, 10, 10), VT(45, 45, 45), titanElement.Color, 0.8, nil, 3)
			CreateEffect("Ring", CF(spawnPos) * ANGLES(RAD(90), 0, 0), VT(15, 15, 6), VT(60, 60, 6), titanElement.Color, 0.7, nil, 2.5)
			CreatePositionalSound("massive_explosion", spawnPos, 2.5, MRANDOM(6, 11)/10, false, "Titan spawn")
			CreatePositionalSound(titanElement.Sound, spawnPos, 2.2, MRANDOM(7, 12)/10, false, "Elemental spawn")
			CreatePositionalSound("intro_explosion", spawnPos, 2, MRANDOM(8, 13)/10, false, "Spawn boom")

			-- Elemental pillars rising around spawn
			for pillar = 1, 4 do
				local pillarAngle = pillar * 90
				local pillarDist = 25
				local pillarPos = spawnPos + VT(math.cos(RAD(pillarAngle)) * pillarDist, 0, math.sin(RAD(pillarAngle)) * pillarDist)
				local elemPillar = CreatePart(VT(8, 5, 8), CF(pillarPos), titanElement.Color, Enum.Material.Neon, 0.3, true)
				TweenService:Create(elemPillar, TweenInfo.new(1.5), {
					Size = VT(8, 60, 8),
					CFrame = CF(pillarPos) * CF(0, 30, 0)
				}):Play()
				CreatePositionalSound("energy_beam", pillarPos, 1.5, MRANDOM(8, 14)/10, false, "Pillar rise")
				Debris:AddItem(elemPillar, 15)
			end

			ApplyAoE(spawnPos, 30, 240, 95)
			spawnNPC("ElementalTitan", spawnPos)
			task.wait(0.8)
		end

		-- Multi-colored lighting
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.3, 0.2, 0.1),
			ColorShift_Top = Color3.new(0.8, 0.4, 0.2)
		}):Play()

		-- Elemental pillars (Fire, Ice, Lightning, Plasma)
		local elements = {
			{Color = Color3.new(1, 0.3, 0), Name = "Fire", Sound = "fire_whoosh"},
			{Color = Color3.new(0, 0.8, 1), Name = "Ice", Sound = "ice_beam"},
			{Color = Color3.new(1, 1, 0), Name = "Lightning", Sound = "lightning_crack"},
			{Color = Color3.new(0, 1, 1), Name = "Plasma", Sound = "plasma_charge"}
		}

		for pillar = 1, 24 do  -- Increased from 16 to 24
			local element = elements[((pillar - 1) % 4) + 1]
			local angle = pillar * 15
			local dist = 70
			local pillarPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * dist, 0, math.sin(RAD(angle)) * dist)

			local elemPillar = CreatePart(VT(15, 10, 15), CF(pillarPos), element.Color, Enum.Material.Neon, 0.3, true)
			TweenService:Create(elemPillar, TweenInfo.new(2), {
				Size = VT(15, 100, 15),
				CFrame = CF(pillarPos) * CF(0, 50, 0)
			}):Play()

			-- Enhanced effects at pillar tops
			CreateEffect("Sphere", CF(pillarPos + VT(0, 100, 0)), VT(12, 12, 12), VT(30, 30, 30), element.Color, 0.6, nil, 2)
			CreatePositionalSound(element.Sound, pillarPos, 2, MRANDOM(7, 13)/10, false, "Pillar " .. element.Name)
			CreatePositionalSound("explosion_impact", pillarPos, 1.5, MRANDOM(6, 11)/10, false, "Pillar impact")

			ApplyAoE(pillarPos, 22, 300, 100)
			Debris:AddItem(elemPillar, 20)

			task.wait(0.35)
		end

		-- Continuous elemental chaos
		coroutine.wrap(function()
			for chaos = 1, 40 do
				local element = elements[MRANDOM(1, 4)]
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-110, 110), MRANDOM(5, 45), MRANDOM(-110, 110))
				CreateEffect("Sphere", CF(chaosPos), VT(8, 8, 8), VT(25, 25, 25), element.Color, 0.6, nil, 1.8)
				CreatePositionalSound(element.Sound, chaosPos, 1.2, MRANDOM(8, 14)/10, false, "Elemental chaos")
				ApplyAoE(chaosPos, 20, 180, 70)
				task.wait(0.5)
			end
		end)()

		task.wait(10)

		-- ===== PHASE 13: SHADOW APOCALYPSE =====
		CurrentFinalePhase = 13
		DisplayTaunt("DARKNESS CONSUMES THE WORLD!", 5, Color3.fromRGB(20, 20, 20))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.2, false, "Shadows")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.3, false, "Shadow tear")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2.5, 0.4, false, "Time shadow")

		-- Shadow explosions before spawn
		for shadow = 1, 20 do
			local shadowPos = ROOTPART.Position + VT(MRANDOM(-105, 105), MRANDOM(10, 50), MRANDOM(-105, 105))
			CreateEffect("Sphere", CF(shadowPos), VT(12, 12, 12), VT(40, 40, 40), Color3.new(0.05, 0.05, 0.05), 0.8, nil, 2.5)
			CreateEffect("Ring", CF(shadowPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(15, 15, 5), VT(45, 45, 5), Color3.new(0.1, 0.1, 0.1), 0.7, nil, 2)
			CreatePositionalSound("dimensional_rift", shadowPos, 1.5, MRANDOM(4, 9)/10, false, "Shadow chaos")
			ApplyAoE(shadowPos, 28, 210, 80)
			task.wait(0.1)
		end

		-- Spawn Shadow Wraiths with ominous effects
		for i = 1, 9 do  -- Increased from 6 to 9
			local spawnPos = ROOTPART.Position + VT(MRANDOM(-90, 90), 0, MRANDOM(-90, 90))

			-- Dark spawn effect
			CreateEffect("Sphere", CF(spawnPos), VT(10, 10, 10), VT(40, 40, 40), Color3.new(0.08, 0.08, 0.08), 0.9, nil, 3)
			CreateEffect("Ring", CF(spawnPos) * ANGLES(RAD(90), 0, 0), VT(15, 15, 6), VT(55, 55, 6), Color3.new(0.15, 0.15, 0.15), 0.8, nil, 2.8)
			CreatePositionalSound("dimensional_rift", spawnPos, 2.5, MRANDOM(3, 7)/10, false, "Wraith spawn")
			CreatePositionalSound("reality_tear", spawnPos, 2, MRANDOM(4, 8)/10, false, "Shadow spawn")
			CreatePositionalSound("time_distortion", spawnPos, 1.8, MRANDOM(5, 9)/10, false, "Wraith distortion")

			-- Shadow tendrils spreading
			for tendril = 1, 6 do
				local tendrilAngle = tendril * 60
				local tendrilDir = VT(math.cos(RAD(tendrilAngle)), 0, math.sin(RAD(tendrilAngle)))
				for dist = 15, 45, 15 do
					local tendrilPos = spawnPos + tendrilDir * dist
					CreateEffect("Sphere", CF(tendrilPos), VT(6, 6, 6), VT(18, 18, 18), Color3.new(0.1, 0.1, 0.1), 0.6, nil, 1.5)
					ApplyAoE(tendrilPos, 15, 140, 55)
				end
			end

			-- Dark lightning
			for dark_lightning = 1, 4 do
				local lightningPos = spawnPos + VT(MRANDOM(-35, 35), 0, MRANDOM(-35, 35))
				CreateLightningBolt(spawnPos + VT(0, 50, 0), lightningPos, 12, Color3.new(0.15, 0.15, 0.15), 4, 0.3)
				CreatePositionalSound("lightning_crack", lightningPos, 1, MRANDOM(3, 8)/10, false, "Dark lightning")
			end

			ApplyAoE(spawnPos, 30, 220, 85)
			spawnNPC("ShadowWraith", spawnPos)
			task.wait(0.7)
		end

		-- Near-total darkness
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Brightness = 0,
			Ambient = Color3.new(0.02, 0.02, 0.02),
			ColorShift_Top = Color3.new(0, 0, 0),
			FogColor = Color3.new(0, 0, 0),
			FogEnd = 100
		}):Play()

		-- Life-drain aura with shadow chaos
		for drain = 1, 50 do
			for _, playerData in pairs(cachedPlayers) do
				if playerData.Humanoid and playerData.RootPart then
					local dist = (playerData.RootPart.Position - ROOTPART.Position).Magnitude
					if dist < 150 then
						ApplyDamage(playerData.Humanoid, 15, targetPlayer)

						-- Dark particle effect
						if MRANDOM(1, 3) == 1 then
							local darkParticle = CreatePart(VT(2, 2, 2), playerData.RootPart.CFrame, Color3.new(0.1, 0.1, 0.1), Enum.Material.Neon, 0.5, true)
							darkParticle.Shape = Enum.PartType.Ball
							TweenService:Create(darkParticle, TweenInfo.new(1), {
								CFrame = ROOTPART.CFrame,
								Transparency = 1
							}):Play()
							Debris:AddItem(darkParticle, 1)
						end
					end
				end
			end

			-- Shadow chaos effects
			if drain % 5 == 0 then
				local shadowChaosPos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(10, 50), MRANDOM(-100, 100))
				CreateEffect("Sphere", CF(shadowChaosPos), VT(10, 10, 10), VT(30, 30, 30), Color3.new(0.08, 0.08, 0.08), 0.7, nil, 2)
				CreatePositionalSound("dimensional_rift", shadowChaosPos, 1.2, MRANDOM(3, 7)/10, false, "Shadow drain")
				CreatePositionalSound("time_distortion", shadowChaosPos, 1, MRANDOM(4, 8)/10, false, "Life drain")
				ApplyAoE(shadowChaosPos, 22, 160, 65)
			end

			task.wait(0.4)
		end

		task.wait(2)

		-- ===== PHASE 14: COSMIC STORM =====
		CurrentFinalePhase = 14
		DisplayTaunt("THE COSMOS ATTACKS!", 5, Color3.fromRGB(100, 200, 255))
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.4, false, "Cosmic")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Cosmic plasma")
		CreatePositionalSound("energy_beam", ROOTPART.Position, 2.5, 0.6, false, "Cosmic energy")

		-- Cosmic chaos pre-spawn
		for cosmic = 1, 25 do
			local cosmicPos = ROOTPART.Position + VT(MRANDOM(-115, 115), MRANDOM(15, 60), MRANDOM(-115, 115))
			CreateEffect("Sphere", CF(cosmicPos), VT(12, 12, 12), VT(40, 40, 40), Color3.new(MRANDOM(3, 7)/10, MRANDOM(5, 9)/10, 1), 0.8, nil, 2.5)
			CreateEffect("Ring", CF(cosmicPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(15, 15, 5), VT(50, 50, 5), Color3.new(MRANDOM(4, 8)/10, MRANDOM(6, 10)/10, 1), 0.6, nil, 2)
			CreatePositionalSound("explosion_impact", cosmicPos, 1.5, MRANDOM(6, 11)/10, false, "Cosmic chaos")
			ApplyAoE(cosmicPos, 28, 220, 85)
			task.wait(0.12)
		end

		-- Spawn Cosmic Destroyers with spectacular effects
		for i = 1, 6 do  -- Increased from 4 to 6
			local spawnPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 0, MRANDOM(-100, 100))

			-- Cosmic spawn effect
			CreateEffect("Sphere", CF(spawnPos), VT(12, 12, 12), VT(50, 50, 50), Color3.fromRGB(100, 200, 255), 0.9, nil, 3.5)
			CreateEffect("Ring", CF(spawnPos) * ANGLES(RAD(90), 0, 0), VT(18, 18, 7), VT(65, 65, 7), Color3.fromRGB(150, 220, 255), 0.8, nil, 3)
			CreatePositionalSound("cosmic_ambient", spawnPos, 2.8, MRANDOM(7, 12)/10, false, "Destroyer spawn")
			CreatePositionalSound("plasma_charge", spawnPos, 2.5, MRANDOM(8, 13)/10, false, "Cosmic charge")
			CreatePositionalSound("massive_explosion", spawnPos, 2.2, MRANDOM(6, 11)/10, false, "Spawn explosion")
			CreatePositionalSound("intro_explosion", spawnPos, 2, MRANDOM(7, 12)/10, false, "Cosmic boom")

			-- Stellar energy beams from spawn
			for beam = 1, 6 do
				local beamAngle = beam * 60
				local beamLength = 40
				local beamEndPos = spawnPos + VT(math.cos(RAD(beamAngle)) * beamLength, 0, math.sin(RAD(beamAngle)) * beamLength)
				CreateLightningBolt(spawnPos + VT(0, 50, 0), beamEndPos, 15, Color3.new(MRANDOM(5, 9)/10, MRANDOM(7, 10)/10, 1), 5, 0.3)
				CreatePositionalSound("energy_beam", beamEndPos, 1.5, MRANDOM(9, 14)/10, false, "Cosmic beam")
				ApplyAoE(beamEndPos, 18, 180, 70)
			end

			ApplyAoE(spawnPos, 35, 250, 95)
			spawnNPC("CosmicDestroyer", spawnPos)
			task.wait(0.9)
		end

		-- Space-like lighting
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.1,
			Ambient = Color3.new(0.05, 0.1, 0.2),
			ColorShift_Top = Color3.new(0.1, 0.3, 0.6),
			FogEnd = 400
		}):Play()

		-- Asteroid bombardment with enhanced chaos
		for wave = 1, 7 do  -- Increased from 5 to 7
			for asteroid = 1, 12 do  -- Increased from 10 to 12
				local targetPos = ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120))
				local astSize = MRANDOM(10, 18)
				local ast = CreatePart(VT(astSize, astSize, astSize), CF(targetPos + VT(0, 150, 0)), 
					Color3.new(0.4, 0.35, 0.3), Enum.Material.Concrete, 0, false)
				ast.Shape = Enum.PartType.Ball

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = VT(0, -220, 0)
				bv.Parent = ast

				local hitDebounce = false
				ast.Touched:Connect(function(hit)
					if not hitDebounce and isValidMeteorCollision(hit) then
						hitDebounce = true
						CreateEffect("Sphere", CF(ast.Position), VT(astSize, astSize, astSize), VT(astSize*3, astSize*3, astSize*3), Color3.new(1, 0.5, 0), 1, nil, 3)
						CreatePositionalSound("massive_explosion", ast.Position, 2, MRANDOM(7, 12)/10, false, "Asteroid impact")
						CreatePositionalSound("explosion_impact", ast.Position, 1.8, MRANDOM(6, 11)/10, false, "Impact boom")
						ApplyAoE(ast.Position, astSize*2, 380, 150)
						ast:Destroy()
					end
				end)

				Debris:AddItem(ast, 3)
			end
			task.wait(1.8)
		end

		-- Solar flares with enhanced sounds
		for flare = 1, 12 do  -- Increased from 8 to 12
			local flareAngle = flare * 30
			local flareDir = VT(math.cos(RAD(flareAngle)), 0, math.sin(RAD(flareAngle)))

			CreatePositionalSound("fire_whoosh", ROOTPART.Position, 2, MRANDOM(6, 11)/10, false, "Solar flare")
			CreatePositionalSound("plasma_charge", ROOTPART.Position, 1.8, MRANDOM(7, 12)/10, false, "Solar plasma")

			for dist = 20, 140, 20 do
				local flarePos = ROOTPART.Position + flareDir * dist
				CreateEffect("Sphere", CF(flarePos), VT(20, 20, 20), VT(35, 35, 35), Color3.new(1, 0.8, 0), 0.8, nil, 2)
				CreatePositionalSound("explosion_impact", flarePos, 1.2, MRANDOM(8, 13)/10, false, "Flare hit")
				ApplyAoE(flarePos, 25, 320, 110)
				task.wait(0.1)
			end
		end

		task.wait(3)

		-- ===== PHASE 15: NEXUS ASCENSION =====
		CurrentFinalePhase = 15
		DisplayTaunt("I TRANSCEND ALL LIMITS!", 6, Color3.fromRGB(255, 255, 255))
		CreatePositionalSound("intro_buildup", ROOTPART.Position, 4, 0.3, false, "Ascension")
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3.5, 0.4, false, "Cosmic ascension")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Plasma ascension")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 2.8, 0.6, false, "Reality ascension")

		-- Ascension chaos explosions
		for ascend = 1, 30 do
			local ascendPos = ROOTPART.Position + VT(MRANDOM(-125, 125), MRANDOM(10, 70), MRANDOM(-125, 125))
			local ascendColor = Color3.new(MRANDOM(7, 10)/10, MRANDOM(7, 10)/10, MRANDOM(7, 10)/10)
			CreateEffect("Sphere", CF(ascendPos), VT(15, 15, 15), VT(50, 50, 50), ascendColor, 0.9, nil, 3)
			CreateEffect("Ring", CF(ascendPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(18, 18, 6), VT(60, 60, 6), ascendColor, 0.8, nil, 2.5)
			CreatePositionalSound("massive_explosion", ascendPos, 2, MRANDOM(6, 11)/10, false, "Ascension explosion")
			CreatePositionalSound("intro_explosion", ascendPos, 1.8, MRANDOM(7, 12)/10, false, "Ascension boom")
			ApplyAoE(ascendPos, 30, 250, 95)
			task.wait(0.1)
		end

		-- Spawn all NPC types with massive effects
		local npcTypes = {"DarkHerald", "VoidSentinel", "ElementalTitan", "ShadowWraith", "CosmicDestroyer"}
		for i = 1, 3 do  -- Increased from 2 to 3
			for _, npcType in ipairs(npcTypes) do
				local spawnPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 0, MRANDOM(-100, 100))

				-- Transcendent spawn effect
				CreateEffect("Sphere", CF(spawnPos), VT(15, 15, 15), VT(55, 55, 55), Color3.new(MRANDOM(8, 10)/10, MRANDOM(8, 10)/10, MRANDOM(8, 10)/10), 1, nil, 4)
				CreateEffect("Ring", CF(spawnPos) * ANGLES(RAD(90), 0, 0), VT(20, 20, 8), VT(70, 70, 8), Color3.new(1, 1, 1), 0.9, nil, 3.5)
				CreatePositionalSound("intro_buildup", spawnPos, 3, MRANDOM(5, 10)/10, false, "Transcendent spawn")
				CreatePositionalSound("massive_explosion", spawnPos, 2.5, MRANDOM(6, 11)/10, false, "Spawn massive")
				CreatePositionalSound("cosmic_ambient", spawnPos, 2.2, MRANDOM(7, 12)/10, false, "Cosmic spawn")
				CreatePositionalSound("dimensional_rift", spawnPos, 2, MRANDOM(8, 13)/10, false, "Rift spawn")

				-- Radial energy bursts
				for burst = 1, 8 do
					local burstAngle = burst * 45
					local burstDir = VT(math.cos(RAD(burstAngle)), 0, math.sin(RAD(burstAngle)))
					local burstPos = spawnPos + burstDir * 35
					CreateEffect("Sphere", CF(burstPos), VT(10, 10, 10), VT(25, 25, 25), Color3.new(1, 1, 1), 0.6, nil, 2)
					CreateLightningBolt(spawnPos + VT(0, 60, 0), burstPos, 18, Color3.new(1, 1, 1), 6, 0.3)
					CreatePositionalSound("energy_beam", burstPos, 1.5, MRANDOM(9, 14)/10, false, "Energy burst")
				end

				ApplyAoE(spawnPos, 40, 280, 110)
				spawnNPC(npcType, spawnPos)
				task.wait(0.5)
			end
		end

		-- Blinding light
		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 5,
			Ambient = Color3.new(1, 1, 1),
			ColorShift_Top = Color3.new(1, 1, 1)
		}):Play()

		-- Massive energy discharge with enhanced chaos
		for discharge = 1, 40 do  -- Increased from 30 to 40
			local disPos = ROOTPART.Position + VT(MRANDOM(-130, 130), MRANDOM(-20, 60), MRANDOM(-130, 130))
			CreateEffect("Sphere", CF(disPos), VT(15, 15, 15), VT(50, 50, 50), Color3.new(MRANDOM(8, 10)/10, MRANDOM(8, 10)/10, MRANDOM(8, 10)/10), 0.8, nil, 2.5)
			CreateEffect("Ring", CF(disPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
				VT(20, 20, 7), VT(65, 65, 7), Color3.new(1, 1, 1), 0.7, nil, 2.2)
			CreateLightningBolt(ROOTPART.Position + VT(0, 50, 0), disPos, 15, Color3.new(1, 1, 1), 5, 0.3)
			CreatePositionalSound("energy_beam", disPos, 2, MRANDOM(7, 12)/10, false, "Energy discharge")
			CreatePositionalSound("lightning_crack", disPos, 1.8, MRANDOM(8, 13)/10, false, "Lightning discharge")
			CreatePositionalSound("plasma_charge", disPos, 1.5, MRANDOM(6, 11)/10, false, "Plasma discharge")
			ApplyAoE(disPos, 30, 400, 140)
			task.wait(0.4)
		end

		-- Continuous chaos during ascension
		coroutine.wrap(function()
			for chaos = 1, 50 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(10, 55), MRANDOM(-120, 120))
				CreateEffect("Sphere", CF(chaosPos), VT(12, 12, 12), VT(35, 35, 35), Color3.new(MRANDOM(7, 10)/10, MRANDOM(7, 10)/10, MRANDOM(7, 10)/10), 0.7, nil, 2)
				CreatePositionalSound("explosion_impact", chaosPos, 1.5, MRANDOM(6, 11)/10, false, "Ascension chaos")
				ApplyAoE(chaosPos, 25, 200, 80)
				task.wait(0.4)
			end
		end)()

		task.wait(5)

		-- ===== PHASE 16-30: ENHANCED BOSS ATTACKS AT FINALE SCALE =====
		-- Phase 16: Apocalyptic Lightning Storm
		CurrentFinalePhase = 16
		DisplayTaunt("LIGHTNING BEYOND COMPREHENSION!", 5, Color3.fromRGB(255, 255, 0))
		CreatePositionalSound("lightning_charge", ROOTPART.Position, 3, 0.6, false, "Lightning storm charge")
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 3, 0.7, false, "Lightning storm")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.3, 0.3, 0),
			ColorShift_Top = Color3.new(1, 1, 0)
		}):Play()

		for strike = 1, 80 do  -- Increased from 60 to 80
			local targetPos = ROOTPART.Position + VT(MRANDOM(-140, 140), 0, MRANDOM(-140, 140))
			CreateLightningBolt(targetPos + VT(0, 200, 0), targetPos, 30, Color3.new(1, 1, 0.8), MRANDOM(6, 10), 0.35)
			CreateEffect("Sphere", CF(targetPos), VT(15, 15, 15), VT(45, 45, 45), Color3.new(1, 1, 0), 0.7, nil, 2)
			CreateEffect("Ring", CF(targetPos) * ANGLES(RAD(90), 0, 0), VT(18, 18, 5), VT(55, 55, 5), Color3.new(1, 1, 0.8), 0.6, nil, 1.8)
			CreatePositionalSound("lightning_crack", targetPos, 2, MRANDOM(7, 12)/10, false, "Lightning strike")
			CreatePositionalSound("explosion_impact", targetPos, 1.5, MRANDOM(6, 11)/10, false, "Lightning impact")
			ApplyAoE(targetPos, 30, 350, 130)
			task.wait(0.25)
		end

		-- Additional lightning chaos
		coroutine.wrap(function()
			for chaos = 1, 40 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(5, 45), MRANDOM(-120, 120))
				CreateEffect("Sphere", CF(chaosPos), VT(10, 10, 10), VT(30, 30, 30), Color3.new(1, 1, 0.7), 0.6, nil, 1.8)
				CreatePositionalSound("lightning_charge", chaosPos, 1.2, MRANDOM(8, 13)/10, false, "Lightning chaos")
				ApplyAoE(chaosPos, 22, 180, 70)
				task.wait(0.5)
			end
		end)()

		task.wait(3)

		-- Phase 17: Meteor Apocalypse
		CurrentFinalePhase = 17
		DisplayTaunt("METEORS RAIN ENDLESSLY!", 5, Color3.fromRGB(255, 100, 0))
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.5, false, "Meteor fire")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 3, 0.6, false, "Meteor apocalypse")
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 2.5, 0.4, false, "Meteor rain")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.4, 0.15, 0),
			ColorShift_Top = Color3.new(1, 0.4, 0)
		}):Play()

		for wave = 1, 12 do  -- Increased from 10 to 12
			for m = 1, 18 do  -- Increased from 15 to 18
				coroutine.wrap(function()
					local pos = ROOTPART.Position + VT(MRANDOM(-150, 150), 0, MRANDOM(-150, 150))
					local mSize = MRANDOM(18, 28)
					local meteor = CreatePart(VT(mSize, mSize, mSize), CF(pos + VT(0, 250, 0)), 
						Color3.new(0.35, 0.25, 0.15), Enum.Material.Concrete, 0, false)
					meteor.Shape = Enum.PartType.Ball

					local fireCore = CreatePart(VT(mSize*0.7, mSize*0.7, mSize*0.7), meteor.CFrame,
						Color3.new(1, MRANDOM(5, 8)/10, 0), Enum.Material.Neon, 0, false)
					fireCore.Shape = Enum.PartType.Ball

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = meteor
					weld.Part1 = fireCore
					weld.Parent = meteor

					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = VT(1e9, 1e9, 1e9)
					bv.Velocity = VT(0, -280, 0)
					bv.Parent = meteor

					local hitDebounce = false
					meteor.Touched:Connect(function(hit)
						if not hitDebounce and isValidMeteorCollision(hit) then
							hitDebounce = true
							CreateEffect("Sphere", CF(meteor.Position), VT(mSize, mSize, mSize), VT(mSize*4, mSize*4, mSize*4), Color3.new(1, 0.5, 0), 1.2, nil, 4)
							CreateEffect("Ring", CF(meteor.Position) * ANGLES(RAD(90), 0, 0), VT(mSize*2, mSize*2, 5), VT(mSize*6, mSize*6, 5), Color3.new(1, 0.6, 0), 1, nil, 3.5)
							CreatePositionalSound("massive_explosion", meteor.Position, 2.5, MRANDOM(6, 11)/10, false, "Meteor impact")
							CreatePositionalSound("explosion_impact", meteor.Position, 2.2, MRANDOM(7, 12)/10, false, "Meteor crash")
							CreatePositionalSound("fire_whoosh", meteor.Position, 2, MRANDOM(5, 10)/10, false, "Meteor fire")
							ApplyAoE(meteor.Position, mSize*2.5, 450, 180)
							meteor:Destroy()
							if fireCore.Parent then fireCore:Destroy() end
						end
					end)

					Debris:AddItem(meteor, 4)
					Debris:AddItem(fireCore, 4)
				end)()
			end
			task.wait(1.6)
		end

		-- Continuous meteor chaos
		coroutine.wrap(function()
			for chaos = 1, 60 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-130, 130), MRANDOM(10, 50), MRANDOM(-130, 130))
				CreateEffect("Sphere", CF(chaosPos), VT(12, 12, 12), VT(35, 35, 35), Color3.new(1, MRANDOM(4, 7)/10, 0), 0.7, nil, 2)
				CreatePositionalSound("fire_whoosh", chaosPos, 1.2, MRANDOM(6, 11)/10, false, "Meteor chaos")
				ApplyAoE(chaosPos, 25, 200, 80)
				task.wait(0.35)
			end
		end)()

		task.wait(3)

		-- Phase 18: Dimensional Chaos
		CurrentFinalePhase = 18
		DisplayTaunt("DIMENSIONS COLLIDE!", 5, Color3.fromRGB(100, 0, 200))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.4, false, "Dimensional chaos")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.5, false, "Dimension collision")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2.5, 0.6, false, "Time chaos")
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 2.2, 0.5, false, "Cosmic dimension")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.15, 0, 0.3),
			ColorShift_Top = Color3.new(0.4, 0, 0.8)
		}):Play()

		workspace.Gravity = 80

		-- Pre-rift chaos
		for pre_chaos = 1, 25 do
			local prePos = ROOTPART.Position + VT(MRANDOM(-110, 110), MRANDOM(15, 60), MRANDOM(-110, 110))
			CreateEffect("Sphere", CF(prePos), VT(12, 12, 12), VT(40, 40, 40), Color3.new(0.2, 0, 0.7), 0.8, nil, 2.5)
			CreatePositionalSound("reality_tear", prePos, 1.5, MRANDOM(6, 11)/10, false, "Pre-rift chaos")
			ApplyAoE(prePos, 28, 220, 85)
			task.wait(0.12)
		end

		for rift = 1, 25 do  -- Increased from 18 to 25
			local riftPos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(15, 50), MRANDOM(-100, 100))
			local dimRift = CreatePart(VT(25, 50, 8), CF(riftPos) * ANGLES(RAD(MRANDOM(-60, 60)), RAD(MRANDOM(-180, 180)), 0), 
				Color3.new(0.15, 0, 0.7), Enum.Material.ForceField, 0.2, true)

			CreatePositionalSound("dimensional_rift", riftPos, 2, MRANDOM(6, 12)/10, false, "Rift spawn")
			CreatePositionalSound("reality_tear", riftPos, 1.8, MRANDOM(7, 13)/10, false, "Rift tear")

			coroutine.wrap(function()
				for proj = 1, 18 do  -- Increased from 15 to 18
					local voidProj = CreatePart(VT(7, 7, 7), dimRift.CFrame, Color3.new(0.2, 0, 0.6), Enum.Material.Neon, 0, false)
					voidProj.Shape = Enum.PartType.Ball

					local dir = (ROOTPART.Position + VT(MRANDOM(-60, 60), 0, MRANDOM(-60, 60)) - voidProj.Position).Unit
					local bv = Instance.new("BodyVelocity")
					bv.MaxForce = VT(1e9, 1e9, 1e9)
					bv.Velocity = dir * 90
					bv.Parent = voidProj

					CreatePositionalSound("energy_beam", voidProj.Position, 1, MRANDOM(8, 14)/10, false, "Void projectile")

					local hitDebounce = false
					voidProj.Touched:Connect(function(hit)
						if not hitDebounce and isValidMeteorCollision(hit) then
							hitDebounce = true
							CreateEffect("Sphere", CF(voidProj.Position), VT(7, 7, 7), VT(30, 30, 30), Color3.new(0.2, 0, 0.6), 0.6, nil, 2)
							CreatePositionalSound("explosion_impact", voidProj.Position, 1.5, MRANDOM(7, 12)/10, false, "Void impact")
							ApplyAoE(voidProj.Position, 22, 280, 100)
							voidProj:Destroy()
						end
					end)

					Debris:AddItem(voidProj, 4)
					task.wait(0.13)
				end
			end)()

			Debris:AddItem(dimRift, 8)
		end

		-- Continuous dimensional chaos
		coroutine.wrap(function()
			for chaos = 1, 80 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(10, 55), MRANDOM(-120, 120))
				CreateEffect("Sphere", CF(chaosPos), VT(10, 10, 10), VT(30, 30, 30), Color3.new(0.2, 0, 0.6), 0.7, nil, 2)
				CreatePositionalSound("dimensional_rift", chaosPos, 1.2, MRANDOM(6, 11)/10, false, "Dimensional chaos")
				ApplyAoE(chaosPos, 22, 190, 75)
				task.wait(0.25)
			end
		end)()

		task.wait(20)

		-- Phase 19: Arcane Devastation Finale
		CurrentFinalePhase = 19
		DisplayTaunt("ARCANE ANNIHILATION!", 5, Color3.fromRGB(200, 0, 255))
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.5, false, "Arcane devastation")
		CreatePositionalSound("energy_beam", ROOTPART.Position, 3, 0.6, false, "Arcane power")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 2.5, 0.7, false, "Arcane charge")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.25, 0, 0.35),
			ColorShift_Top = Color3.new(0.6, 0, 0.9)
		}):Play()

		-- Massive arcane lasers with enhanced chaos
		for laser = 1, 16 do  -- Increased from 12 to 16
			local angle = laser * 22.5
			local beamPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * 100, 0, math.sin(RAD(angle)) * 100)

			local beam = CreatePart(VT(30, 250, 30), CF(beamPos + VT(0, 125, 0)), 
				Color3.new(1, 0.3, 1), Enum.Material.Neon, 0.15, true)
			beam.Shape = Enum.PartType.Cylinder

			CreatePositionalSound("energy_beam", beamPos, 3, MRANDOM(6, 11)/10, false, "Arcane laser")
			CreatePositionalSound("plasma_charge", beamPos, 2.5, MRANDOM(7, 12)/10, false, "Arcane plasma")
			CreatePositionalSound("reality_tear", beamPos, 2, MRANDOM(8, 13)/10, false, "Arcane tear")

			for explosion = 1, 10 do  -- Increased from 8 to 10
				local expPos = beamPos + VT(MRANDOM(-20, 20), 0, MRANDOM(-20, 20))
				CreateEffect("Sphere", CF(expPos), VT(25, 25, 25), VT(80, 80, 80), Color3.new(1, 0.3, 1), 0.9, nil, 3)
				CreateEffect("Ring", CF(expPos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
					VT(30, 30, 8), VT(90, 90, 8), Color3.new(1, 0.4, 1), 0.8, nil, 2.8)
				CreatePositionalSound("massive_explosion", expPos, 2, MRANDOM(6, 11)/10, false, "Arcane explosion")
				ApplyAoE(expPos, 40, 360, 120)
			end

			Debris:AddItem(beam, 3)
			task.wait(1.2)
		end

		-- Continuous arcane chaos
		coroutine.wrap(function()
			for chaos = 1, 50 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-115, 115), MRANDOM(10, 50), MRANDOM(-115, 115))
				CreateEffect("Sphere", CF(chaosPos), VT(12, 12, 12), VT(35, 35, 35), Color3.new(1, MRANDOM(2, 5)/10, 1), 0.7, nil, 2)
				CreatePositionalSound("reality_tear", chaosPos, 1.2, MRANDOM(7, 12)/10, false, "Arcane chaos")
				ApplyAoE(chaosPos, 25, 200, 80)
				task.wait(0.4)
			end
		end)()

		task.wait(3)

		-- Phase 20: Inferno Finale
		CurrentFinalePhase = 20
		DisplayTaunt("BURN IN ETERNAL FLAMES!", 5, Color3.fromRGB(255, 50, 0))
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3.5, 0.4, false, "Inferno")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 3, 0.5, false, "Inferno explosion")
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 2.5, 0.6, false, "Inferno massive")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.5, 0.15, 0),
			ColorShift_Top = Color3.new(1, 0.4, 0)
		}):Play()

		-- Massive fire tornadoes with enhanced chaos
		for tornado = 1, 15 do  -- Increased from 10 to 15
			local torPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 0, MRANDOM(-100, 100))

			CreatePositionalSound("fire_whoosh", torPos, 2.5, MRANDOM(5, 10)/10, false, "Fire tornado")
			CreatePositionalSound("explosion_impact", torPos, 2, MRANDOM(6, 11)/10, false, "Tornado impact")

			for segment = 1, 25 do
				local fire = CreatePart(VT(25 - segment*0.7, 12, 25 - segment*0.7), 
					CF(torPos) * CF(0, segment*8, 0) * ANGLES(0, RAD(segment*20), 0), 
					Color3.new(1, MRANDOM(2, 6)/10, 0), Enum.Material.Neon, 0.3, true)
				fire.Shape = Enum.PartType.Cylinder
				TweenService:Create(fire, TweenInfo.new(4), {Transparency = 1}):Play()
				Debris:AddItem(fire, 4)
			end

			CreateEffect("Sphere", CF(torPos), VT(15, 15, 15), VT(50, 50, 50), Color3.new(1, 0.5, 0), 0.7, nil, 2.5)
			ApplyAoE(torPos, 40, 380, 120)
		end

		-- Continuous inferno chaos
		coroutine.wrap(function()
			for chaos = 1, 70 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-120, 120), MRANDOM(5, 50), MRANDOM(-120, 120))
				CreateEffect("Sphere", CF(chaosPos), VT(12, 12, 12), VT(35, 35, 35), Color3.new(1, MRANDOM(3, 7)/10, 0), 0.7, nil, 2)
				CreatePositionalSound("fire_whoosh", chaosPos, 1.2, MRANDOM(6, 11)/10, false, "Inferno chaos")
				ApplyAoE(chaosPos, 25, 210, 85)
				task.wait(0.3)
			end
		end)()

		task.wait(18)

		-- Phase 21: Cosmic Annihilation Finale
		CurrentFinalePhase = 21
		DisplayTaunt("THE UNIVERSE ITSELF ATTACKS!", 5, Color3.fromRGB(150, 100, 255))
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3.5, 0.4, false, "Cosmic annihilation")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Cosmic plasma")
		CreatePositionalSound("energy_beam", ROOTPART.Position, 2.5, 0.6, false, "Cosmic energy")
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 2.2, 0.7, false, "Cosmic rift")

		-- Create multiple cosmic cores
		for core = 1, 9 do  -- Increased from 6 to 9
			local corePos = ROOTPART.Position + VT(MRANDOM(-80, 80), 40, MRANDOM(-80, 80))
			local cosmicCore = CreatePart(VT(35, 35, 35), CF(corePos), Color3.new(0.5, 0.2, 1), Enum.Material.Neon, 0, true)
			cosmicCore.Shape = Enum.PartType.Ball

			CreatePositionalSound("cosmic_ambient", corePos, 2.5, MRANDOM(6, 11)/10, false, "Cosmic core")
			CreatePositionalSound("intro_explosion", corePos, 2, MRANDOM(7, 12)/10, false, "Core spawn")
			CreateEffect("Sphere", CF(corePos), VT(35, 35, 35), VT(70, 70, 70), Color3.new(0.5, 0.2, 1), 0.8, nil, 3)

			-- Cosmic energy bursts
			coroutine.wrap(function()
				for burst = 1, 20 do  -- Increased from 15 to 20
					local burstAngle = burst * 18
					for b = 1, 6 do  -- Increased from 5 to 6
						local boltPos = corePos + VT(math.cos(RAD(burstAngle + b*60)) * 80, 0, math.sin(RAD(burstAngle + b*60)) * 80)
						CreateLightningBolt(corePos, boltPos, 20, Color3.new(0.6, 0.3, 1), 6, 0.4)
						CreateEffect("Sphere", CF(boltPos), VT(12, 12, 12), VT(30, 30, 30), Color3.new(0.6, 0.3, 1), 0.6, nil, 1.8)
						CreatePositionalSound("lightning_crack", boltPos, 1.5, MRANDOM(7, 12)/10, false, "Cosmic bolt")
						CreatePositionalSound("energy_beam", boltPos, 1.2, MRANDOM(8, 13)/10, false, "Cosmic beam")
						ApplyAoE(boltPos, 25, 340, 110)
					end
					task.wait(0.5)
				end
			end)()

			Debris:AddItem(cosmicCore, 18)
		end

		-- Continuous cosmic chaos
		coroutine.wrap(function()
			for chaos = 1, 90 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-125, 125), MRANDOM(10, 60), MRANDOM(-125, 125))
				CreateEffect("Sphere", CF(chaosPos), VT(15, 15, 15), VT(40, 40, 40), Color3.new(MRANDOM(4, 7)/10, MRANDOM(2, 5)/10, 1), 0.8, nil, 2.2)
				CreatePositionalSound("cosmic_ambient", chaosPos, 1.2, MRANDOM(6, 11)/10, false, "Cosmic chaos")
				ApplyAoE(chaosPos, 28, 220, 90)
				task.wait(0.2)
			end
		end)()

		task.wait(18)

		-- Phase 22: Quantum Slice Finale
		CurrentFinalePhase = 22
		DisplayTaunt("QUANTUM BLADES TEAR REALITY!", 5, Color3.fromRGB(0, 255, 100))
		CreatePositionalSound("energy_beam", ROOTPART.Position, 3.5, 0.5, false, "Quantum slice")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.6, false, "Quantum reality")
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2.5, 0.7, false, "Quantum time")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0, 0.3, 0.2),
			ColorShift_Top = Color3.new(0, 0.8, 0.4)
		}):Play()

		-- Massive quantum blades with enhanced chaos
		for slice = 1, 80 do  -- Increased from 60 to 80
			local sliceAngle = slice * 4.5
			local blade = CreatePart(VT(6, 150, 6), ROOTPART.CFrame * CF(0, 75, 0) * ANGLES(0, RAD(sliceAngle), RAD(70)), 
				Color3.new(0, 1, MRANDOM(3, 8)/10), Enum.Material.Neon, 0.2, true)

			-- Giant slash trail
			local trail = CreatePart(VT(10, 150, 220), blade.CFrame * CF(0, 0, -110), 
				Color3.new(0, 1, MRANDOM(3, 8)/10), Enum.Material.Neon, 0.3, true)

			CreatePositionalSound("energy_beam", ROOTPART.Position, 2, MRANDOM(7, 12)/10, false, "Quantum blade")
			CreatePositionalSound("reality_tear", ROOTPART.Position, 1.5, MRANDOM(8, 13)/10, false, "Quantum slash")

			TweenService:Create(trail, TweenInfo.new(1), {Transparency = 1}):Play()
			Debris:AddItem(trail, 1)
			Debris:AddItem(blade, 1)

			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(90), 0, 0), VT(80, 80, 10), VT(180, 180, 10), Color3.new(0, 1, 0.7), 0.5, nil, 1.5)
			ApplyAoE(ROOTPART.Position, 120, 320, 100)
			task.wait(0.25)
		end

		-- Continuous quantum chaos
		coroutine.wrap(function()
			for chaos = 1, 80 do
				local chaosPos = ROOTPART.Position + VT(MRANDOM(-130, 130), MRANDOM(5, 55), MRANDOM(-130, 130))
				CreateEffect("Sphere", CF(chaosPos), VT(12, 12, 12), VT(35, 35, 35), Color3.new(0, 1, MRANDOM(4, 8)/10), 0.7, nil, 2)
				CreatePositionalSound("time_distortion", chaosPos, 1.2, MRANDOM(6, 11)/10, false, "Quantum chaos")
				ApplyAoE(chaosPos, 25, 210, 85)
				task.wait(0.25)
			end
		end)()

		task.wait(3)

		-- Phase 23: Plasma Nova Finale - Enhanced with vortex and chain reactions
		CurrentFinalePhase = 23
		DisplayTaunt("PLASMA VORTEX CONVERGENCE!", 5, Color3.fromRGB(0, 255, 255))
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.5, false, "Plasma charge")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0, 0.25, 0.35),
			ColorShift_Top = Color3.new(0, 0.6, 1)
		}):Play()

		-- Create plasma vortex core
		local vortexCore = CreatePart(VT(40, 40, 40), CF(ROOTPART.Position + VT(0, 50, 0)), Color3.new(0, 1, 1), Enum.Material.Neon, 0, true)
		vortexCore.Shape = Enum.PartType.Ball

		-- Spinning plasma orbs
		coroutine.wrap(function()
			for orb = 1, 20 do
				local angle = orb * 18
				local radius = 60
				local orbPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * radius, 30 + math.sin(RAD(angle * 2)) * 20, math.sin(RAD(angle)) * radius)
				local plasmaOrb = CreatePart(VT(12, 12, 12), CF(orbPos), Color3.new(0.2, 0.9, 1), Enum.Material.Neon, 0, false)
				plasmaOrb.Shape = Enum.PartType.Ball

				local light = Instance.new("PointLight")
				light.Brightness = 20
				light.Color = Color3.new(0, 1, 1)
				light.Range = 30
				light.Parent = plasmaOrb

				-- Orbit animation
				local startTime = tick()
				coroutine.wrap(function()
					while plasmaOrb.Parent do
						local elapsed = tick() - startTime
						local newAngle = angle + elapsed * 60
						local newPos = ROOTPART.Position + VT(math.cos(RAD(newAngle)) * radius, 30 + math.sin(RAD(newAngle * 2)) * 20, math.sin(RAD(newAngle)) * radius)
						plasmaOrb.CFrame = CF(newPos)
						task.wait()
					end
				end)()

				-- Explode after delay
				task.wait(MRANDOM(3, 6))
				if plasmaOrb.Parent then
					CreatePositionalSound("explosion_impact", plasmaOrb.Position, 2, MRANDOM(7, 12)/10, false, "Plasma explosion")
					CreateEffect("Sphere", CF(plasmaOrb.Position), VT(12, 12, 12), VT(55, 55, 55), Color3.new(0.2, 0.9, 1), 0.9, "explosion_impact", 3.5)
					CreateEffect("Ring", CF(plasmaOrb.Position) * ANGLES(RAD(90), 0, 0), VT(20, 20, 5), VT(70, 70, 5), Color3.new(0, 1, 1), 0.8, "energy_beam", 2)
					ApplyAoE(plasmaOrb.Position, 38, 350, 120)
					plasmaOrb:Destroy()
				end
				task.wait(0.3)
			end
		end)()

		-- Plasma chain lightning between orbs
		coroutine.wrap(function()
			for chain = 1, 15 do
				local startPos = ROOTPART.Position + VT(MRANDOM(-80, 80), 0, MRANDOM(-80, 80))
				local endPos = ROOTPART.Position + VT(MRANDOM(-80, 80), 0, MRANDOM(-80, 80))
				CreateLightningBolt(startPos, endPos, 25, Color3.new(0, 1, 1), 8, 0.3)
				CreatePositionalSound("lightning_crack", (startPos + endPos) / 2, 1.5, MRANDOM(8, 12)/10, false, "Plasma lightning")
				ApplyAoE((startPos + endPos) / 2, 30, 320, 110)
				task.wait(0.5)
			end
		end)()

		Debris:AddItem(vortexCore, 20)
		task.wait(18)

		-- Phase 24: Cryo Blast Finale - Enhanced with ice crystals and freezing waves
		CurrentFinalePhase = 24
		DisplayTaunt("GLACIAL STORM DESCENDS!", 5, Color3.fromRGB(100, 200, 255))
		CreatePositionalSound("ice_beam", ROOTPART.Position, 3, 0.6, false, "Ice charge")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0, 0.2, 0.4),
			ColorShift_Top = Color3.new(0.2, 0.6, 1)
		}):Play()

		-- Create massive ice crystal above
		local iceCrystal = CreatePart(VT(50, 80, 50), CF(ROOTPART.Position + VT(0, 100, 0)), Color3.new(0.7, 0.9, 1), Enum.Material.Neon, 0.3, true)
		iceCrystal.Shape = Enum.PartType.Cylinder

		-- Spinning ice shards
		coroutine.wrap(function()
			for shard = 1, 30 do
				local angle = shard * 12
				local radius = 100
				local shardPos = ROOTPART.Position + VT(math.cos(RAD(angle)) * radius, 50, math.sin(RAD(angle)) * radius)
				local iceShard = CreatePart(VT(8, 25, 8), CF(shardPos) * ANGLES(RAD(90), 0, 0), Color3.new(0.5, 0.9, 1), Enum.Material.Neon, 0.2, false)
				iceShard.Shape = Enum.PartType.Cylinder

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = VT(0, -80, 0)
				bv.Parent = iceShard

				local hitDebounce = false
				iceShard.Touched:Connect(function(hit)
					if not hitDebounce and hit.Parent ~= CHARACTER then
						hitDebounce = true
						CreatePositionalSound("ice_beam", iceShard.Position, 1.5, MRANDOM(7, 11)/10, false, "Ice shard impact")
						CreateEffect("Sphere", CF(iceShard.Position), VT(8, 8, 8), VT(35, 35, 35), Color3.new(0.5, 0.9, 1), 0.6, "ice_beam", 2)
						ApplyAoE(iceShard.Position, 25, 300, 100)
						iceShard:Destroy()
					end
				end)
				Debris:AddItem(iceShard, 5)
				task.wait(0.2)
			end
		end)()

		-- Freezing wave rings
		for wave = 1, 5 do
			local waveRadius = wave * 40
			for segment = 1, 24 do
				local angle = segment * 15
				local wavePos = ROOTPART.Position + VT(math.cos(RAD(angle)) * waveRadius, 0, math.sin(RAD(angle)) * waveRadius)
				CreateEffect("Ring", CF(wavePos) * ANGLES(RAD(90), 0, 0), VT(20, 1, 20), VT(60, 1, 60), Color3.new(0.4, 0.8, 1), 0.8, "ice_beam", 2)
				ApplyAoE(wavePos, 30, 320, 105)
			end
			CreatePositionalSound("ice_beam", ROOTPART.Position, 2, MRANDOM(6, 9)/10, false, "Freezing wave")
			task.wait(0.8)
		end

		Debris:AddItem(iceCrystal, 12)
		task.wait(6)

		-- Phase 25: Gravity Collapse Finale - Enhanced with black hole and gravitational anomalies
		CurrentFinalePhase = 25
		DisplayTaunt("GRAVITATIONAL SINGULARITY FORMS!", 5, Color3.fromRGB(80, 0, 120))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.5, false, "Gravity collapse")

		-- Create black hole core
		local blackHole = CreatePart(VT(30, 30, 30), CF(ROOTPART.Position + VT(0, 20, 0)), Color3.new(0.05, 0, 0.1), Enum.Material.Neon, 0, true)
		blackHole.Shape = Enum.PartType.Ball

		local holeLight = Instance.new("PointLight")
		holeLight.Brightness = 5
		holeLight.Color = Color3.new(0.3, 0, 0.6)
		holeLight.Range = 50
		holeLight.Parent = blackHole

		-- Gravity pull effect
		coroutine.wrap(function()
			for pull = 1, 20 do
				workspace.Gravity = 100 + pull * 10

				-- Pull players toward black hole
				for _, playerData in pairs(cachedPlayers) do
					if playerData.RootPart then
						local direction = (blackHole.Position - playerData.RootPart.Position).Unit
						local bv = playerData.RootPart:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = direction * (30 + pull * 2)
						bv.Parent = playerData.RootPart

						if playerData.Humanoid then
							ApplyDamage(playerData.Humanoid, 20 + pull, targetPlayer)
						end
					end
				end

				-- Gravity ripple effects
				CreateEffect("Ring", blackHole.CFrame * ANGLES(RAD(90), 0, 0), VT(30 + pull*5, 1, 30 + pull*5), VT(100 + pull*10, 1, 100 + pull*10), Color3.new(0.2, 0, 0.5), 0.8, "dimensional_rift", 2)

				task.wait(0.4)
			end
		end)()

		-- Gravitational anomalies spawn around
		coroutine.wrap(function()
			for anomaly = 1, 15 do
				local anomPos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(10, 60), MRANDOM(-100, 100))
				local anom = CreatePart(VT(15, 15, 15), CF(anomPos), Color3.new(0.3, 0, 0.6), Enum.Material.Neon, 0.3, true)
				anom.Shape = Enum.PartType.Ball

				-- Pulse effect
				TweenService:Create(anom, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = VT(25, 25, 25)}):Play()
				task.wait(1)
				if anom.Parent then
					CreatePositionalSound("explosion_impact", anom.Position, 1.5, MRANDOM(7, 11)/10, false, "Anomaly collapse")
					CreateEffect("Sphere", anom.CFrame, VT(15, 15, 15), VT(50, 50, 50), Color3.new(0.3, 0, 0.6), 0.6, "explosion_impact", 2)
					ApplyAoE(anom.Position, 30, 340, 110)
					anom:Destroy()
				end
				task.wait(0.5)
			end
		end)()

		Debris:AddItem(blackHole, 25)
		task.wait(20)

		-- Phase 26: Reality Shatter Finale - Enhanced with dimensional fractures and chaos
		CurrentFinalePhase = 26
		DisplayTaunt("REALITY FRACTURES INTO NOTHING!", 5, Color3.fromRGB(255, 0, 200))
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3, 0.7, false, "Reality shatter")

		-- Everything glitches
		for glitch = 1, 40 do
			TweenService:Create(Lighting, TweenInfo.new(0.2), {
				Ambient = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10),
				ColorShift_Top = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10),
				Brightness = MRANDOM(0, 50)/10
			}):Play()

			workspace.Gravity = MRANDOM(0, 250)

			-- Reality tears everywhere with sounds
			for tear = 1, 5 do
				local tearPos = ROOTPART.Position + VT(MRANDOM(-150, 150), MRANDOM(-20, 60), MRANDOM(-150, 150))
				local realityTear = CreatePart(VT(30, 60, 6), CF(tearPos) * ANGLES(RAD(MRANDOM(-90, 90)), RAD(MRANDOM(-180, 180)), 0), 
					Color3.new(MRANDOM(0, 10)/10, 0, MRANDOM(5, 10)/10), Enum.Material.ForceField, 0.1, true)

				if glitch % 3 == 0 then
					CreatePositionalSound("dimensional_rift", tearPos, 1.5, MRANDOM(6, 10)/10, false, "Reality tear")
				end
				CreateEffect("Ring", CF(tearPos) * ANGLES(RAD(90), 0, 0), VT(20, 20, 5), VT(70, 70, 5), Color3.new(MRANDOM(5, 10)/10, 0, MRANDOM(5, 10)/10), 1.2, "dimensional_rift", 2)
				ApplyAoE(tearPos, 45, 400, 150)
				Debris:AddItem(realityTear, 1.5)
			end

			task.wait(0.4)
		end

		task.wait(3)

		-- Phase 27: Solar Flare Finale - Enhanced with solar core and expanding flares
		CurrentFinalePhase = 27
		DisplayTaunt("SOLAR CORE IGNITION!", 5, Color3.fromRGB(255, 200, 0))
		CreatePositionalSound("intro_buildup", ROOTPART.Position, 3, 0.4, false, "Solar charge")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 8,
			Ambient = Color3.new(1, 0.8, 0.3),
			ColorShift_Top = Color3.new(1, 0.7, 0)
		}):Play()

		-- Create massive solar core
		local solarCore = CreatePart(VT(60, 60, 60), CF(ROOTPART.Position + VT(0, 80, 0)), Color3.new(1, 0.9, 0.3), Enum.Material.Neon, 0, true)
		solarCore.Shape = Enum.PartType.Ball

		local coreLight = Instance.new("PointLight")
		coreLight.Brightness = 30
		coreLight.Color = Color3.new(1, 0.8, 0.2)
		coreLight.Range = 200
		coreLight.Parent = solarCore

		-- Pulsing core
		coroutine.wrap(function()
			while solarCore.Parent do
				TweenService:Create(solarCore, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = VT(70, 70, 70)}):Play()
				task.wait(1)
				if solarCore.Parent then
					TweenService:Create(solarCore, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = VT(60, 60, 60)}):Play()
				end
				task.wait(1)
			end
		end)()

		-- Expanding solar flare waves
		for wave = 1, 6 do
			CreatePositionalSound("fire_whoosh", ROOTPART.Position, 2.5, MRANDOM(5, 8)/10, false, "Solar flare wave")
			for segment = 1, 32 do
				local angle = segment * 11.25
				local radius = wave * 35
				local flarePos = ROOTPART.Position + VT(math.cos(RAD(angle)) * radius, 0, math.sin(RAD(angle)) * radius)
				CreateEffect("Sphere", CF(flarePos), VT(20 + wave*3, 20 + wave*3, 20 + wave*3), VT(50 + wave*5, 50 + wave*5, 50 + wave*5), Color3.new(1, 0.8, 0.2), 1, "fire_whoosh", 2.5)
				CreateEffect("Ring", CF(flarePos) * ANGLES(RAD(90), 0, 0), VT(15, 15, 5), VT(60, 60, 5), Color3.new(1, 0.6, 0), 0.8, "explosion_impact", 2)
				ApplyAoE(flarePos, 35, 380, 130)
			end
			task.wait(0.6)
		end

		-- Final core explosion
		task.wait(2)
		CreatePositionalSound("massive_explosion", solarCore.Position, 5, 0.3, false, "Solar core explosion")
		CreateEffect("Sphere", solarCore.CFrame, VT(60, 60, 60), VT(200, 200, 200), Color3.new(1, 0.9, 0.3), 2, "massive_explosion", 8)
		for ring = 1, 8 do
			CreateEffect("Ring", solarCore.CFrame * ANGLES(RAD(90), RAD(ring*45), 0), VT(50, 50, 5), VT(250 + ring*30, 250 + ring*30, 5), Color3.new(1, 0.7, 0), 1.5, "massive_explosion", 5)
		end
		ApplyAoE(solarCore.Position, 120, 500, 200)

		Debris:AddItem(solarCore, 5)
		task.wait(4)

		-- Phase 28: Volcanic Eruption Finale - Enhanced with magma chambers and lava flows
		CurrentFinalePhase = 28
		DisplayTaunt("MAGMA CHAMBERS ERUPT!", 5, Color3.fromRGB(200, 50, 0))
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 3, 0.5, false, "Volcanic eruption")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Ambient = Color3.new(0.4, 0.1, 0),
			ColorShift_Top = Color3.new(0.9, 0.2, 0),
			FogColor = Color3.new(0.3, 0.1, 0)
		}):Play()

		-- Create magma chambers
		local chambers = {}
		for chamber = 1, 8 do
			local chamberPos = ROOTPART.Position + VT(MRANDOM(-120, 120), -20, MRANDOM(-120, 120))
			local chamber = CreatePart(VT(40, 40, 40), CF(chamberPos), Color3.new(0.8, 0.2, 0), Enum.Material.Neon, 0.5, true)
			chamber.Shape = Enum.PartType.Ball
			table.insert(chambers, {Part = chamber, Pos = chamberPos})
		end

		-- Eruptions from chambers
		coroutine.wrap(function()
			for eruption = 1, 30 do
				local chamber = chambers[MRANDOM(1, #chambers)]
				if chamber and chamber.Part.Parent then
					local eruptPos = chamber.Pos

					-- Lava pillar eruption
					CreatePositionalSound("explosion_impact", eruptPos, 2, MRANDOM(6, 10)/10, false, "Lava eruption")
					local lavaPillar = CreatePart(VT(30, 15, 30), CF(eruptPos), Color3.new(1, 0.3, 0), Enum.Material.Neon, 0.2, true)
					TweenService:Create(lavaPillar, TweenInfo.new(2.5), {
						Size = VT(30, 200, 30),
						CFrame = CF(eruptPos) * CF(0, 100, 0)
					}):Play()

					-- Lava bombs
					for bomb = 1, 15 do
						local lavaDir = VT(MRANDOM(-100, 100)/10, MRANDOM(80, 150)/10, MRANDOM(-100, 100)/10)
						local lavaBomb = CreatePart(VT(12, 12, 12), CF(eruptPos), Color3.new(1, 0.4, 0), Enum.Material.Neon, 0, false)
						lavaBomb.Shape = Enum.PartType.Ball

						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = lavaDir * 55
						bv.Parent = lavaBomb

						local hitDebounce = false
						lavaBomb.Touched:Connect(function(hit)
							if not hitDebounce and isValidMeteorCollision(hit) then
								hitDebounce = true
								CreatePositionalSound("explosion_impact", lavaBomb.Position, 1.5, MRANDOM(7, 11)/10, false, "Lava bomb impact")
								CreateEffect("Sphere", CF(lavaBomb.Position), VT(12, 12, 12), VT(45, 45, 45), Color3.new(1, 0.4, 0), 1, "explosion_impact", 3)
								ApplyAoE(lavaBomb.Position, 30, 360, 120)
								lavaBomb:Destroy()
							end
						end)
						Debris:AddItem(lavaBomb, 4)
					end

					CreateEffect("Ring", CF(eruptPos) * ANGLES(RAD(90), 0, 0), VT(25, 25, 5), VT(80, 80, 5), Color3.new(1, 0.5, 0), 1.2, "explosion_impact", 2.5)
					ApplyAoE(eruptPos, 40, 380, 130)
					Debris:AddItem(lavaPillar, 15)
				end
				task.wait(0.6)
			end
		end)()

		-- Cleanup chambers
		task.wait(20)
		for _, chamber in ipairs(chambers) do
			if chamber.Part.Parent then
				chamber.Part:Destroy()
			end
		end
		task.wait(2)

		-- Phase 29: Antimatter Annihilation Finale - Enhanced with cascading annihilation
		CurrentFinalePhase = 29
		DisplayTaunt("ANTIMATTER CASCADE BEGINNING!", 6, Color3.fromRGB(200, 255, 255))
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.4, false, "Antimatter charge")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.2,
			Ambient = Color3.new(0.2, 0.4, 0.4),
			ColorShift_Top = Color3.new(0.4, 0.8, 0.8)
		}):Play()

		-- Antimatter spheres that cascade explode
		coroutine.wrap(function()
			for sphere = 1, 25 do
				local spherePos = ROOTPART.Position + VT(MRANDOM(-140, 140), MRANDOM(20, 80), MRANDOM(-140, 140))
				local antiSphere = CreatePart(VT(20, 20, 20), CF(spherePos), Color3.new(0.5, 1, 1), Enum.Material.Neon, 0, true)
				antiSphere.Shape = Enum.PartType.Ball

				local light = Instance.new("PointLight")
				light.Brightness = 25
				light.Color = Color3.new(0.6, 1, 1)
				light.Range = 40
				light.Parent = antiSphere

				-- Grow then explode
				CreatePositionalSound("plasma_charge", spherePos, 1.5, MRANDOM(5, 8)/10, false, "Antimatter charge")
				TweenService:Create(antiSphere, TweenInfo.new(2.5), {Size = VT(55, 55, 55)}):Play()
				task.wait(2.5)

				-- Massive antimatter explosion with sounds
				CreatePositionalSound("massive_explosion", spherePos, 4, MRANDOM(4, 7)/10, false, "Antimatter explosion")
				CreateEffect("Sphere", antiSphere.CFrame, VT(55, 55, 55), VT(160, 160, 160), Color3.new(0.7, 1, 1), 2, "massive_explosion", 8)
				for ring = 1, 8 do
					CreateEffect("Ring", antiSphere.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
						VT(45, 45, 10), VT(130 + ring*35, 130 + ring*35, 10), Color3.new(0.5, 1, 1), 1.5, "explosion_impact", 6)
				end

				-- Chain reaction - spawn smaller spheres
				for chain = 1, 3 do
					local chainPos = spherePos + VT(MRANDOM(-40, 40), 0, MRANDOM(-40, 40))
					local chainSphere = CreatePart(VT(10, 10, 10), CF(chainPos), Color3.new(0.6, 1, 1), Enum.Material.Neon, 0, false)
					chainSphere.Shape = Enum.PartType.Ball

					task.wait(0.5)
					if chainSphere.Parent then
						CreatePositionalSound("explosion_impact", chainPos, 2, MRANDOM(7, 11)/10, false, "Chain reaction")
						CreateEffect("Sphere", CF(chainPos), VT(10, 10, 10), VT(40, 40, 40), Color3.new(0.6, 1, 1), 1, "explosion_impact", 3)
						ApplyAoE(chainPos, 25, 350, 120)
						chainSphere:Destroy()
					end
				end

				ApplyAoE(spherePos, 85, 600, 250)
				antiSphere:Destroy()
				task.wait(0.3)
			end
		end)()

		task.wait(25)

		-- Phase 30: GRAVITY NEXUS - Black hole and gravitational chaos
		CurrentFinalePhase = 30
		DisplayTaunt("GRAVITY NEXUS ACTIVATED! REALITY COLLAPSES!", 6, Color3.fromRGB(100, 0, 100))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 4, 0.3, false, "Gravity nexus")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 3, 0.4, false, "Gravity charge")
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 3, 0.5, false, "Gravity cosmic")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.1,
			Ambient = Color3.new(0.15, 0, 0.25),
			ColorShift_Top = Color3.new(0.3, 0, 0.6)
		}):Play()

		-- Create black hole core
		local blackHole = CreatePart(VT(60, 60, 60), CF(ROOTPART.Position + VT(0, 60, 0)), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, 0.5, true)
		blackHole.Shape = Enum.PartType.Ball

		-- Gravity pulls everything inward
		coroutine.wrap(function()
			for pull = 1, 80 do
				for _, playerData in pairs(cachedPlayers) do
					if playerData.RootPart then
						local direction = (blackHole.Position - playerData.RootPart.Position).Unit
						local distance = (blackHole.Position - playerData.RootPart.Position).Magnitude
						if distance < 200 then
							local pullForce = Instance.new("BodyVelocity")
							pullForce.MaxForce = VT(1e9, 1e9, 1e9)
							pullForce.Velocity = direction * math.min(distance / 200 * 300, 150)
							pullForce.Parent = playerData.RootPart
							Debris:AddItem(pullForce, 0.1)
							ApplyDamage(playerData.Humanoid, 25, targetPlayer)
						end
					end
				end

				-- Gravity field effects
				for g = 1, 12 do
					local angle = g * 30
					local pos = ROOTPART.Position + VT(math.cos(RAD(angle)) * 100, MRANDOM(20, 80), math.sin(RAD(angle)) * 100)
					CreateEffect("Sphere", CF(pos), VT(15, 15, 15), VT(40, 40, 40), Color3.new(0.1, 0, 0.3), 0.6, nil, 1.5)
					CreatePositionalSound("time_distortion", pos, 0.8, MRANDOM(8, 12)/10, false, "Gravity warp")
					ApplyAoE(pos, 35, 280, 100)
				end

				task.wait(0.3)
			end
		end)()

		-- Expanding black hole
		TweenService:Create(blackHole, TweenInfo.new(8), {Size = VT(150, 150, 150), Transparency = 0.7}):Play()
		Debris:AddItem(blackHole, 20)

		task.wait(20)

		-- Phase 31: VOID SINGULARITY - All void powers converge
		CurrentFinalePhase = 31
		DisplayTaunt("THE VOID CONSUMES ALL EXISTENCE!", 6, Color3.fromRGB(50, 0, 100))
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 4, 0.4, false, "Void singularity")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 3.5, 0.5, false, "Void tear")
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 3, 0.6, false, "Void explosion")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.05,
			Ambient = Color3.new(0.1, 0, 0.2),
			ColorShift_Top = Color3.new(0.2, 0, 0.4)
		}):Play()

		-- Void rifts everywhere
		coroutine.wrap(function()
			for voidWave = 1, 100 do
				for v = 1, 8 do
					local voidPos = ROOTPART.Position + VT(MRANDOM(-150, 150), MRANDOM(10, 70), MRANDOM(-150, 150))
					local voidRift = CreatePart(VT(30, 60, 12), CF(voidPos) * ANGLES(RAD(MRANDOM(-60, 60)), RAD(MRANDOM(-180, 180)), 0),
						Color3.new(0.1, 0, 0.3), Enum.Material.ForceField, 0.15, true)

					-- Void projectiles
					coroutine.wrap(function()
						for proj = 1, 15 do
							local voidOrb = CreatePart(VT(5, 5, 5), voidRift.CFrame, Color3.new(0.15, 0, 0.25), Enum.Material.Neon, 0, false)
							voidOrb.Shape = Enum.PartType.Ball

							local targetPos = ROOTPART.Position + VT(MRANDOM(-60, 60), 0, MRANDOM(-60, 60))
							local dir = (targetPos - voidOrb.Position).Unit
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = VT(1e9, 1e9, 1e9)
							bv.Velocity = dir * 100
							bv.Parent = voidOrb

							local hitDebounce = false
							voidOrb.Touched:Connect(function(hit)
								if not hitDebounce and isValidMeteorCollision(hit) then
									hitDebounce = true
									CreateEffect("Sphere", CF(voidOrb.Position), VT(5, 5, 5), VT(25, 25, 25), Color3.new(0.2, 0, 0.35), 0.7, nil, 1.5)
									CreatePositionalSound("explosion_impact", voidOrb.Position, 1.5, MRANDOM(8, 12)/10, false, "Void impact")
									ApplyAoE(voidOrb.Position, 20, 250, 90)
									-- Apply Blind effect from void attack
									for _, playerData in pairs(cachedPlayers) do
										if playerData.Character and (playerData.Character.HumanoidRootPart.Position - voidOrb.Position).Magnitude < 30 then
											ApplyStatusEffect(playerData.Character, playerData.Humanoid, "Blind", targetPlayer)
										end
									end
									voidOrb:Destroy()
								end
							end)

							Debris:AddItem(voidOrb, 4)
							task.wait(0.1)
						end
					end)()

					CreatePositionalSound("dimensional_rift", voidPos, 1.5, MRANDOM(7, 12)/10, false, "Void rift")
					ApplyAoE(voidPos, 40, 300, 110)
					Debris:AddItem(voidRift, 6)
				end
				task.wait(0.15)
			end
		end)()

		task.wait(20)

		-- Phase 32: ELEMENTAL CONVERGENCE - Fire, Ice, Lightning, Earth unite
		CurrentFinalePhase = 32
		DisplayTaunt("THE FOUR ELEMENTS MERGE INTO CHAOS!", 6, Color3.fromRGB(255, 100, 100))
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 4, 0.4, false, "Fire convergence")
		CreatePositionalSound("ice_beam", ROOTPART.Position, 3.5, 0.5, false, "Ice convergence")
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 3.5, 0.6, false, "Lightning convergence")
		CreatePositionalSound("explosion_impact", ROOTPART.Position, 3, 0.7, false, "Earth convergence")

		TweenService:Create(Lighting, TweenInfo.new(2), {
			Brightness = 0.4,
			Ambient = Color3.new(0.4, 0.3, 0.2),
			ColorShift_Top = Color3.new(1, 0.5, 0.3)
		}):Play()

		-- Elemental attacks happening simultaneously
		coroutine.wrap(function()
			for element = 1, 80 do
				-- Fire tornado
				local firePos = ROOTPART.Position + VT(MRANDOM(-100, -50), MRANDOM(10, 60), MRANDOM(-100, 100))
				CreateEffect("Sphere", CF(firePos), VT(20, 20, 20), VT(50, 50, 50), Color3.new(1, 0.4, 0), 0.7, nil, 2)
				CreatePositionalSound("fire_whoosh", firePos, 1.5, MRANDOM(7, 12)/10, false, "Fire element")
				ApplyAoE(firePos, 40, 300, 110)

				-- Ice blast
				local icePos = ROOTPART.Position + VT(MRANDOM(50, 100), MRANDOM(10, 60), MRANDOM(-100, 100))
				CreateEffect("Sphere", CF(icePos), VT(20, 20, 20), VT(50, 50, 50), Color3.new(0.5, 0.9, 1), 0.7, nil, 2)
				CreatePositionalSound("ice_beam", icePos, 1.5, MRANDOM(7, 12)/10, false, "Ice element")
				ApplyAoE(icePos, 40, 300, 110)

				-- Lightning strikes
				local lightPos = ROOTPART.Position + VT(MRANDOM(-100, 100), MRANDOM(80, 150), MRANDOM(-50, 50))
				CreateLightningBolt(lightPos, lightPos + VT(0, -80, 0), 20, Color3.new(1, 1, 0.7), 6, 0.3)
				CreatePositionalSound("lightning_crack", lightPos, 1.5, MRANDOM(7, 12)/10, false, "Lightning element")
				ApplyAoE(lightPos, 35, 280, 100)

				-- Earth meteors
				local earthPos = ROOTPART.Position + VT(MRANDOM(-100, 100), 0, MRANDOM(-100, 100))
				local earth = CreatePart(VT(15, 15, 15), CF(earthPos + VT(0, 100, 0)), Color3.new(0.6, 0.4, 0.2), Enum.Material.Rock, 0, false)
				local earthBv = Instance.new("BodyVelocity")
				earthBv.MaxForce = VT(1e9, 1e9, 1e9)
				earthBv.Velocity = VT(0, -150, 0)
				earthBv.Parent = earth
				local earthDebounce = false
				earth.Touched:Connect(function(hit)
					if not earthDebounce then
						earthDebounce = true
						CreateEffect("Sphere", CF(earth.Position), VT(15, 15, 15), VT(45, 45, 45), Color3.new(0.7, 0.5, 0.3), 0.8, nil, 2)
						CreatePositionalSound("explosion_impact", earth.Position, 2, MRANDOM(6, 11)/10, false, "Earth impact")
						ApplyAoE(earth.Position, 40, 300, 110)
						earth:Destroy()
					end
				end)
				Debris:AddItem(earth, 2)

				task.wait(0.25)
			end
		end)()

		task.wait(20)

		-- Phase 33: ULTIMATE FINALE - EVERYTHING AT ONCE
		CurrentFinalePhase = 33
		DisplayTaunt("THIS IS THE END OF EVERYTHING!!!", 8, Color3.fromRGB(255, 0, 0))

		-- Spawn ALL remaining NPCs
		for i = 1, 5 do
			spawnNPC("DarkHerald", ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120)))
			spawnNPC("VoidSentinel", ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120)))
			spawnNPC("ElementalTitan", ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120)))
			spawnNPC("ShadowWraith", ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120)))
			spawnNPC("CosmicDestroyer", ROOTPART.Position + VT(MRANDOM(-120, 120), 0, MRANDOM(-120, 120)))
		end

		-- Chaos - everything happens at once with MASSIVE sounds
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.2, false, "Ultimate finale 1")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.25, false, "Ultimate finale 2")
		CreatePositionalSound("lightning_crack", ROOTPART.Position, 5, 0.4, false, "Ultimate finale 3")
		CreatePositionalSound("plasma_charge", ROOTPART.Position, 4.5, 0.3, false, "Ultimate finale 4")
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 4.5, 0.35, false, "Ultimate finale 5")
		CreatePositionalSound("energy_beam", ROOTPART.Position, 4, 0.6, false, "Ultimate finale 6")
		CreatePositionalSound("fire_whoosh", ROOTPART.Position, 4, 0.5, false, "Ultimate finale 7")
		CreatePositionalSound("cosmic_ambient", ROOTPART.Position, 4, 0.4, false, "Ultimate finale 8")

		-- Extreme lighting chaos
		coroutine.wrap(function()
			for chaos = 1, 60 do
				TweenService:Create(Lighting, TweenInfo.new(0.15), {
					Brightness = MRANDOM(0, 100)/10,
					Ambient = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10),
					ColorShift_Top = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10)
				}):Play()
				task.wait(0.2)
			end
		end)()

		-- Extreme gravity chaos
		coroutine.wrap(function()
			for grav = 1, 60 do
				workspace.Gravity = MRANDOM(-100, 400)
				task.wait(0.2)
			end
		end)()

		-- ALL ATTACK TYPES SIMULTANEOUSLY with enhanced mechanics
		coroutine.wrap(function()
			for ultimate = 1, 50 do
				-- Lightning
				local lPos = ROOTPART.Position + VT(MRANDOM(-160, 160), 0, MRANDOM(-160, 160))
				CreateLightningBolt(lPos + VT(0, 200, 0), lPos, 35, Color3.new(1, 1, 0.8), 8, 0.3)
				if ultimate % 3 == 0 then
					CreatePositionalSound("lightning_strike", lPos, 2, MRANDOM(7, 12)/10, false, "Ultimate lightning")
				end
				ApplyAoE(lPos, 35, 450, 160)
				ApplyStatusEffectToNearby(lPos, 50, "Stun", targetPlayer)

				-- Meteors
				local mPos = ROOTPART.Position + VT(MRANDOM(-160, 160), 0, MRANDOM(-160, 160))
				local meteor = CreatePart(VT(25, 25, 25), CF(mPos + VT(0, 300, 0)), Color3.new(1, 0.4, 0), Enum.Material.Neon, 0, false)
				meteor.Shape = Enum.PartType.Ball
				if ultimate % 3 == 1 then
					CreatePositionalSound("cosmic_ambient", mPos, 2, MRANDOM(6, 11)/10, false, "Ultimate meteor")
				end
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = VT(0, -300, 0)
				bv.Parent = meteor
				local hitDebounce = false
				meteor.Touched:Connect(function(hit)
					if not hitDebounce and isValidMeteorCollision(hit) then
						hitDebounce = true
						CreateEffect("Sphere", CF(meteor.Position), VT(25, 25, 25), VT(100, 100, 100), Color3.new(1, 0.4, 0), 1.5, nil, 5)
						CreatePositionalSound("explosion_impact", meteor.Position, 2.5, MRANDOM(6, 11)/10, false, "Meteor impact")
						ApplyAoE(meteor.Position, 55, 500, 200)
						meteor:Destroy()
						ApplyStatusEffectToNearby(meteor.Position, 80, "Burn", targetPlayer)
					end
				end)
				Debris:AddItem(meteor, 4)

				-- Dimensional rifts with sound
				local rPos = ROOTPART.Position + VT(MRANDOM(-160, 160), MRANDOM(10, 60), MRANDOM(-160, 160))
				local rift = CreatePart(VT(35, 70, 10), CF(rPos), Color3.new(0.2, 0, 0.8), Enum.Material.ForceField, 0.2, true)
				if ultimate % 4 == 0 then
					CreatePositionalSound("dimensional_rift", rPos, 2, MRANDOM(6, 10)/10, false, "Ultimate rift")
				end
				ApplyAoE(rPos, 50, 480, 180)
				ApplyStatusEffectToNearby(rPos, 60, "Slow", targetPlayer)
				Debris:AddItem(rift, 2)

				-- Plasma explosions with sound
				local pPos = ROOTPART.Position + VT(MRANDOM(-160, 160), 0, MRANDOM(-160, 160))
				CreatePositionalSound("explosion_impact", pPos, 2.5, MRANDOM(7, 12)/10, false, "Ultimate plasma")
				CreateEffect("Sphere", CF(pPos), VT(25, 25, 25), VT(90, 90, 90), Color3.new(0, 1, 1), 1.2, "explosion_impact", 4)
				ApplyStatusEffectToNearby(pPos, 70, "Freeze", targetPlayer)
				ApplyAoE(pPos, 50, 470, 170)

				-- Reality tears with sound
				local tPos = ROOTPART.Position + VT(MRANDOM(-160, 160), MRANDOM(-10, 70), MRANDOM(-160, 160))
				local tear = CreatePart(VT(40, 80, 8), CF(tPos), Color3.new(MRANDOM(5, 10)/10, 0, MRANDOM(5, 10)/10), Enum.Material.ForceField, 0.15, true)
				if ultimate % 5 == 0 then
					CreatePositionalSound("reality_tear", tPos, 2, MRANDOM(6, 11)/10, false, "Ultimate tear")
				end
				ApplyStatusEffectToNearby(tPos, 75, "Weakness", targetPlayer)
				ApplyAoE(tPos, 55, 490, 185)
				Debris:AddItem(tear, 2)

				task.wait(0.4)
			end
		end)()

		-- One final MASSIVE explosion after everything
		task.wait(30)

		DisplayTaunt("THE NEXUS... FINALE... COMPLETE...", 6, Color3.fromRGB(255, 255, 255))
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.15, false, "Final explosion")

		CreateEffect("Sphere", ROOTPART.CFrame, VT(150, 150, 150), VT(600, 600, 600), Color3.new(1, 1, 1), 8, "massive_explosion", 25)
		ApplyAoE(ROOTPART.Position, 300, 1500, 600)

		for finalRing = 1, 50 do
			if finalRing % 5 == 0 then
				CreatePositionalSound("massive_explosion", ROOTPART.Position, 3, MRANDOM(3, 7)/10, false, "Final ring")
			end
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180))), 
				VT(80, 80, 20), VT(300 + finalRing*40, 300 + finalRing*40, 20), Color3.new(MRANDOM(8, 10)/10, MRANDOM(5, 10)/10, MRANDOM(8, 10)/10), 2, "explosion_impact", 12)
			task.wait(0.15)
		end

		task.wait(10)  -- Dramatic pause

		-- ===== PHASE 34: FINALE FINALE FINAL ATTACK - BEYOND ULTIMATE =====
		CurrentFinalePhase = 34
		DisplayTaunt("YOU THOUGHT IT WAS OVER!?", 8, Color3.fromRGB(255, 0, 0))
		CreatePositionalSound("intro_buildup", ROOTPART.Position, 5, 0.25, false, "Ultimate buildup")
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 4.5, 0.3, false, "Beyond ultimate explosion")
		CreatePositionalSound("reality_tear", ROOTPART.Position, 4, 0.4, false, "Beyond ultimate reality")
		task.wait(3)

		DisplayTaunt("WITNESS TRUE ANNIHILATION!!!", 8, Color3.fromRGB(255, 255, 255))

		-- Spawn MAXIMUM NPCs
		for i = 1, 10 do
			spawnNPC("DarkHerald", ROOTPART.Position + VT(MRANDOM(-150, 150), 0, MRANDOM(-150, 150)))
			spawnNPC("VoidSentinel", ROOTPART.Position + VT(MRANDOM(-150, 150), 0, MRANDOM(-150, 150)))
			spawnNPC("ElementalTitan", ROOTPART.Position + VT(MRANDOM(-150, 150), 0, MRANDOM(-150, 150)))
			spawnNPC("ShadowWraith", ROOTPART.Position + VT(MRANDOM(-150, 150), 0, MRANDOM(-150, 150)))
			spawnNPC("CosmicDestroyer", ROOTPART.Position + VT(MRANDOM(-150, 150), 0, MRANDOM(-150, 150)))
		end

		-- Reality itself breaks - Ultimate chaos
		for chaos = 1, 100 do
			-- Rapidly changing environment
			TweenService:Create(Lighting, TweenInfo.new(0.1), {
				Brightness = MRANDOM(0, 150)/10,
				Ambient = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10),
				ColorShift_Top = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10),
				FogColor = Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10)
			}):Play()

			workspace.Gravity = MRANDOM(-200, 500)
			task.wait(0.1)
		end

		-- SIMULTANEOUS MEGA ATTACKS
		local finalAttackTime = tick()

		-- Continuous lightning apocalypse
		coroutine.wrap(function()
			for i = 1, 100 do
				local lPos = ROOTPART.Position + VT(MRANDOM(-180, 180), 0, MRANDOM(-180, 180))
				CreateLightningBolt(lPos + VT(0, 250, 0), lPos, 40, Color3.new(MRANDOM(8, 10)/10, MRANDOM(8, 10)/10, 1), 12, 0.25)
				CreateEffect("Sphere", CF(lPos), VT(20, 20, 20), VT(60, 60, 60), Color3.new(1, 1, 0), 0.8, nil, 3)
				ApplyAoE(lPos, 40, 550, 200)
				task.wait(0.15)
			end
		end)()

		-- Continuous meteor bombardment
		coroutine.wrap(function()
			for i = 1, 80 do
				local mPos = ROOTPART.Position + VT(MRANDOM(-180, 180), 0, MRANDOM(-180, 180))
				local mSize = MRANDOM(30, 45)
				local meteor = CreatePart(VT(mSize, mSize, mSize), CF(mPos + VT(0, 350, 0)), Color3.new(1, 0.5, 0), Enum.Material.Neon, 0, false)
				meteor.Shape = Enum.PartType.Ball

				local light = Instance.new("PointLight")
				light.Brightness = 35
				light.Color = Color3.new(1, 0.5, 0)
				light.Range = 120
				light.Parent = meteor

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = VT(1e9, 1e9, 1e9)
				bv.Velocity = VT(0, -350, 0)
				bv.Parent = meteor

				local hitDebounce = false
				meteor.Touched:Connect(function(hit)
					if not hitDebounce and isValidMeteorCollision(hit) then
						hitDebounce = true
						CreateEffect("Sphere", CF(meteor.Position), VT(mSize, mSize, mSize), VT(mSize*5, mSize*5, mSize*5), Color3.new(1, 0.5, 0), 1.8, nil, 8)
						for ring = 1, 5 do
							CreateEffect("Ring", CF(meteor.Position) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
								VT(mSize, mSize, 5), VT(mSize*4 + ring*30, mSize*4 + ring*30, 5), Color3.new(1, 0.4, 0), 1.2, nil, 5)
						end
						ApplyAoE(meteor.Position, mSize*3, 650, 250)
						meteor:Destroy()
					end
				end)

				Debris:AddItem(meteor, 5)
				task.wait(0.2)
			end
		end)()

		-- Continuous dimensional rifts
		coroutine.wrap(function()
			for i = 1, 60 do
				local rPos = ROOTPART.Position + VT(MRANDOM(-180, 180), MRANDOM(10, 80), MRANDOM(-180, 180))
				local rift = CreatePart(VT(50, 100, 12), CF(rPos) * ANGLES(RAD(MRANDOM(-90, 90)), RAD(MRANDOM(-180, 180)), 0), 
					Color3.new(0.2, 0, 0.9), Enum.Material.ForceField, 0.15, true)

				-- Void projectiles from rift
				coroutine.wrap(function()
					for p = 1, 20 do
						local voidOrb = CreatePart(VT(10, 10, 10), rift.CFrame, Color3.new(0.3, 0, 0.8), Enum.Material.Neon, 0, false)
						voidOrb.Shape = Enum.PartType.Ball

						local dir = (ROOTPART.Position + VT(MRANDOM(-80, 80), 0, MRANDOM(-80, 80)) - voidOrb.Position).Unit
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = dir * 120
						bv.Parent = voidOrb

						local hitDebounce = false
						voidOrb.Touched:Connect(function(hit)
							if not hitDebounce and isValidMeteorCollision(hit) then
								hitDebounce = true
								CreateEffect("Sphere", CF(voidOrb.Position), VT(10, 10, 10), VT(45, 45, 45), Color3.new(0.3, 0, 0.8), 0.7, nil, 3)
								ApplyAoE(voidOrb.Position, 35, 480, 170)
								voidOrb:Destroy()
							end
						end)

						Debris:AddItem(voidOrb, 4)
						task.wait(0.1)
					end
				end)()

				ApplyAoE(rPos, 60, 580, 210)
				Debris:AddItem(rift, 5)
				task.wait(0.25)
			end
		end)()

		-- Continuous plasma storms
		coroutine.wrap(function()
			for i = 1, 50 do
				for x = -3, 3 do
					for z = -3, 3 do
						local pos = ROOTPART.Position + VT(x * 60, 0, z * 60)
						CreateEffect("Sphere", CF(pos), VT(25, 25, 25), VT(75, 75, 75), Color3.new(0, 1, 1), 1, nil, 4)
						ApplyAoE(pos, 45, 520, 190)
					end
				end
				task.wait(0.3)
			end
		end)()

		-- Continuous fire tornadoes
		coroutine.wrap(function()
			for i = 1, 40 do
				local torPos = ROOTPART.Position + VT(MRANDOM(-140, 140), 0, MRANDOM(-140, 140))

				for segment = 1, 30 do
					local fire = CreatePart(VT(30 - segment*0.7, 15, 30 - segment*0.7), 
						CF(torPos) * CF(0, segment*10, 0) * ANGLES(0, RAD(segment*25), 0), 
						Color3.new(1, MRANDOM(2, 6)/10, 0), Enum.Material.Neon, 0.3, true)
					fire.Shape = Enum.PartType.Cylinder
					TweenService:Create(fire, TweenInfo.new(5), {Transparency = 1}):Play()
					Debris:AddItem(fire, 5)
				end

				ApplyAoE(torPos, 50, 560, 180)
				task.wait(0.4)
			end
		end)()

		-- Continuous quantum slices
		coroutine.wrap(function()
			for i = 1, 120 do
				local sliceAngle = i * 3
				local blade = CreatePart(VT(8, 200, 8), ROOTPART.CFrame * CF(0, 100, 0) * ANGLES(0, RAD(sliceAngle), RAD(75)), 
					Color3.new(0, 1, MRANDOM(4, 10)/10), Enum.Material.Neon, 0.2, true)

				local trail = CreatePart(VT(12, 200, 280), blade.CFrame * CF(0, 0, -140), 
					Color3.new(0, 1, MRANDOM(4, 10)/10), Enum.Material.Neon, 0.3, true)

				TweenService:Create(trail, TweenInfo.new(1), {Transparency = 1}):Play()
				Debris:AddItem(trail, 1)
				Debris:AddItem(blade, 1)

				ApplyAoE(ROOTPART.Position, 140, 540, 170)
				task.wait(0.15)
			end
		end)()

		-- Reality tears everywhere
		coroutine.wrap(function()
			for i = 1, 80 do
				for t = 1, 8 do
					local tearPos = ROOTPART.Position + VT(MRANDOM(-180, 180), MRANDOM(-30, 80), MRANDOM(-180, 180))
					local tear = CreatePart(VT(45, 90, 10), CF(tearPos) * ANGLES(RAD(MRANDOM(-90, 90)), RAD(MRANDOM(-180, 180)), 0), 
						Color3.new(MRANDOM(0, 10)/10, 0, MRANDOM(5, 10)/10), Enum.Material.ForceField, 0.1, true)

					ApplyAoE(tearPos, 55, 600, 220)
					Debris:AddItem(tear, 2)
				end
				task.wait(0.25)
			end
		end)()

		-- ULTIMATE CORE EXPLOSION SEQUENCE
		task.wait(15)

		DisplayTaunt("THE NEXUS... TRANSCENDS... EVERYTHING!!!", 10, Color3.fromRGB(255, 255, 255))
		CreatePositionalSound("massive_explosion", ROOTPART.Position, 5, 0.1, false, "Ultimate finale sound")
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 5, 0.1, false, "Ultimate finale sound 2")

		-- Create ultimate nexus sphere
		local finalCore = CreatePart(VT(200, 200, 200), ROOTPART.CFrame * CF(0, 100, 0), Color3.new(1, 1, 1), Enum.Material.Neon, 0, true)
		finalCore.Shape = Enum.PartType.Ball

		local finalLight = Instance.new("PointLight")
		finalLight.Brightness = 100
		finalLight.Color = Color3.new(1, 1, 1)
		finalLight.Range = 500
		finalLight.Parent = finalCore

		-- Charge up
		TweenService:Create(finalCore, TweenInfo.new(8), {Size = VT(500, 500, 500)}):Play()
		TweenService:Create(finalLight, TweenInfo.new(8), {Brightness = 500, Range = 1000}):Play()

		-- Pull everything toward the core
		for pull = 1, 80 do
			for _, playerData in pairs(cachedPlayers) do
				if playerData.RootPart then
					local direction = (finalCore.Position - playerData.RootPart.Position).Unit
					local distance = (finalCore.Position - playerData.RootPart.Position).Magnitude
					local pullStrength = (500 - math.min(distance, 500)) / 500 * 200

					local pullForce = Instance.new("BodyVelocity")
					pullForce.MaxForce = VT(1e9, 1e9, 1e9)
					pullForce.Velocity = direction * pullStrength
					pullForce.Parent = playerData.RootPart
					Debris:AddItem(pullForce, 0.1)

					if distance < 100 then
						ApplyDamage(playerData.Humanoid, 150, targetPlayer)
					end
				end
			end
			task.wait(0.1)
		end

		task.wait(8)

		-- FINAL ULTIMATE EXPLOSION
		DisplayTaunt("TOTAL... COSMIC... OBLITERATION!!!", 12, Color3.fromRGB(255, 255, 255))

		-- Ultra blinding flash
		local ultraFlash = Instance.new("ColorCorrectionEffect")
		ultraFlash.Brightness = 3
		ultraFlash.Contrast = 2
		ultraFlash.Saturation = -1
		ultraFlash.Parent = Lighting
		TweenService:Create(ultraFlash, TweenInfo.new(2), {Brightness = 0, Saturation = 0, Contrast = 0}):Play()
		Debris:AddItem(ultraFlash, 3)

		-- MASSIVE EXPLOSION
		CreateEffect("Sphere", finalCore.CFrame, VT(500, 500, 500), VT(2000, 2000, 2000), Color3.new(1, 1, 1), 15, nil, 50)
		ApplyAoE(finalCore.Position, 500, 5000, 1000)

		-- Explosion waves
		for wave = 1, 100 do
			CreateEffect("Ring", finalCore.CFrame * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180))), 
				VT(100, 100, 30), VT(600 + wave*80, 600 + wave*80, 30), 
				Color3.new(MRANDOM(8, 10)/10, MRANDOM(5, 10)/10, MRANDOM(8, 10)/10), 3, nil, 20)

			if wave % 5 == 0 then
				CreatePositionalSound("massive_explosion", ROOTPART.Position, 4, MRANDOM(3, 7)/10, false, "Wave explosion")
			end

			task.wait(0.12)
		end

		-- Pillar of annihilation
		for pillar = 1, 20 do
			local pillarAngle = pillar * 18
			for height = 0, 400, 40 do
				local pillarPos = finalCore.Position + VT(math.cos(RAD(pillarAngle)) * 120, height - 200, math.sin(RAD(pillarAngle)) * 120)
				CreateEffect("Sphere", CF(pillarPos), VT(40, 40, 40), VT(80, 80, 80), Color3.new(MRANDOM(8, 10)/10, MRANDOM(5, 10)/10, MRANDOM(8, 10)/10), 1.5, nil, 6)
				ApplyAoE(pillarPos, 50, 700, 280)
			end
			task.wait(0.3)
		end

		-- Final reality collapse
		for collapse = 1, 30 do
			local collapsePos = ROOTPART.Position + VT(MRANDOM(-200, 200), MRANDOM(-50, 100), MRANDOM(-200, 200))

			CreateEffect("Sphere", CF(collapsePos), VT(60, 60, 60), VT(180, 180, 180), Color3.new(MRANDOM(0, 10)/10, MRANDOM(0, 10)/10, MRANDOM(0, 10)/10), 2, nil, 10)

			for ring = 1, 8 do
				CreateEffect("Ring", CF(collapsePos) * ANGLES(RAD(MRANDOM(-180, 180)), RAD(MRANDOM(-180, 180)), 0), 
					VT(50, 50, 15), VT(180 + ring*40, 180 + ring*40, 15), Color3.new(MRANDOM(7, 10)/10, MRANDOM(5, 10)/10, MRANDOM(7, 10)/10), 1.8, nil, 8)
			end

			ApplyAoE(collapsePos, 100, 800, 320)
			task.wait(0.6)
		end

		finalCore:Destroy()

		-- One final shockwave
		for finalWave = 1, 150 do
			CreateEffect("Ring", ROOTPART.CFrame * ANGLES(RAD(90), RAD(finalWave*2.4), 0), 
				VT(80, 80, 20), VT(120 + finalWave*50, 120 + finalWave*50, 20), 
				Color3.new(MRANDOM(8, 10)/10, MRANDOM(5, 10)/10, MRANDOM(8, 10)/10), 0.8, nil, 4)
			task.wait(0.08)
		end

		-- Universe-ending blast
		ApplyAoE(ROOTPART.Position, 999, 10000, 2000)

		task.wait(15)

		-- ===== RESTORATION PHASE =====
		DisplayTaunt("The nexus... rests... for now...", 5, Color3.fromRGB(100, 100, 255))

		-- Gradually restore all environment settings
		TweenService:Create(Lighting, TweenInfo.new(8), {
			Brightness = originalBrightness,
			Ambient = originalAmbient,
			ColorShift_Top = originalColorShift,
			OutdoorAmbient = originalOutdoorAmbient,
			FogEnd = originalFogEnd,
			FogColor = originalFogColor,
			ClockTime = originalClockTime
		}):Play()

		TweenService:Create(workspace, TweenInfo.new(8), {
			Gravity = originalGravity
		}):Play()

		-- Cleanup all NPCs and systems
		cleanupNPCs()
		stopMinionMode()
		CurrentFinalePhase = 0

		task.wait(2)
		Attack = false
		AttackCooldowns.NexusFinale = tick()
	end

	-- All attacks list
	local AllAttacks = {
		LightningStrike, MeteorShower, DimensionalRifts, ArcaneDevastation,
		InfernoTornado, CosmicAnnihilation, QuantumSlice, StellarConvergence,
		VoidStorm, PlasmaNova, CryoBlast, GravityCollapse, PlasmaCascade,
		RealityShatter, SolarFlareBurst, TemporalDistortion, VolcanicEruption,
		AntimatterAnnihilation, TyphoonCyclone, NexusFinale
	}

	-- ENHANCED INFECTION SYSTEM FUNCTIONS
	local function createCloneGUI(player)
		if InfectionConfig.CloneGUIs[player.UserId] then return end

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NexusCloneGUI"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = player:WaitForChild("PlayerGui")

		InfectionConfig.CloneGUIs[player.UserId] = screenGui

		-- Main dark container
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(0, 280, 0, 200)
		mainFrame.Position = UDim2.new(1, -300, 0, 20)
		mainFrame.BackgroundColor3 = Color3.fromRGB(20, 5, 15)
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = screenGui

		local borderGlow = Instance.new("UIStroke")
		borderGlow.Color = Color3.fromRGB(150, 0, 100)
		borderGlow.Thickness = 2
		borderGlow.Transparency = 0.2
		borderGlow.Parent = mainFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = mainFrame

		-- Title with distortion
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -10, 0, 30)
		title.Position = UDim2.new(0, 5, 0, 5)
		title.BackgroundTransparency = 1
		title.Text = "? NEXUS CLONE ?"
		title.TextColor3 = Color3.fromRGB(200, 50, 150)
		title.TextSize = 16
		title.Font = Enum.Font.GothamBold
		title.Parent = mainFrame

		-- Taunt display
		local tauntLabel = Instance.new("TextLabel")
		tauntLabel.Size = UDim2.new(1, -10, 0, 50)
		tauntLabel.Position = UDim2.new(0, 5, 0, 40)
		tauntLabel.BackgroundTransparency = 1
		tauntLabel.Text = CloneTaunts[MRANDOM(1, #CloneTaunts)]
		tauntLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		tauntLabel.TextSize = 12
		tauntLabel.Font = Enum.Font.Gotham
		tauntLabel.TextWrapped = true
		tauntLabel.Parent = mainFrame

		-- Cycle taunts
		coroutine.wrap(function()
			while screenGui.Parent do
				task.wait(MRANDOM(3, 7))
				if tauntLabel.Parent then
					tauntLabel.Text = CloneTaunts[MRANDOM(1, #CloneTaunts)]
				end
			end
		end)()

		-- Random attack from list (excluding finale)
		local availableAttacks = {
			{Name = "Lightning Strike", Func = function() 
				if not Attack then
					-- Weaker clone version
					CreateSound("lightning_crack", player.Character.HumanoidRootPart, 1, 1, false)
					for i = 1, 5 do
						local pos = player.Character.HumanoidRootPart.Position + VT(MRANDOM(-20, 20), 0, MRANDOM(-20, 20))
						CreateEffect("Sphere", CF(pos), VT(5, 5, 5), VT(15, 15, 15), Color3.new(1, 1, 0.8), 0.5, nil, 1)
						ApplyAoE(pos, 10, 40, 20)
					end
				end
			end, Color = Color3.fromRGB(255, 255, 100)},
			{Name = "Fire Blast", Func = function()
				if not Attack then
					CreateSound("fire_whoosh", player.Character.HumanoidRootPart, 1, 1, false)
					for i = 1, 3 do
						local fireball = CreatePart(VT(3, 3, 3), player.Character.HumanoidRootPart.CFrame * CF(0, 0, -5), Color3.new(1, 0.4, 0), Enum.Material.Neon, 0, false)
						fireball.Shape = Enum.PartType.Ball
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = player.Character.HumanoidRootPart.CFrame.LookVector * 40
						bv.Parent = fireball
						fireball.Touched:Connect(function(hit)
							if hit.Parent ~= player.Character then
								CreateEffect("Sphere", CF(fireball.Position), VT(3, 3, 3), VT(10, 10, 10), Color3.new(1, 0.4, 0), 0.4, nil, 1)
								ApplyAoE(fireball.Position, 8, 35, 15)
								fireball:Destroy()
							end
						end)
						Debris:AddItem(fireball, 3)
					end
				end
			end, Color = Color3.fromRGB(255, 100, 0)},
			{Name = "Ice Shard", Func = function()
				if not Attack then
					CreateSound("ice_beam", player.Character.HumanoidRootPart, 1, 1, false)
					for i = 1, 4 do
						local shard = CreatePart(VT(2, 2, 2), player.Character.HumanoidRootPart.CFrame * CF(MRANDOM(-3, 3), 0, -3), Color3.new(0.8, 0.9, 1), Enum.Material.Ice, 0, false)
						local bv = Instance.new("BodyVelocity")
						bv.MaxForce = VT(1e9, 1e9, 1e9)
						bv.Velocity = (player.Character.HumanoidRootPart.CFrame.LookVector + VT(MRANDOM(-1, 1)/5, 0, MRANDOM(-1, 1)/5)) * 35
						bv.Parent = shard
						shard.Touched:Connect(function(hit)
							if hit.Parent ~= player.Character then
								ApplyAoE(shard.Position, 6, 25, 10)
								shard:Destroy()
							end
						end)
						Debris:AddItem(shard, 3)
					end
				end
			end, Color = Color3.fromRGB(100, 200, 255)}
		}

		local chosenAttack = availableAttacks[MRANDOM(1, #availableAttacks)]

		-- Attack button
		local attackButton = Instance.new("TextButton")
		attackButton.Size = UDim2.new(1, -10, 0, 35)
		attackButton.Position = UDim2.new(0, 5, 0, 100)
		attackButton.BackgroundColor3 = Color3.fromRGB(40, 10, 30)
		attackButton.BorderSizePixel = 0
		attackButton.Text = chosenAttack.Name
		attackButton.TextColor3 = chosenAttack.Color
		attackButton.TextSize = 14
		attackButton.Font = Enum.Font.Gotham
		attackButton.Parent = mainFrame

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = attackButton

		local buttonStroke = Instance.new("UIStroke")
		buttonStroke.Color = chosenAttack.Color
		buttonStroke.Thickness = 1
		buttonStroke.Transparency = 0.5
		buttonStroke.Parent = attackButton

		attackButton.MouseButton1Click:Connect(function()
			chosenAttack.Func()
		end)

		-- Status label
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Size = UDim2.new(1, -10, 0, 25)
		statusLabel.Position = UDim2.new(0, 5, 0, 145)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = "INFECTED BY NEXUS"
		statusLabel.TextColor3 = Color3.fromRGB(255, 0, 100)
		statusLabel.TextSize = 12
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.Parent = mainFrame

		-- Pulsing effect
		coroutine.wrap(function()
			while screenGui.Parent do
				TweenService:Create(borderGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.8}):Play()
				task.wait(0.8)
			end
		end)()
	end

	local function createInfectedVisualEffects(character)
		-- Create continuous visual effects for infected players (like Nexus boss but weaker)
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local effectsFolder = Instance.new("Folder")
		effectsFolder.Name = "InfectedEffects"
		effectsFolder.Parent = character

		-- Add body part auras similar to main Nexus boss
		for _, partName in ipairs({"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg", "Head"}) do
			local part = character:FindFirstChild(partName)
			if part then
				-- Create orbiting energy spheres (2 per part instead of 3)
				for i = 1, 2 do
					local auraSphere = CreatePart(VT(0.8, 0.8, 0.8), part.CFrame, Color3.new(0.5, 0.1, 0.9), Enum.Material.Neon, 0.5, true)
					auraSphere.Shape = Enum.PartType.Ball
					auraSphere.Parent = effectsFolder

					coroutine.wrap(function()
						local angle = (i / 2) * math.pi * 2
						while effectsFolder.Parent and part.Parent and rootPart.Parent do
							angle = angle + 0.1
							auraSphere.CFrame = part.CFrame * CF(math.cos(angle) * 1.8, math.sin(tick() * 2.5 + i) * 1.2, math.sin(angle) * 1.8)
							task.wait()
						end
					end)()
				end
			end
		end

		-- Purple aura rings around character
		for i = 1, 4 do
			local auraPart = CreatePart(VT(1.2, 1.2, 1.2), rootPart.CFrame, Color3.new(0.4, 0, 0.8), Enum.Material.Neon, 0.6, true)
			auraPart.Shape = Enum.PartType.Ball
			auraPart.Parent = effectsFolder

			coroutine.wrap(function()
				local angle = (i / 4) * math.pi * 2
				while effectsFolder.Parent and rootPart.Parent do
					angle = angle + 0.06
					auraPart.CFrame = rootPart.CFrame * CF(math.cos(angle) * 2.5, math.sin(tick() * 2 + i) * 1.5, math.sin(angle) * 2.5)
					task.wait()
				end
			end)()
		end

		-- Corrupted energy particles
		coroutine.wrap(function()
			while effectsFolder.Parent and rootPart.Parent do
				if math.random(1, 3) == 1 then
					local particle = CreatePart(VT(0.6, 0.6, 0.6), rootPart.CFrame * CF(math.random(-2, 2), math.random(0, 4), math.random(-2, 2)), Color3.new(0.5, 0, 0.9), Enum.Material.Neon, 0.3, true)
					particle.Shape = Enum.PartType.Ball
					TweenService:Create(particle, TweenInfo.new(1.5), {
						CFrame = particle.CFrame + VT(0, 6, 0),
						Size = VT(1.2, 1.2, 1.2),
						Transparency = 1
					}):Play()
					Debris:AddItem(particle, 1.5)
				end
				task.wait(0.25)
			end
		end)()

		-- Energy sparks (similar to Nexus boss)
		coroutine.wrap(function()
			while effectsFolder.Parent and rootPart.Parent do
				if math.random(1, 4) == 1 then
					local spark = CreatePart(VT(0.4, 0.4, 0.4), rootPart.CFrame * CF(math.random(-3, 3), math.random(-1, 4), math.random(-3, 3)), Color3.new(0.8, 0.5, 1), Enum.Material.Neon, 0, true)
					spark.Shape = Enum.PartType.Ball
					TweenService:Create(spark, TweenInfo.new(0.7), {
						Size = VT(1.5, 1.5, 1.5),
						Transparency = 1
					}):Play()
					Debris:AddItem(spark, 0.7)
				end
				task.wait(0.4)
			end
		end)()

		-- Cosmic dust trail (like Nexus boss but smaller)
		coroutine.wrap(function()
			while effectsFolder.Parent and rootPart.Parent do
				if math.random(1, 6) == 1 then
					local dust = CreatePart(VT(1, 1, 1), rootPart.CFrame * CF(0, math.random(1, 3), 0), Color3.new(0.3, 0.05, 0.6), Enum.Material.Neon, 0.7, true)
					dust.Shape = Enum.PartType.Ball
					TweenService:Create(dust, TweenInfo.new(2), {
						CFrame = dust.CFrame + VT(math.random(-6, 6), math.random(3, 6), math.random(-6, 6)),
						Size = VT(0.2, 0.2, 0.2),
						Transparency = 1
					}):Play()
					Debris:AddItem(dust, 2)
				end
				task.wait(0.5)
			end
		end)()

		return effectsFolder
	end

	local function playInfectionAnimation(player)
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

		local character = player.Character
		local rootPart = character.HumanoidRootPart

		-- Infection visual effects
		CreateSound("dimensional_rift", rootPart, 2, 0.8, false, "Dimensional rift/portal sound")

		-- Dark energy swirl
		for i = 1, 15 do
			local energy = CreatePart(VT(2, 2, 2), rootPart.CFrame * CF(MRANDOM(-8, 8), MRANDOM(-5, 10), MRANDOM(-8, 8)), Color3.new(0.2, 0, 0.5), Enum.Material.Neon, 0.3, true)
			energy.Shape = Enum.PartType.Ball

			TweenService:Create(energy, TweenInfo.new(1.5), {
				CFrame = rootPart.CFrame,
				Size = VT(0.5, 0.5, 0.5),
				Transparency = 1
			}):Play()

			Debris:AddItem(energy, 1.5)
		end

		-- Infection explosion
		CreateEffect("Sphere", rootPart.CFrame, VT(8, 8, 8), VT(25, 25, 25), Color3.new(0.3, 0, 0.6), 1, nil, 2)

		-- Create continuous visual effects
		local visualEffects = createInfectedVisualEffects(character)
		InfectionConfig.CloneConnections[player.UserId .. "_visuals"] = visualEffects

		-- Character transformation effects
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Disable auto-heal for infected
			local infectedHealthConnection
			infectedHealthConnection = humanoid.HealthChanged:Connect(function(health)
				if health > humanoid.Health and not DEAD then
					humanoid.Health = humanoid.Health
				end
			end)
			InfectionConfig.CloneConnections[player.UserId .. "_health"] = infectedHealthConnection
		end
	end

	-- Handle minion deaths and disconnections
	Players.PlayerRemoving:Connect(function(player)
		if MinionConfig.Minions[player.UserId] then
			freeMinion(player.UserId)
		end
	end)

	-- Monitor minions for death - Free them if they die
	coroutine.wrap(function()
		while true do
			for userId, minionData in pairs(MinionConfig.Minions) do
				if minionData.Humanoid and minionData.Humanoid.Health <= 0 then
					freeMinion(userId)
				elseif not minionData.Player or not minionData.Player.Character then
					freeMinion(userId)
				end
			end
			task.wait(1)
		end
	end)()

	-- AI FUNCTIONS
	local function GetNearestTarget()
		local nearest = nil
		local minDist = AISettings.DetectionRange

		for _, player in pairs(Players:GetPlayers()) do
			if player ~= targetPlayer and player.Character then
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				local root = player.Character:FindFirstChild("HumanoidRootPart")

				if hum and root and hum.Health > 0 then
					local dist = (root.Position - ROOTPART.Position).Magnitude
					if dist < minDist then
						nearest = player
						minDist = dist
					end
				end
			end
		end

		return nearest, minDist
	end

	local function ExecuteAIAttack()
		if Attack or not AIMode then return end

		local target, dist = GetNearestTarget()
		if not target then return end

		local availableAttacks = {}

		-- Get all attacks EXCEPT NexusFinale (last one in the list)
		for i = 1, #AllAttacks - 1 do
			local attack = AllAttacks[i]
			local cooldownName = tostring(attack)
			if not AttackCooldowns[cooldownName] or tick() - AttackCooldowns[cooldownName] > 2 then
				table.insert(availableAttacks, attack)
			end
		end

		if #availableAttacks > 0 then
			local chosenAttack = availableAttacks[MRANDOM(1, #availableAttacks)]
			-- Face the target
			ROOTPART.CFrame = CFrame.lookAt(ROOTPART.Position, target.Character.HumanoidRootPart.Position)
			chosenAttack()
			AttackCooldowns[tostring(chosenAttack)] = tick()
		end

		AIState.LastAttackTime = tick()
	end

	-- AI Main Loop - IMPROVED PURSUIT
	coroutine.wrap(function()
		while not DEAD do
			if AIMode and not Attack then
				local target, dist = GetNearestTarget()

				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
					AIState.CurrentTarget = target

					-- Face target
					local targetPos = target.Character.HumanoidRootPart.Position
					ROOTPART.CFrame = CFrame.lookAt(ROOTPART.Position, targetPos)

					if dist <= AISettings.AttackRange and tick() - AIState.LastAttackTime > AISettings.AttackCooldown then
						-- In range, attack!
						ExecuteAIAttack()
					elseif dist > AISettings.AttackRange and dist <= AISettings.DetectionRange then
						-- Out of range, move towards target
						local moveDir = (targetPos - ROOTPART.Position).Unit
						HUMANOID:MoveTo(targetPos)

						-- Also manually move for faster pursuit
						ROOTPART.CFrame = ROOTPART.CFrame + (moveDir * AISettings.MovementSpeed * 0.1)
					end
				end
			end

			task.wait(0.1)
		end
	end)()

	-- PLAYER STOMP SYSTEM
	local function handlePlayerStomp(player, character)
		if not character or DEAD then return end

		local lastStompTime = PlayerLastStompTime[player.UserId] or 0
		local currentTime = tick()

		if currentTime - lastStompTime < PlayerStompCooldown then
			return
		end

		local characterRoot = character:FindFirstChild("HumanoidRootPart")
		if not characterRoot then return end

		local distance = (characterRoot.Position - ROOTPART.Position).Magnitude
		if distance > PlayerStompRange then return end

		local heightDifference = characterRoot.Position.Y - ROOTPART.Position.Y
		if heightDifference < 3 then return end

		if HUMANOID then
			HUMANOID:TakeDamage(PlayerStompDamage)
			PlayerLastStompTime[player.UserId] = currentTime

			CreateEffect("Sphere", CF(ROOTPART.Position), VT(8, 8, 8), VT(20, 20, 20), Color3.new(1, 0.4, 0.1), 0.5, 429400881, 2)

			local damageIndicator = Instance.new("BillboardGui")
			damageIndicator.Adornee = ROOTPART
			damageIndicator.Size = UDim2.new(0, 150, 0, 40)
			damageIndicator.StudsOffset = Vector3.new(0, 3, 0)
			damageIndicator.AlwaysOnTop = true

			local damageText = Instance.new("TextLabel")
			damageText.BackgroundTransparency = 1
			damageText.Size = UDim2.new(1, 0, 1, 0)
			damageText.Text = "-" .. PlayerStompDamage .. " STOMP!"
			damageText.TextColor3 = Color3.new(1, 0.5, 0)
			damageText.TextStrokeTransparency = 0
			damageText.TextSize = 24
			damageText.Font = Enum.Font.SourceSansBold
			damageText.Parent = damageIndicator

			damageIndicator.Parent = workspace

			coroutine.wrap(function()
				for i = 1, 15 do
					damageText.TextTransparency = i/15
					damageText.TextStrokeTransparency = i/15
					damageText.Position = UDim2.new(0, 0, 0, -i*1.5)
					task.wait(0.02)
				end
				damageIndicator:Destroy()
			end)()

			ROOTPART.Velocity = ROOTPART.Velocity + Vector3.new(MRANDOM(-8, 8), 4, MRANDOM(-8, 8))
		end
	end

	-- Player stomp detection - OPTIMIZED
	coroutine.wrap(function()
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= targetPlayer then
				PlayerLastStompTime[player.UserId] = 0
			end
		end

		Players.PlayerAdded:Connect(function(player)
			if player ~= targetPlayer then
				PlayerLastStompTime[player.UserId] = 0
			end
		end)

		while not DEAD do
			-- Use cached players instead of Players:GetPlayers() every 0.5s
			for _, playerData in pairs(cachedPlayers) do
				if playerData.Model and playerData.Humanoid then
					local player = Players:GetPlayerFromCharacter(playerData.Model)
					if player then
						handlePlayerStomp(player, playerData.Model)
					end
				end
			end
			task.wait(0.5) -- Increased from 0.1s to 0.5s for better performance
		end
	end)()

	-- MODERN DARK MODE GUI
	local function CreateModernGUI()
		if BossGUI then BossGUI:Destroy() end

		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NexusControlGUI"
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = targetPlayer:WaitForChild("PlayerGui")

		BossGUI = screenGui

		-- Main dark container
		local mainFrame = Instance.new("Frame")
		mainFrame.Size = UDim2.new(0, 320, 0, 500)
		mainFrame.Position = UDim2.new(1, -340, 0.5, -250)
		mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		mainFrame.BorderSizePixel = 0
		mainFrame.Parent = screenGui

		-- Modern border glow
		local borderGlow = Instance.new("UIStroke")
		borderGlow.Color = Color3.fromRGB(100, 50, 200)
		borderGlow.Thickness = 2
		borderGlow.Transparency = 0.3
		borderGlow.Parent = mainFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = mainFrame

		-- Title
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -20, 0, 40)
		title.Position = UDim2.new(0, 10, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = "? NEXUS CHAOS MATRIX ?"
		title.TextColor3 = Color3.fromRGB(150, 100, 255)
		title.TextSize = 18
		title.Font = Enum.Font.GothamBold
		title.Parent = mainFrame

		-- Health display
		local healthFrame = Instance.new("Frame")
		healthFrame.Size = UDim2.new(1, -20, 0, 30)
		healthFrame.Position = UDim2.new(0, 10, 0, 60)
		healthFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		healthFrame.BorderSizePixel = 0
		healthFrame.Parent = mainFrame

		local healthCorner = Instance.new("UICorner")
		healthCorner.CornerRadius = UDim.new(0, 6)
		healthCorner.Parent = healthFrame

		local healthBar = Instance.new("Frame")
		healthBar.Size = UDim2.new(1, 0, 1, 0)
		healthBar.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
		healthBar.BorderSizePixel = 0
		healthBar.Parent = healthFrame

		local healthBarCorner = Instance.new("UICorner")
		healthBarCorner.CornerRadius = UDim.new(0, 6)
		healthBarCorner.Parent = healthBar

		local healthText = Instance.new("TextLabel")
		healthText.Size = UDim2.new(1, 0, 1, 0)
		healthText.BackgroundTransparency = 1
		healthText.Text = "NEXUS: " .. math.floor(HUMANOID.Health) .. " / " .. HUMANOID.MaxHealth
		healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
		healthText.TextSize = 14
		healthText.Font = Enum.Font.Gotham
		healthText.Parent = healthFrame

		-- Scrolling frame for attacks
		local scrollFrame = Instance.new("ScrollingFrame")
		scrollFrame.Size = UDim2.new(1, -20, 1, -180)
		scrollFrame.Position = UDim2.new(0, 10, 0, 100)
		scrollFrame.BackgroundTransparency = 1
		scrollFrame.BorderSizePixel = 0
		scrollFrame.ScrollBarThickness = 6
		scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 50, 200)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		scrollFrame.Parent = mainFrame

		-- Attack buttons
		local attacks = {
			{Name = "Lightning Strike", Func = LightningStrike, Color = Color3.fromRGB(255, 255, 100), Key = "[1]"},
			{Name = "Meteor Shower", Func = MeteorShower, Color = Color3.fromRGB(255, 100, 50), Key = "[2]"},
			{Name = "Dimensional Rifts", Func = DimensionalRifts, Color = Color3.fromRGB(150, 50, 255), Key = "[3]"},
			{Name = "Arcane Devastation", Func = ArcaneDevastation, Color = Color3.fromRGB(200, 0, 255), Key = "[4]"},
			{Name = "Inferno Tornado", Func = InfernoTornado, Color = Color3.fromRGB(255, 100, 0), Key = "[5]"},
			{Name = "Cosmic Annihilation", Func = CosmicAnnihilation, Color = Color3.fromRGB(100, 0, 200), Key = "[6]"},
			{Name = "Quantum Slice", Func = QuantumSlice, Color = Color3.fromRGB(0, 255, 150), Key = "[7]"},
			{Name = "Stellar Convergence", Func = StellarConvergence, Color = Color3.fromRGB(255, 200, 0), Key = "[8]"},
			{Name = "Void Storm", Func = VoidStorm, Color = Color3.fromRGB(100, 0, 150), Key = "[9]"},
			{Name = "Plasma Nova", Func = PlasmaNova, Color = Color3.fromRGB(0, 150, 255), Key = "[0]"},
			{Name = "Cryo Blast", Func = CryoBlast, Color = Color3.fromRGB(100, 200, 255), Key = "[Q]"},
			{Name = "Gravity Collapse", Func = GravityCollapse, Color = Color3.fromRGB(100, 0, 100), Key = "[R]"},
			{Name = "Plasma Cascade", Func = PlasmaCascade, Color = Color3.fromRGB(150, 100, 255), Key = "[T]"},
			{Name = "Reality Shatter", Func = RealityShatter, Color = Color3.fromRGB(200, 0, 200), Key = "[Y]"},
			{Name = "Solar Flare Burst", Func = SolarFlareBurst, Color = Color3.fromRGB(255, 200, 0), Key = "[U]"},
			{Name = "Temporal Distortion", Func = TemporalDistortion, Color = Color3.fromRGB(100, 255, 200), Key = "[I]"},
			{Name = "Volcanic Eruption", Func = VolcanicEruption, Color = Color3.fromRGB(255, 80, 0), Key = "[O]"},
			{Name = "Antimatter Annihilation", Func = AntimatterAnnihilation, Color = Color3.fromRGB(200, 0, 255), Key = "[P]"},
			{Name = "Typhoon Cyclone", Func = TyphoonCyclone, Color = Color3.fromRGB(150, 200, 255), Key = "[F]"},
			{Name = "NEXUS FINALE", Func = NexusFinale, Color = Color3.fromRGB(255, 150, 255), Key = "[E]"}
		}

		local yPos = 0
		for i, attack in ipairs(attacks) do
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, -10, 0, 35)
			button.Position = UDim2.new(0, 5, 0, yPos)
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			button.BorderSizePixel = 0
			button.Text = attack.Name .. " " .. attack.Key
			button.TextColor3 = attack.Color
			button.TextSize = 14
			button.Font = Enum.Font.Gotham
			button.Parent = scrollFrame

			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 6)
			buttonCorner.Parent = button

			local buttonStroke = Instance.new("UIStroke")
			buttonStroke.Color = attack.Color
			buttonStroke.Thickness = 1
			buttonStroke.Transparency = 0.7
			buttonStroke.Parent = button

			button.MouseButton1Click:Connect(function()
				if not Attack then
					attack.Func()
				end
			end)

			button.MouseEnter:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
				TweenService:Create(buttonStroke, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
			end)

			button.MouseLeave:Connect(function()
				TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
				TweenService:Create(buttonStroke, TweenInfo.new(0.2), {Transparency = 0.7}):Play()
			end)

			yPos = yPos + 40
		end

		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)

		-- Control buttons
		local aiButton = Instance.new("TextButton")
		aiButton.Size = UDim2.new(0.48, 0, 0, 35)
		aiButton.Position = UDim2.new(0, 10, 1, -80)
		aiButton.BackgroundColor3 = AIMode and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
		aiButton.BorderSizePixel = 0
		aiButton.Text = AIMode and "AI: ON" or "AI: OFF"
		aiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		aiButton.TextSize = 14
		aiButton.Font = Enum.Font.GothamBold
		aiButton.Parent = mainFrame

		local aiCorner = Instance.new("UICorner")
		aiCorner.CornerRadius = UDim.new(0, 6)
		aiCorner.Parent = aiButton

		local introButton = Instance.new("TextButton")
		introButton.Size = UDim2.new(0.48, 0, 0, 35)
		introButton.Position = UDim2.new(0.52, 0, 1, -80)
		introButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		introButton.BorderSizePixel = 0
		introButton.Text = "INTRO"
		introButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		introButton.TextSize = 14
		introButton.Font = Enum.Font.GothamBold
		introButton.Parent = mainFrame

		local introCorner = Instance.new("UICorner")
		introCorner.CornerRadius = UDim.new(0, 6)
		introCorner.Parent = introButton

		-- Infection controls
		local minionFrame = Instance.new("Frame")
		minionFrame.Size = UDim2.new(1, -20, 0, 35)
		minionFrame.Position = UDim2.new(0, 10, 1, -40)
		minionFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		minionFrame.BorderSizePixel = 0
		minionFrame.Parent = mainFrame

		local minionCorner = Instance.new("UICorner")
		minionCorner.CornerRadius = UDim.new(0, 6)
		minionCorner.Parent = minionFrame

		local startMinionBtn = Instance.new("TextButton")
		startMinionBtn.Size = UDim2.new(0.48, 0, 1, 0)
		startMinionBtn.Position = UDim2.new(0, 0, 0, 0)
		startMinionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		startMinionBtn.BorderSizePixel = 0
		startMinionBtn.Text = "START MINION MODE"
		startMinionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		startMinionBtn.TextSize = 11
		startMinionBtn.Font = Enum.Font.GothamBold
		startMinionBtn.Parent = minionFrame

		local startMinionCorner = Instance.new("UICorner")
		startMinionCorner.CornerRadius = UDim.new(0, 6)
		startMinionCorner.Parent = startMinionBtn

		local stopMinionBtn = Instance.new("TextButton")
		stopMinionBtn.Size = UDim2.new(0.48, 0, 1, 0)
		stopMinionBtn.Position = UDim2.new(0.52, 0, 0, 0)
		stopMinionBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		stopMinionBtn.BorderSizePixel = 0
		stopMinionBtn.Text = "STOP MINION MODE"
		stopMinionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		stopMinionBtn.TextSize = 11
		stopMinionBtn.Font = Enum.Font.GothamBold
		stopMinionBtn.Parent = minionFrame

		local stopMinionCorner = Instance.new("UICorner")
		stopMinionCorner.CornerRadius = UDim.new(0, 6)
		stopMinionCorner.Parent = stopMinionBtn

		-- Button connections
		aiButton.MouseButton1Click:Connect(function()
			AIMode = not AIMode
			aiButton.Text = AIMode and "AI: ON" or "AI: OFF"
			aiButton.BackgroundColor3 = AIMode and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
		end)

		introButton.MouseButton1Click:Connect(function()
			if not Attack and not DEAD then
				PlayBossIntro()
			end
		end)

		startMinionBtn.MouseButton1Click:Connect(function()
			startMinionMode()
		end)

		stopMinionBtn.MouseButton1Click:Connect(function()
			stopMinionMode()
		end)

		-- Health update
		coroutine.wrap(function()
			while BossGUI.Parent and not DEAD do
				local healthPercent = HUMANOID.Health / HUMANOID.MaxHealth
				healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
				healthText.Text = "NEXUS: " .. math.floor(HUMANOID.Health) .. " / " .. HUMANOID.MaxHealth

				if healthPercent > 0.6 then
					healthBar.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
				elseif healthPercent > 0.3 then
					healthBar.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
				else
					healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
				end

				task.wait(0.3)
			end
		end)()

		return screenGui
	end

	-- Handle character respawns
	targetPlayer.CharacterAdded:Connect(function(character)
		CHARACTER = character
		HUMANOID = character:WaitForChild("Humanoid")
		ROOTPART = character:WaitForChild("HumanoidRootPart")
		HEAD = character:WaitForChild("Head")

		-- Re-disable auto-heal
		if healthChangeConnection then healthChangeConnection:Disconnect() end
		healthChangeConnection = HUMANOID.HealthChanged:Connect(function(health)
			if health > HUMANOID.Health and not DEAD then
				HUMANOID.Health = HUMANOID.Health
			end
		end)

		classValue = Instance.new("StringValue")
		classValue.Name = "Classification"
		classValue.Value = CLASSIFICATION
		classValue.Parent = CHARACTER

		Effects = Instance.new("Folder")
		Effects.Name = "Nexus_Effects"
		Effects.Parent = CHARACTER

		task.wait(1)
		CreateModernGUI()
	end)

	-- EPIC OUTRO SEQUENCE
	HUMANOID.Died:Connect(function()
		if OutroPlayed then return end
		OutroPlayed = true
		DEAD = true

		-- OPTIMIZATION: Clean up all connections to prevent memory leaks
		if heartbeatConnection then heartbeatConnection:Disconnect() end
		if playerAddedConnection then playerAddedConnection:Disconnect() end
		if playerRemovingConnection then playerRemovingConnection:Disconnect() end
		if healthChangeConnection then healthChangeConnection:Disconnect() end

		-- Stop idle effects
		IdleEffectsActive = false

		-- Clean up all GUIs immediately and thoroughly
		if BossGUI and BossGUI.Parent then 
			BossGUI:Destroy() 
			BossGUI = nil
		end
		if TauntGUI and TauntGUI.Parent then 
			TauntGUI:Destroy()
			TauntGUI = nil
		end

		-- Also check PlayerGui for any remaining GUIs
		pcall(function()
			local playerGui = targetPlayer:FindFirstChild("PlayerGui")
			if playerGui then
				local existingGUI = playerGui:FindFirstChild("NexusControlGUI")
				if existingGUI then existingGUI:Destroy() end
				local existingTaunt = playerGui:FindFirstChild("NexusTauntGUI")
				if existingTaunt then existingTaunt:Destroy() end
			end
		end)

		-- Free all minions on boss death
		for userId, _ in pairs(MinionConfig.Minions) do
			freeMinion(userId)
		end
		stopMinionMode()

		-- Display outro taunts
		DisplayTaunt(OutroTaunts[1], 4, Color3.fromRGB(255, 100, 100))
		CreatePositionalSound("time_distortion", ROOTPART.Position, 2, 0.7, false, "Time distortion/slow effect sound")

		task.wait(4)
		DisplayTaunt(OutroTaunts[2], 4, Color3.fromRGB(255, 150, 0))

		-- Energy drain effect
		local drainBeam = CreatePart(VT(8, 200, 8), ROOTPART.CFrame * CF(0, 100, 0), Color3.new(1, 1, 0.8), Enum.Material.Neon, 0.3, true)
		drainBeam.Shape = Enum.PartType.Ball

		TweenService:Create(drainBeam, TweenInfo.new(3), {
			Size = VT(20, 200, 20),
			Transparency = 0.1
		}):Play()

		task.wait(3)
		DisplayTaunt(OutroTaunts[3], 4, Color3.fromRGB(200, 200, 0))

		-- Nexus energy being sucked away
		for i = 1, 30 do
			local energy = CreatePart(VT(3, 3, 3), ROOTPART.CFrame * CF(MRANDOM(-10, 10), MRANDOM(-5, 5), MRANDOM(-10, 10)), Color3.new(0.8, 0.3, 1), Enum.Material.Neon, 0.2, true)
			energy.Shape = Enum.PartType.Ball

			TweenService:Create(energy, TweenInfo.new(2), {
				CFrame = ROOTPART.CFrame * CF(0, 150, 0),
				Size = VT(0.5, 0.5, 0.5),
				Transparency = 1
			}):Play()

			Debris:AddItem(energy, 2)
			task.wait(0.1)
		end

		task.wait(2)
		DisplayTaunt(OutroTaunts[4], 4, Color3.fromRGB(150, 150, 255))

		task.wait(3)
		DisplayTaunt(OutroTaunts[5], 5, Color3.fromRGB(255, 255, 255))

		-- Final energy drain
		CreatePositionalSound("dimensional_rift", ROOTPART.Position, 3, 0.5, false, "Dimensional rift/portal sound")

		TweenService:Create(ROOTPART, TweenInfo.new(3), {
			Transparency = 0.8,
			Size = VT(2, 2, 1)
		}):Play()

		TweenService:Create(drainBeam, TweenInfo.new(3), {
			Transparency = 1
		}):Play()

		-- Final explosion cleanup
		task.wait(3)
		CreatePositionalSound("intro_explosion", ROOTPART.Position, 2, 0.8, false, "Massive explosion sound")

		for i = 1, 10 do
			CreateEffect("Sphere", 
				CF(ROOTPART.Position + VT(MRANDOM(-8, 8), MRANDOM(-4, 6), MRANDOM(-8, 8))),
				VT(4, 4, 4), 
				VT(15, 15, 15), 
				Color3.new(MRANDOM(5, 10)/10, MRANDOM(3, 8)/10, MRANDOM(8, 10)/10), 
				0.8, 
				nil,
				1
			)
			task.wait(0.2)
		end

		-- Clean up minion GUIs
		for userId, minionData in pairs(MinionConfig.Minions) do
			if minionData.MinionGUI then
				minionData.MinionGUI:Destroy()
			end
		end

		drainBeam:Destroy()

		nexusInUse = false
		currentNexusPlayer = nil
	end)

	-- Keyboard controls (only works in LocalScript context)
	if UserInputService then
		pcall(function()
			UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed or Attack or DEAD or not currentNexusPlayer or Players.LocalPlayer ~= currentNexusPlayer then return end

				local keymap = {
					[Enum.KeyCode.One] = LightningStrike,
					[Enum.KeyCode.Two] = MeteorShower,
					[Enum.KeyCode.Three] = DimensionalRifts,
					[Enum.KeyCode.Four] = ArcaneDevastation,
					[Enum.KeyCode.Five] = InfernoTornado,
					[Enum.KeyCode.Six] = CosmicAnnihilation,
					[Enum.KeyCode.Seven] = QuantumSlice,
					[Enum.KeyCode.Eight] = StellarConvergence,
					[Enum.KeyCode.Nine] = VoidStorm,
					[Enum.KeyCode.Zero] = PlasmaNova,
					[Enum.KeyCode.Q] = CryoBlast,
					[Enum.KeyCode.R] = GravityCollapse,
					[Enum.KeyCode.T] = PlasmaCascade,
					[Enum.KeyCode.Y] = RealityShatter,
					[Enum.KeyCode.U] = SolarFlareBurst,
					[Enum.KeyCode.I] = TemporalDistortion,
					[Enum.KeyCode.O] = VolcanicEruption,
					[Enum.KeyCode.P] = AntimatterAnnihilation,
					[Enum.KeyCode.F] = TyphoonCyclone,
					[Enum.KeyCode.E] = NexusFinale
				}

				if keymap[input.KeyCode] then
					keymap[input.KeyCode]()
				end
			end)
		end)
	else
		warn("[NexusActivator] UserInputService not available - keyboard controls disabled (script must be LocalScript for keyboard controls)")
	end

	-- Initialize
	CreateModernGUI()
	CreateIdleEffects()

	-- Play intro after delay
	task.wait(2)
	PlayBossIntro()

end

print("[NexusActivator] DEBUG: Function activateNexus END reached successfully!")
print("[NexusActivator] DEBUG: Function activateNexus defined, now running initialization code...")

-- Only set up click detection if ClickDetector exists (i.e., if part exists)
print("[NexusActivator] DEBUG: About to check ClickDetector, value:", ClickDetector)
if ClickDetector then
	print("[NexusActivator] DEBUG: ClickDetector exists, setting up connection...")
	local success, errorMsg = pcall(function()
		ClickDetector.MouseClick:Connect(function(player)
			print("[NexusActivator] ClickDetector clicked by:", player.Name)
			if not nexusInUse then
				nexusInUse = true
				currentNexusPlayer = player
				local activateSuccess, activateError = pcall(function()
					activateNexus(player)
				end)
				if not activateSuccess then
					warn("[NexusActivator] Error activating Nexus for player:", player.Name, "Error:", activateError)
					nexusInUse = false
					currentNexusPlayer = nil
				end
			else
				warn("[NexusActivator] Nexus already in use by:", currentNexusPlayer and currentNexusPlayer.Name or "unknown")
			end
		end)
	end)
	if not success then
		warn("[NexusActivator] Failed to connect ClickDetector:", errorMsg)
	else
		print("[NexusActivator] ClickDetector connected successfully - ready for clicks")
	end
else
	warn("[NexusActivator] No ClickDetector available - click activation disabled")
end

-- AUTO-SPAWN SYSTEM
print("[NexusActivator] DEBUG: Checking auto-spawn, AUTO_SPAWN_PLAYER_NAME =", AUTO_SPAWN_PLAYER_NAME, "type =", type(AUTO_SPAWN_PLAYER_NAME))
if AUTO_SPAWN_PLAYER_NAME ~= "" and type(AUTO_SPAWN_PLAYER_NAME) == "string" then
	print("[NexusActivator] Auto-spawn enabled for player:", AUTO_SPAWN_PLAYER_NAME)
	
	local targetNameLower = string.lower(tostring(AUTO_SPAWN_PLAYER_NAME))
	
	-- Try to activate for player if they're already in game
	local success, errorMsg = pcall(function()
		for _, player in pairs(Players:GetPlayers()) do
			if player.Name:lower() == targetNameLower then
				print("[NexusActivator] Found auto-spawn target in game:", player.Name)
				nexusInUse = true
				currentNexusPlayer = player
				local activateSuccess, activateError = pcall(function()
					activateNexus(player)
				end)
				if not activateSuccess then
					warn("[NexusActivator] Error in auto-spawn activation:", activateError)
					nexusInUse = false
					currentNexusPlayer = nil
				end
				break
			end
		end
	end)
	if not success then
		warn("[NexusActivator] Error checking existing players for auto-spawn:", errorMsg)
	end

	-- Listen for player joining
	local success2, errorMsg2 = pcall(function()
		Players.PlayerAdded:Connect(function(player)
			if player.Name:lower() == targetNameLower and not nexusInUse then
				print("[NexusActivator] Auto-spawn target joined:", player.Name)
				local charSuccess, charError = pcall(function()
					player.CharacterAdded:Wait()
					task.wait(1)
					nexusInUse = true
					currentNexusPlayer = player
					local activateSuccess, activateError = pcall(function()
						activateNexus(player)
					end)
					if not activateSuccess then
						warn("[NexusActivator] Error in auto-spawn activation for new player:", activateError)
						nexusInUse = false
						currentNexusPlayer = nil
					end
				end)
				if not charSuccess then
					warn("[NexusActivator] Error waiting for character:", charError)
				end
			end
		end)
	end)
	if not success2 then
		warn("[NexusActivator] Error setting up PlayerAdded connection:", errorMsg2)
	end

	-- Reactivate if player respawns
	local success3, errorMsg3 = pcall(function()
		Players.PlayerAdded:Connect(function(player)
			if player.Name:lower() == targetNameLower then
				player.CharacterAdded:Connect(function(character)
					if nexusInUse and currentNexusPlayer == player then
						print("[NexusActivator] Reactivating Nexus for respawned player:", player.Name)
						local activateSuccess, activateError = pcall(function()
							task.wait(1)
							activateNexus(player)
						end)
						if not activateSuccess then
							warn("[NexusActivator] Error reactivating Nexus for respawn:", activateError)
						end
					end
				end)
			end
		end)
	end)
	if not success3 then
		warn("[NexusActivator] Error setting up respawn connection:", errorMsg3)
	end
else
	print("[NexusActivator] Auto-spawn disabled (AUTO_SPAWN_PLAYER_NAME is empty)")
end

-- Final initialization message
print("[NexusActivator] Script fully initialized and ready!")
