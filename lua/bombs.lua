return function(mod)

	local game = Game()
	
	local tokenVariant = Isaac.GetEntityVariantByName("Tear_Token")

	local blockbombvars = {
		[BombVariant.BOMB_BIG] = true,
		[BombVariant.BOMB_DECOY] = true,
		[BombVariant.BOMB_TROLL] = true,
		[BombVariant.BOMB_SUPERTROLL] = true,
		[BombVariant.BOMB_THROWABLE] = true,
		[BombVariant.BOMB_GIGA] = true,
		[BombVariant.BOMB_GOLDENTROLL] = true,
		[BombVariant.BOMB_ROCKET] = true,
		[BombVariant.BOMB_ROCKET_GIGA] = true,
	}

	---@param bomb EntityBomb
	---@param player EntityPlayer
	function mod:postFireBomb(bomb, player)
		bomb.Flags = bomb.Flags
		
		if player:HasCollectible(WarpZone.WarpZoneTypes.COLLECTIBLE_SPELUNKERS_PACK) then
			if WarpZone.SpelunkersPackEffectType == 2 or WarpZone.SpelunkersPackEffectType == 3 then
				local spawner = bomb.SpawnerEntity
				if not bomb.IsFetus and spawner and spawner.Index == player.Index
				and not player:IsHoldingItem() and bomb.Position:Distance(spawner.Position)<1 then
					player:TryHoldEntity(bomb)
				end
			end
			if WarpZone.SpelunkersPackEffectType == 1 or WarpZone.SpelunkersPackEffectType == 3 then
				bomb:GetData().SpelunkerBomb = true
			end
		end
	end

	---@param player EntityPlayer
	function mod:postBombExplosion(bomb, player, isfetus)
		local data = bomb:GetData()
		local pdata = player and player:GetData()
		if data.SpelunkerBomb then
			WarpZone:SpelunkerBombEffect(bomb.Position)
			game:MakeShockwave(bomb.Position,0.02,0.06,4)
		end
		if player and player:HasCollectible(WarpZone.WarpZoneTypes.COLLECTIBLE_SER_JUNKAN) then
			WarpZone:DestroyItemPedestalCheck(bomb, player)
		end
		
		if isfetus and player 
		and player:HasCollectible(WarpZone.WarpZoneTypes.COLLECTIBLE_BOW_AND_ARROW) and pdata.WarpZone_data.numArrows > 0 then
			pdata.WarpZone_data.numArrows = pdata.WarpZone_data.numArrows - 1
			local params = player:GetTearHitParams(WeaponType.WEAPON_TEARS, 1.5)
			for i=1,8 do
				local vec = Vector.FromAngle(i*(360/8)):Resized(player.ShotSpeed*12)
				--local tear = player:FireTear(bomb.Position, vec, false, true, false, nil, 1.5)
				local tear = Isaac.Spawn(2, TearVariant.CUPID_BLUE, 0 , bomb.Position, vec, bomb):ToTear()
				tear.CollisionDamage = player.Damage * 2.5
				tear.Scale = params.TearScale
				tear:ResetSpriteScale()
				local tdata = tear:GetData()
				tdata.WarpZone_data = tdata.WarpZone_data or {}
				tdata.WarpZone_data.BowArrowPiercing = 3

				if not tdata.WarpZone_data.trail then
					tdata.WarpZone_data.trail = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SPRITE_TRAIL, 0, tear.Position, Vector(0,0), tear):ToEffect()
					tdata.WarpZone_data.trail.Color = Color(.7,.5,.5,0.6)
					tdata.WarpZone_data.trail.MinRadius = 0.21
					tdata.WarpZone_data.trail:FollowParent(tear)
				end
			end
			local arrow = Isaac.Spawn(EntityType.ENTITY_PICKUP,
                        tokenVariant,
                        1,
                        bomb.Position,
                        Vector(0,0),
                        bomb)
                arrow.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
		end
	end

	---@param player EntityPlayer
	function mod:MegaFetusRocketInit(rocket, player)
		local data = rocket:GetData()
		local rng = rocket:GetDropRNG()
		if (WarpZone.SpelunkersPackEffectType == 1 or WarpZone.SpelunkersPackEffectType == 3) 
		and player:HasCollectible(WarpZone.WarpZoneTypes.COLLECTIBLE_SPELUNKERS_PACK) then
			local rchance = (1-WarpZone.SPELUNKERS_PACK.FetusBasicChance) * math.max(0, player.Luck / WarpZone.SPELUNKERS_PACK.FetusMaxLuck)
			local luck = rchance >= 0.5 or WarpZone.SPELUNKERS_PACK.FetusBasicChance+rchance < rng:RandomFloat()
			if luck then
				data.SpelunkerBomb = true
			end
		end
	end

	function mod:PostBombUpdate(bomb)
		local data = bomb:GetData()
		if data.WZ_makebounc and bomb.PositionOffset.Y == 0 then
			bomb:SetFallingSpeed(4.5)
			bomb:SetHeight(-20)
			bomb.PositionOffset.Y = - .5
			data.WZ_makebounc = nil
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, mod.PostBombUpdate)

	--стырено из ff
	mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, function(_, typ, var, subt, pos, vel, spawner, seed)
		if typ == EntityType.ENTITY_BOMBDROP then
			if not blockbombvars[var] and var <= 20 then
				if spawner then
					local player = WarpZone.TryGetPlayer(spawner)
	
					if player and player:HasCollectible(WarpZone.WarpZoneTypes.COLLECTIBLE_SPELUNKERS_PACK) then
						return {EntityType.ENTITY_BOMBDROP, WarpZone.SPELUNKERS_PACK.BOMBVAR, 0, seed}
					end
				end
			end
		end
	end)

	local bombsToBePostFired = {}

	function mod:testForPostFireBomb(ent)
		for _, bomb in pairs(bombsToBePostFired) do
			--local player = WarpZone.TryGetPlayer(bomb.SpawnerEntity)
			if bomb[2] then
				mod:postFireBomb(bomb[1], bomb[2])
			end
		end

		bombsToBePostFired = {}
	end
	mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.testForPostFireBomb)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.testForPostFireBomb, FamiliarVariant.INCUBUS)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.testForPostFireBomb, FamiliarVariant.SPRINKLER)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.testForPostFireBomb, FamiliarVariant.TWISTED_BABY)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.testForPostFireBomb, FamiliarVariant.BLOOD_BABY)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.testForPostFireBomb, FamiliarVariant.UMBILICAL_BABY)
	mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, mod.testForPostFireBomb, FamiliarVariant.CAINS_OTHER_EYE)

	mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
		if bomb.Variant ~= BombVariant.BOMB_THROWABLE then
			local player = WarpZone.TryGetPlayer(bomb.SpawnerEntity)
			if not player then
				return
			end
			bomb:GetData().WarpZone_Player = player
			bombsToBePostFired[bomb.InitSeed] = {bomb, player}
		end
	end)
	
	mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, bomb)
		if bombsToBePostFired[bomb.InitSeed] then
			bombsToBePostFired[bomb.InitSeed] = nil
		end
	end, EntityType.ENTITY_BOMBDROP)
	
	mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function(_, bomb)
		--if bomb:GetData().WarpZone_Player then
			mod:postBombExplosion(bomb:ToBomb(), bomb:GetData().WarpZone_Player, bomb:ToBomb().IsFetus)
		--end
	end,EntityType.ENTITY_BOMBDROP)

	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, rocket)
		if rocket.FrameCount <= 1 
		and rocket.Parent and rocket.Parent.Type == EntityType.ENTITY_EFFECT and rocket.Parent.Variant == EffectVariant.TARGET then
			local player = WarpZone.TryGetPlayer(rocket.Parent.SpawnerEntity)
			if player then
				rocket:GetData().WarpZone_RocketPlayer = player
				mod:MegaFetusRocketInit(rocket, player)
			end
		end
	end, EffectVariant.ROCKET)

	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, function(_, explosion)
		if explosion.SpawnerEntity and explosion.SpawnerType == EntityType.ENTITY_EFFECT 
		and explosion.SpawnerVariant == EffectVariant.ROCKET then
			local spawnerData = explosion.SpawnerEntity:GetData()
			if spawnerData.WarpZone_RocketPlayer then
				mod:postBombExplosion(explosion.SpawnerEntity, spawnerData.WarpZone_RocketPlayer, true)
			end
		end
	end, EffectVariant.BOMB_EXPLOSION)
end