return function(mod)

	local game = Game()
	local sfx = SFXManager()
	local nilvector = Vector.Zero

    local getAngleDiv = function(a,b)
		local r1,r2
		if a > b then
			r1,r2 = a-b, b-a+360
		else
			r1,r2 = b-a, a-b+360
		end
		return r1>r2 and r2 or r1
	end

    local lerpAngle = function(a, b, t)
        return (a - (((a+180)-b)%360-180)*t) 
    end

    ---@param knife EntityFamiliar
    function WarpZone:RenderJohnnysKnife(knife, renderoffset)
        local player = knife.Player
        local angle = player:GetSmoothBodyRotation()
        local var = knife.Variant == WarpZone.JOHNNYS_KNIVES.ENT.SAD
        local addangle = var and 45 or -45
        if knife.State == 1 then
            local offset = Vector.FromAngle(angle-addangle):Resized(20)
            knife.Velocity = player.Position + knife.Velocity/2 - knife.Position + offset
            if var then
                knife.SpriteRotation = angle - addangle*2
            else
                knife.SpriteRotation = angle + addangle*2
            end
        elseif knife.State == 2 then
            knife.SpriteRotation = knife.Velocity:GetAngleDegrees() - 90
        end
    end

    WarpZone:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, WarpZone.RenderJohnnysKnife, WarpZone.JOHNNYS_KNIVES.ENT.HAPPY)
    WarpZone:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, WarpZone.RenderJohnnysKnife, WarpZone.JOHNNYS_KNIVES.ENT.SAD)

    ---@param knife EntityFamiliar
    function WarpZone:UpdateJohnnysKnife(knife)
        local data = knife:GetData()
        local player = knife.Player
        local var = knife.Variant == WarpZone.JOHNNYS_KNIVES.ENT.SAD

        local useMouse = Options.MouseControl and player.ControllerIndex == 0 and Input.IsMouseBtnPressed(0)

        if not knife.Target and WarpZone.JohnnysKnivesEffectType == 1 then
            knife.FireCooldown = 0
            knife:PickEnemyTarget ( 220, 5, 17, 
                useMouse and (Input.GetMousePosition(true) - player.Position):Normalized() or player:GetShootingJoystick(),
                90 )
        end
        knife.State = 1
        local isshooting = player:GetShootingJoystick():Length()>0.1 or useMouse
        if knife.Target and 
        (WarpZone.JohnnysKnivesEffectType == 2 or isshooting) then

            knife.State = 2
            if knife.FireCooldown <= 0 then
                local knifeAngle = knife.SpriteRotation + 90
                local angleToEnemy = (knife.Target.Position-knife.Position):GetAngleDegrees()
                local raznitsta = getAngleDiv(knifeAngle, angleToEnemy)
                --local newVec = Vector(15 * ((360-math.abs(raznitsta))/180),0):Rotated(knife.SpriteRotation+raznitsta/2)
                local power = math.abs(raznitsta) < 25 and 25 or 15
                if var then power = power + 1 end
                --local newVec = Vector(power,0):Rotated(knifeAngle*0.3 + ((knifeAngle+raznitsta)%360+1) * 0.7)
                local apower = math.min(1, 0.5 - knife.FireCooldown/46 )
                --+ math.min(0.55, math.max(0, (120 - knife.Position:Distance(knife.Target.Position))/ 210) )
                local newVec = Vector(power,0):Rotated(lerpAngle(knifeAngle,angleToEnemy,apower))
                knife.Velocity = knife.Velocity * 0.85 + newVec * 0.15
            else
                knife.Velocity = knife.Velocity:Resized(25)
            end
            if WarpZone.JohnnysKnivesEffectType == 1 and knife.Target.Position:Distance(player.Position) > 320 then
                knife.Target = nil
            end
        elseif player.Position:Distance(knife.Position) > 25 then
            knife.State = 2
            local tarvel = (player.Position-knife.Position):Resized(20)
            knife.Velocity = knife.Velocity * 0.8 + tarvel * 0.2
        end
        knife.FireCooldown = knife.FireCooldown - 1
        if knife.State == 1 then
            knife.FireCooldown = 0
            if Options.MouseControl and player.ControllerIndex == 0 then
                knife.Target = nil
            end
        end

        --[[local room = game:GetRoom()

        iif knife.FrameCount % 5 == 0 then
            local pos = knife.Position
            local grid = room:GetGridEntityFromPos(pos)

            f grid and grid:Hurt(1) then
            end
            for i=0, 360-45, 45 do
                local pos = knife.Position + Vector.FromAngle(i):Resized(10)
                local grid = room:GetGridEntityFromPos(pos)
        
                if grid and grid:Hurt(1) then
                        
                end
            end
        end]]
    end

    WarpZone:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, WarpZone.UpdateJohnnysKnife, WarpZone.JOHNNYS_KNIVES.ENT.HAPPY)
    WarpZone:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, WarpZone.UpdateJohnnysKnife, WarpZone.JOHNNYS_KNIVES.ENT.SAD)

    function WarpZone:OnJohnnyTouch(knife, collider, low)
        if collider and collider:IsVulnerableEnemy() and not collider:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            --local damage = 6
            local damage
			if knife.Player and knife.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
				damage = 12
			else
				damage = 6
			end

            if knife.FireCooldown <= 0 then
                if collider.HitPoints < damage then
                    local creepEntity = Isaac.Spawn(
                        EntityType.ENTITY_EFFECT,
                        EffectVariant.PLAYER_CREEP_RED,
                        0,
                        collider.Position,
                        Vector(0, 0),
                        nil
                    )
                    local massMultiplier = 1 + (collider.Mass or 20)/10
                    --creepEntity:ToEffect().Scale = creepEntity:ToEffect().Scale * massMultiplier
                    creepEntity:ToEffect().Size = creepEntity:ToEffect().Size * massMultiplier
                    creepEntity:GetSprite().Scale = creepEntity:GetSprite().Scale * massMultiplier
                    creepEntity:Update()
                    collider:GetData().WarpZone_KilledJohnny = knife.Player
                end
                if collider.Type ~= 951 then
                    collider:ToNPC():BloodExplode()
                end
                collider:TakeDamage(damage, 0, EntityRef(knife), 0)
                sfx:Play(SoundEffect.SOUND_DEATH_BURST_LARGE)
                knife.FireCooldown = 9
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 4,
                    collider.Position, Vector.Zero, knife):GetSprite().Scale = Vector(.5,.5)
            end
        end
    end

    WarpZone:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, WarpZone.OnJohnnyTouch, WarpZone.JOHNNYS_KNIVES.ENT.HAPPY)
    WarpZone:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, WarpZone.OnJohnnyTouch, WarpZone.JOHNNYS_KNIVES.ENT.SAD)

    --[[function WarpZone:JohnnyKill(ent)
        local data = ent:GetData()
        if data.WarpZone_KilledJohnny and data.WarpZone_KilledJohnny:Exists() then
            local playerdata = data.WarpZone_KilledJohnny:GetData().WarpZone_unsavedata
            playerdata.johnnytearbonus = playerdata.johnnytearbonus and (playerdata.johnnytearbonus + 1) or 1
            playerdata.johnnytearbonus = math.min(playerdata.johnnytearbonus, 20)
            data.WarpZone_KilledJohnny:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            data.WarpZone_KilledJohnny:EvaluateItems()
        end
    end]]
    --WarpZone:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, WarpZone.JohnnyKill)

    WarpZone.DoubleTapCallback[#WarpZone.DoubleTapCallback+1] =
        {function(player, direction)
            if WarpZone.JohnnysKnivesEffectType == 2 then
                --local data = player:GetData()
                local list = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, WarpZone.JOHNNYS_KNIVES.ENT.HAPPY, 0)
                for i=1, #list do
                    local knife = list[i]:ToFamiliar()
                    if knife.Player and knife.Player.Index == player.Index then
                        knife.FireCooldown = 0
                        knife:PickEnemyTarget ( 420, 0, 17, player:GetShootingJoystick(), 90 )
                    end
                end
                local list2 = Isaac.FindByType(EntityType.ENTITY_FAMILIAR, WarpZone.JOHNNYS_KNIVES.ENT.SAD, 0)
                for i=1, #list2 do
                    local knife = list2[i]:ToFamiliar()
                    if knife.Player and knife.Player.Index == player.Index then
                        knife.FireCooldown = 0
                        knife:PickEnemyTarget ( 420, 0, 17, player:GetShootingJoystick(), 90 )
                    end
                end
            end
        end,50}

end