--
if SERVER then
    AddCSLuaFile()
end
hook.Add("OnEntityCreated", "Slenderman_gentoi_noodles_pill_initialize", function(ent)
    timer.Simple(0.1, function()
        if !IsValid(ent) then return end
        if ent:GetClass() == "pill_ent_costume" then
            if ent.formTable then

                local PuppetEntity = ent:GetPuppet()
                local entityply = ent:GetPillUser()
                local hookName = "Pill_pill_Noodles_Slenderman_gentoi" .. ent:EntIndex()

                if ent.formTable.think_noodles_slenderman_gentoi_pill then
                    hook.Add("Think", hookName, function()
                        if not IsValid(ent) then
                            hook.Remove("Think", hookName)
                            return
                        end

                        local ply = ent:GetPillUser()
                        local puppet = ent:GetPuppet()

                        if not IsValid(puppet) or not IsValid(ply) then
                            hook.Remove("Think", hookName)
                            return
                        end

                        ent.formTable.think_noodles_slenderman_gentoi_pill(ply, ent)
                    end)
                end

                if ent.formTable.noodles_Slenderman_gentoi_initialize then



                    local tablevarable = {["player"] = entityply, ["entity"] = ent, ["puppet"] = PuppetEntity}
                    timer.Simple(0.01, function()
                        if !IsValid(ent) then return end
                        ent.formTable:noodles_Slenderman_gentoi_initialize(tablevarable,tablevarable,tablevarable)
                    end)

                    hook.Add("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex(), function(ply) if entityply == ply then return true end end)

                    ent:CallOnRemove("RemoveHook_OM"..ent:EntIndex(), function()
                        hook.Remove("PlayerFootstep", "DisableFootstepID_OM:".. ent:EntIndex())
                        ent.formTable:noodles_Slenderman_gentoi_OnRemove(tablevarable,tablevarable,tablevarable)
                    end)



                    local self = ent


                    local ply = self:GetPillUser()
                    local hull = self.formTable.hull or Vector(32, 32, 72)
                    local duckBy = self.formTable.duckBy or (self.formTable.hull and 0 or 36)
                    ply:SetHull(-Vector(hull.x / 2, hull.y / 2, 0), Vector(hull.x / 2, hull.y / 2, hull.z))
                    ply:SetHullDuck(-Vector(hull.x / 2, hull.y / 2, 0), Vector(hull.x / 2, hull.y / 2, hull.z - duckBy or 0))--
                    ply:SetRenderMode(RENDERMODE_NONE)

                    if SERVER then

                        ply:Freeze(false)
                        ply:SetNotSolid(false)
                        ply:DrawViewModel(false)

                        local camOffset = Vector(0, 0, 100)
                        --clside this?
                        ply:SetStepSize(hull.z / 4)
                        ply:SetViewOffset(camOffset)
                        ply:SetViewOffsetDucked(camOffset - Vector(0, 0, duckBy*0.15) )
                        self:ApplyMoveSpeed()
                    end

                    local firsttime = false
                    ent.Think = function()
                        local currentanim = 'idle'
                        local ply = self:GetPillUser()
                        local puppet = self:GetPuppet()
                        if not IsValid(puppet) or not IsValid(ply) then return end
                        local vel = ply:GetVelocity():Length()

                        if SERVER then
                            --Anims
                            local anims = table.Copy(self.formTable.anims.default or {})
                            table.Merge(anims, (IsValid(ply:GetActiveWeapon()) and self.formTable.anims[ply:GetActiveWeapon():GetHoldType()]) or (self.forceAnimSet and self.formTable.anims[self.forceAnimSet]) or {})
                            local anim
                            --local useSeqVel=true
                            local overrideRate

                            if (not self.anim or not anims[self.anim]) then
                                self.animFreeze = nil
                                self.animStart = nil
                            end


                            if self.animFreeze and not self.plyFrozen then
                                self:ApplyMoveSpeed()
                                self.plyFrozen = true
                            elseif not self.animFreeze and self.plyFrozen then
                                self:ApplyMoveSpeed()
                                self.plyFrozen = nil
                            end

                            if self.anim and anims[self.anim] then
                                anim = anims[self.anim]
                                overrideRate = anims[self.anim .. "_rate"] or 1
                                local cycle = puppet:GetCycle()

                                if not self.animStart then
                                    if cycle == 1 or (self.animCycle and self.animCycle > cycle) or (string.lower(anim) ~= string.lower(puppet:GetSequenceName(puppet:GetSequence()))) then
                                        self.anim = nil
                                        self.animCycle = nil

                                        if self.animFreeze then
                                            self.animFreeze = nil
                                        end
                                    elseif self.animCycle then
                                        self.animCycle = cycle
                                    end
                                end
                            elseif self.tickAnim and anims[self.tickAnim] then
                                anim = anims[self.tickAnim]
                                overrideRate = anims[self.tickAnim .. "_rate"] or 1
                                self.tickAnim = nil
                            elseif self.burrowed then
                                anim = anims["burrow_loop"]
                            elseif ply:WaterLevel() > 2 then
                                anim = anims["swim"] or anims["glide"] or anims["idle"]
                            elseif ply:IsOnGround() then
                                if ply:Crouching() then
                                    if vel > ply:GetCrouchedWalkSpeed() / 4 then
                                        anim = anims["crouch_walk"] or anims["crouch"] or anims["walk"] or anims["idle"]
                                    else
                                        anim = anims["crouch"] or anims["idle"]
                                    end
                                else
                                    if vel > (ply:GetWalkSpeed() + ply:GetRunSpeed()) / 2 then
                                        anim = anims["run"] or anims["walk"] or anims["idle"]
                                    elseif vel > ply:GetWalkSpeed() / 4 then
                                        anim = anims["walk"] or anims["idle"]
                                    else
                                        anim = anims["idle"]
                                    end
                                end
                            else
                                anim = anims["glide"] or anims["idle"]
                            end

                            if anim == anims["idle"] or anim == anims["crouch"] then
                                overrideRate = 1
                            end
                            self:SetNWString("Animlastplayed", anim)

                            local ShouldAlternate = table.Copy(self.formTable.anims.ShouldAlternate or {})
                            if type(ShouldAlternate[anim]) == "function" and ShouldAlternate[anim](self) then
                                if ShouldAlternate[anim](self) ~= nil and isstring(ShouldAlternate[anim](self)) then
                                    
                                    anim = ShouldAlternate[anim](self)
                                end
                            end

                            if (anim and puppet:GetSequence() ~= puppet:LookupSequence(anim)) or self.animStart or (self.formTable.autoRestartAnims and puppet:GetCycle() == 1) then


                                puppet:ResetSequence(puppet:LookupSequence(anim))
                                puppet:SetCycle(0)
                                self.animCycle = 0
                            end

                            self.animStart = nil
                            local seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                            --if true then
                            if self.formTable.movePoseMode ~= "xy" and self.formTable.movePoseMode ~= "xy-bot" and not overrideRate then
                                local rate = overrideRate or vel / seq_vel

                                --goofy limitation (floods console with errors if above 12!)
                                if rate > 12 then
                                    rate = 12
                                end

                                puppet:SetPlaybackRate(rate)
                            else
                                --puppet:SetPlaybackRate(1)
                            end

                            --print(puppet:GetCycle())
                            if self.formTable.movePoseMode then
                                --
                                if self.formTable.movePoseMode == "yaw" then
                                    local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                    puppet:SetPoseParameter("move_yaw", move_dir.y)
                                elseif self.formTable.movePoseMode == "xy" then
                                    if not overrideRate then
                                        local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                        local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                        local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                        puppet:SetPoseParameter("move_x", clampedvel.x)
                                        puppet:SetPoseParameter("move_y", -clampedvel.y)
                                        seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                        if seq_vel ~= 0 then
                                            puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                        end
                                        --print(puppet:GetPlaybackRate())
                                    else
                                        puppet:SetPoseParameter("move_x", 0)
                                        puppet:SetPoseParameter("move_y", 0)
                                    end
                                elseif self.formTable.movePoseMode == "xy-bot" then
                                    if not overrideRate then
                                        local localvel = ply:WorldToLocal(ply:GetPos() + ply:GetVelocity())
                                        local maxdim = math.Max(math.abs(localvel.x), math.abs(localvel.y))
                                        local clampedvel = maxdim == 0 and Vector(0, 0, 0) or localvel / maxdim
                                        local move_dir = puppet:WorldToLocalAngles(ply:GetVelocity():Angle())
                                        puppet:SetPoseParameter("move_x", clampedvel.x)
                                        puppet:SetPoseParameter("move_y", -clampedvel.y)
                                        puppet:SetPoseParameter("move_yaw", move_dir.y)
                                        puppet:SetPoseParameter("move_scale", 1)
                                        seq_vel = puppet:GetSequenceGroundSpeed(puppet:GetSequence())

                                        if seq_vel ~= 0 then
                                            puppet:SetPoseParameter("move_x", math.Clamp(localvel.x / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_y", math.Clamp(-localvel.y / seq_vel, -.99, .99))
                                            puppet:SetPoseParameter("move_scale", math.Clamp(localvel:Length() / seq_vel, -.99, .99))
                                        end
                                        --print(puppet:GetPlaybackRate())
                                    else
                                        puppet:SetPoseParameter("move_x", 0)
                                        puppet:SetPoseParameter("move_y", 0)
                                        puppet:SetPoseParameter("move_yaw", 0)
                                        puppet:SetPoseParameter("move_scale", 0)
                                    end
                                end
                            end

                            --Aimage
                            if self.formTable.aim then
                                if self.formTable.aim.xPose then
                                    local yaw = math.AngleDifference(ply:EyeAngles().y, puppet:GetAngles().y)

                                    if self.formTable.aim.xInvert then
                                        yaw = -yaw
                                    end

                                    puppet:SetPoseParameter(self.formTable.aim.xPose, yaw)
                                end

                                if self.formTable.aim.yPose then
                                    local pitch = math.AngleDifference(ply:EyeAngles().p, puppet:GetAngles().p)

                                    if self.formTable.aim.yInvert then
                                        pitch = -pitch
                                    end

                                    puppet:SetPoseParameter(self.formTable.aim.yPose, pitch)
                                end
                            end

                            --tick attack
                            if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "tick" then
                                self.formTable.attack.func(ply, self, self.formTable.attack)
                            end

                            if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "tick" then
                                self.formTable.attack2.func(ply, self, self.formTable.attack2)
                            end

                            --auto attack
                            if ply:KeyDown(IN_ATTACK) and self.formTable.attack and self.formTable.attack.mode == "auto" then
                                if not self.formTable.aim then
                                    self:PillLoopSound("attack")
                                else
                                    self:PillLoopStop("attack")
                                end

                                if (not self.lastAttack or (self.formTable.attack.interval or self.formTable.attack.delay) < CurTime() - self.lastAttack) then
                                    self.formTable.attack.func(ply, self, self.formTable.attack)
                                    self.lastAttack = CurTime()
                                end
                            else
                                self:PillLoopStop("attack")
                            end

                            if ply:KeyDown(IN_ATTACK2) and self.formTable.attack2 and self.formTable.attack2.mode == "auto" then
                                if not self.formTable.aim then
                                    self:PillLoopSound("attack2")
                                else
                                    self:PillLoopStop("attack2")
                                end

                                if not self.lastAttack2 or (self.formTable.attack2.interval or self.formTable.attack2.delay) < CurTime() - self.lastAttack2 then
                                    self.formTable.attack2.func(ply, self, self.formTable.attack2)
                                    self.lastAttack2 = CurTime()
                                end
                            else
                                self:PillLoopStop("attack2")
                            end

        if not self.formTable.hideWeapons then
            local realWep = self:GetPillUser():GetActiveWeapon()

            --&&self:GetPillUser()!=ply or pk_pills.var_thirdperson:GetBool()) then
            if IsValid(realWep) and realWep:GetModel() ~= "" then
                --hiding the real thing [BROKEN]
                --[[if realWep:GetRenderMode()!=RENDERMODE_NONE then
                    realWep:SetRenderMode(RENDERMODE_NONE)
                end]]
                if realWep.pill_attachment then
                    if IsValid(self.wepmdl) then
                        self.wepmdl:Remove()
                    end

                    self.wepmdl = ents.Create("pill_attachment_wep")
                    self.wepmdl:SetParent(self:GetPuppet())
                    self.wepmdl:SetModel(realWep:GetModel())
                    self.wepmdl.attachment = realWep.pill_attachment
                    self.wepmdl:Spawn()

                    if realWep.pill_offset then
                        self.wepmdl:SetWepOffset(realWep.pill_offset)
                    end

                    if realWep.pill_angle then
                        self.wepmdl:SetWepAng(realWep.pill_angle)
                    end

                    realWep.pill_proxy = self.wepmdl
                elseif not IsValid(self.wepmdl) then
                    self.wepmdl = ents.Create("pill_attachment_wep")
                    self.wepmdl:SetParent(self:GetPuppet())
                    self.wepmdl:SetModel(realWep:GetModel())
                    self.wepmdl:Spawn()
                    realWep.pill_proxy = self.wepmdl
                elseif self.wepmdl:GetModel() ~= realWep:GetModel() then
                    self.wepmdl:SetModel(realWep:GetModel())
                end
            elseif IsValid(self.wepmdl) then
                self.wepmdl:Remove()
            end
        end
                        else
                            local realWep = self:GetPillUser():GetActiveWeapon()

                            if IsValid(realWep) and realWep:GetModel() ~= "" and not realWep:GetNoDraw() then
                                realWep:SetNoDraw(true)
                            end
                            if self:GetPillUser() ~= LocalPlayer() or pk_pills.convars.cl_thirdperson:GetBool() then
                                puppet:SetNoDraw(false)
                                if IsValid(self:GetPuppet()) then
                                    if IsValid(self:GetNWEntity("Armtenticle_entity_1")) then
                                        self:GetPuppet():SetBodygroup(0,1)
                                    else
                                        self:GetPuppet():SetBodygroup(0,0)
                                    end
                                    if IsValid(self:GetNWEntity("Armtenticle_entity_2")) then
                                        self:GetPuppet():SetBodygroup(1,1)
                                    else
                                        self:GetPuppet():SetBodygroup(1,0)
                                    end
                                    if IsValid(self:GetNWEntity("Armtenticle_entity_3")) then
                                        self:GetPuppet():SetBodygroup(2,1)
                                    else
                                        self:GetPuppet():SetBodygroup(2,0)
                                    end
                                    if IsValid(self:GetNWEntity("Armtenticle_entity_1=4")) then
                                        self:GetPuppet():SetBodygroup(3,1)
                                    else
                                        self:GetPuppet():SetBodygroup(3,0)
                                    end
                                    self:GetPuppet():SetBodygroup(4,0)
                                    self:GetPuppet():SetBodygroup(5,0)
                                end
                            else
                                puppet:SetNoDraw(false)
                                if self:GetNWInt("Slenderman1stperson") < CurTime() and !IsValid(ent:GetNWEntity("flyingent")) and !IsValid(self:GetNWEntity("gentoi_slenderman_target")) then
                                    if IsValid(self:GetPuppet()) then
                                        self:GetPuppet():SetBodygroup(0,1)
                                        self:GetPuppet():SetBodygroup(1,1)
                                        self:GetPuppet():SetBodygroup(2,1)
                                        self:GetPuppet():SetBodygroup(3,1)
                                        self:GetPuppet():SetBodygroup(4,1)
                                        self:GetPuppet():SetBodygroup(5,1)
                                    end
                                else

                                    if IsValid(self:GetPuppet()) then
                                        if IsValid(self:GetNWEntity("Armtenticle_entity_1")) then
                                            self:GetPuppet():SetBodygroup(0,1)
                                        else
                                            self:GetPuppet():SetBodygroup(0,0)
                                        end
                                        if IsValid(self:GetNWEntity("Armtenticle_entity_2")) then
                                            self:GetPuppet():SetBodygroup(1,1)
                                        else
                                            self:GetPuppet():SetBodygroup(1,0)
                                        end
                                        if IsValid(self:GetNWEntity("Armtenticle_entity_3")) then
                                            self:GetPuppet():SetBodygroup(2,1)
                                        else
                                            self:GetPuppet():SetBodygroup(2,0)
                                        end
                                        if IsValid(self:GetNWEntity("Armtenticle_entity_1=4")) then
                                            self:GetPuppet():SetBodygroup(3,1)
                                        else
                                            self:GetPuppet():SetBodygroup(3,0)
                                        end
                                        self:GetPuppet():SetBodygroup(4,0)
                                        self:GetPuppet():SetBodygroup(5,0)
                                    end
                                end
                            end
                        end

                        --Align pos and angles with player
                        if SERVER then
                            puppet:SetPos(ply:GetPos())
                        else
                            puppet:SetRenderOrigin(ply:GetPos())
                        end
                        
                        currentanim = self:GetNWString("Animlastplayed")

                        --if vel > 0 or math.abs(math.AngleDifference(puppet:GetAngles().y, ply:EyeAngles().y)) > 350 then

                        local animsshouldspn = table.Copy(self.formTable.anims.ShouldMoveRotate or {})
                        if animsshouldspn[currentanim] or (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) then
                                                        
                            local typeofitem = (type(animsshouldspn[currentanim]) == "function" and animsshouldspn[currentanim](self)) or animsshouldspn[currentanim]

                            local function SetTargetAngle(ang)
                                ang.p = 0
                                puppet:SetNW2Vector("SyncAng", ang:Forward())
                            end

                            local function GetTargetAngle()
                                local dir = puppet:GetNW2Vector("SyncAng")
                                if not dir or dir == vector_origin then return nil end
                                local ang = dir:Angle()
                                if not ang then return nil end
                                ang.p = 0
                                return ang
                            end

                            if typeofitem == "notshftlock" then
                                local dir = ply:GetVelocity():GetNormalized()
                                local aheadPos = ply:GetPos() + dir * 5
                                local ang = (aheadPos - ply:GetPos()):Angle()
                                ang.p = 0

                                if SERVER then
                                    SetTargetAngle(ang)
                                    puppet:SetAngles(ang)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end
                            elseif typeofitem == "assignedagnles_instant" then
                                local targetAng = self:GetNWAngle("pill_assignedangle")

                                if SERVER then
                                    SetTargetAngle(targetAng)
                                    puppet:SetAngles(targetAng)
                                end

                                if CLIENT then
                                    if targetAng then
                                        puppet:SetRenderAngles(targetAng)
                                    end
                                end

                            elseif typeofitem == "shiftlock" then
                                local angs = ply:EyeAngles()
                                angs.p = 0

                                if SERVER then
                                    SetTargetAngle(angs)
                                    puppet:SetAngles(angs)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "Playerangles" then
                                local angs = ply:GetAngles()
                                angs.p = 0

                                if SERVER then
                                    SetTargetAngle(angs)
                                    puppet:SetAngles(angs)
                                end

                                if CLIENT then
                                    local targetAng = GetTargetAngle()
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "assignedagnles" then
                                local targetAng = self:GetNWAngle("pill_assignedangle")

                                if SERVER then
                                    SetTargetAngle(targetAng)
                                    puppet:SetAngles(targetAng)
                                end

                                if CLIENT then
                                    if targetAng then
                                        local curAng = puppet:GetRenderAngles()
                                        if not curAng then curAng = targetAng end
                                        if not curAng.p then curAng = Angle(0,0,0) end
                                        local smoothAng = LerpAngle(FrameTime() * 10, curAng, targetAng)
                                        puppet:SetRenderAngles(smoothAng)
                                    end
                                end

                            elseif typeofitem == "notanything" then
                            end
                        end

                        self:NextThink(CurTime())

                        return true
                    end
                end
                if ent.formTable.HandleAnimEvent_Noodles_Slenderman_Gentoi_pill then
                    local PuppetEntity = ent:GetPuppet()
                    local entityply = ent:GetPillUser()

                    if IsValid(PuppetEntity) then
                        function PuppetEntity:AcceptInput(inputName, activator, caller, data)
                            ent.formTable.HandleAnimEvent_Noodles_Slenderman_Gentoi_pill(entityply, ent, inputName)
                            return true
                        end
                    end
                end
            end
        end
    end)
end)



hook.Add("PlayerButtonDown", "ActivateKeybind_Slenderman_gentoi_pills", function(ply, button)
    local pillentity = ply.pk_pill_ent
    if IsValid(pillentity) then
        if pillentity.formTable.noodles_Slenderman_gentoi_keybinds then
            pillentity.formTable.noodles_Slenderman_gentoi_keybinds(ply, pillentity, button)
        end
    end
    local ent = ply:GetNWEntity("gentoi_slenderman_host")
    if IsValid(ent) then

        ply:SetNWFloat("PressIcon_SlendermanPill_gentoi", CurTime()+0.25 )
        if ent:GetNWInt("GameTollerance_Slendermanside") < -50 then
            ent:SetNWInt("GameTollerance_Slendermanside", -50 )
        else
            ent:SetNWInt("GameTollerance_Slendermanside", ent:GetNWInt("GameTollerance_Slendermanside") - 2.5 )
        end
    end
end)

local function AdvancedPillSound(SoundData, ent)
    if SERVER then
        if IsValid(ent) then
            SoundData = SoundData or {}
            SoundData.stringe = SoundData.stringe or {}
            SoundData.soundLevel = SoundData.soundLevel or 75
            SoundData.pitchPercent = SoundData.pitchPercent or 100
            SoundData.volume = SoundData.volume or 1
            SoundData.channel = SoundData.channel or CHAN_AUTO
            SoundData.soundFlags = SoundData.soundFlags or 0
            SoundData.dsp = SoundData.dsp or 0
            SoundData.filter = SoundData.filter or nil

            local chosenSound = SoundData.stringe

            if istable(SoundData.stringe) then
                local index = math.random(1, #SoundData.stringe)
                chosenSound = SoundData.stringe[index]
            end

            ent:EmitSound(
                chosenSound,
                SoundData.soundLevel,
                SoundData.pitchPercent,
                SoundData.volume,
                SoundData.channel,
                SoundData.soundFlags,
                SoundData.dsp,
                SoundData.filter
            )
        end
        return true
    end
end

hook.Add("SetupMove", "DisablePlayerMovement_gentoi_Slenderman", function(ply, mv, cmd)
    if ply:GetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun") >= CurTime() or ply:GetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun2") >= CurTime() then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
end)




local function racheljackietien_jumpscare(ply, ent, duration, customanimstuff)
    if SERVER then
        if not ent.IsInJumpscare then ent.IsInJumpscare = 0 end
        if ent.IsInJumpscare >= CurTime() then return end
        if not ent.IsInJumpscareCooldown then ent.IsInJumpscareCooldown = 0 end
        if ent.IsInJumpscareCooldown >= CurTime() then return end

        local jumpscare_entity = nil

if SherlockHNS then
    jumpscare_entity = SherlockHNS.FindVictim(ply, ent:LocalToWorld(Vector(0, 0, 50)), 90)
else
    for _, ent2 in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 90)) do
                if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
                    if ent2 == ply then continue end
                    if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end
    
                    if IsValid(ent2) then
                        jumpscare_entity = ent2
                        break
                    end
                end
            end
end

if SherlockHNS and IsValid(jumpscare_entity) and jumpscare_entity:IsPlayer() then
            return pk_pills.playHNSJumpscare(ply, ent, jumpscare_entity, duration, {
                camera = "gentoi_Slenderman_cam",
                onStart = customanimstuff,
            })
        end

        if jumpscare_entity ~= nil then
            
            ent.JuumpscareStart = CurTime()

            ent.jumpscare_entity = jumpscare_entity
            ent.entitylastpos = jumpscare_entity:GetPos()
            ent.entitylastang = jumpscare_entity:GetAngles()

            local targetAngle = (ply:GetPos() - jumpscare_entity:GetPos()):Angle()

            targetAngle.p = 0
            targetAngle.r = 0

            ply:SetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun", duration+CurTime())
            jumpscare_entity:SetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun", duration+CurTime())

            ent.IsInJumpscare = CurTime() + duration

            local puppet = ent:GetPuppet()

            if jumpscare_entity:IsPlayer() then
                net.Start('gentoi_Slenderman_cam')
                net.WriteEntity(puppet)
                net.WriteBool(true)
                net.Send(jumpscare_entity)
            else
                jumpscare_entity:NextThink(duration+0.1+CurTime())
            end

            ent:SetNWInt("Slenderman1stperson", CurTime()+duration)
            timer.Simple(duration,function()
                if !IsValid(ent) then return end
                ent:SetNWInt("Slenderman1stperson", CurTime()-1)
            end)
            
            jumpscare_entity:AddFlags(FL_NOTARGET)
            ent:CallOnRemove("RachelJumpscare"..ent:EntIndex(), function()
                if !IsValid(jumpscare_entity) then return end

                jumpscare_entity:RemoveFlags(FL_NOTARGET)
                ent.jumpscare_entity = nil

                if jumpscare_entity:IsPlayer() then
                    net.Start('gentoi_Slenderman_cam')
                    net.WriteEntity(puppet)
                    net.WriteBool(false)
                    net.Send(jumpscare_entity)
                else
                    jumpscare_entity:NextThink(CurTime())
                end
                jumpscare_entity:SetPos(ent.entitylastpos)
                jumpscare_entity:SetAngles(ent.entitylastang)
                jumpscare_entity:SetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun", CurTime())
            end)

            customanimstuff()
        end
    end
end


local function tracefuntion(pilluser, nearbycharacters,functionth)
    if SERVER then
        local intir = 0
        local enttable = {}
        local list = SherlockHNS and player.GetAll() or ents.GetAll()

        for _, v in ipairs(list) do
            if not IsValid(v) or v == pilluser then continue end
            if not (v:IsPlayer() or v:IsNextBot() or v:IsNPC()) then continue end

            if v:IsPlayer() and (
                not v:Alive()
                or v:Team() == TEAM_SPECTATOR
                or (SherlockHNS and type(SherlockHNS.IsBystander) == "function" and SherlockHNS.IsBystander(v))
            ) then
                continue
            end

            if v:GetClass() == "pill_puppet" then continue end
            if not pilluser:Visible(v) then continue end

            if nearbycharacters then
                v:SetNWFloat("ambianceAmount_slenderman_gentoi", CurTime() + 0.2)
                table.insert(enttable, v)
            else
                local formula = (v:EyeAngles():Forward():Dot(pilluser:EyePos() - v:EyePos()) / (pilluser:EyePos() - v:EyePos()):Length() >= 0.5)
                if formula then
                    v:SetNWFloat("ChangeAmount_slenderman_gentoi", CurTime() + 0.2)
                    intir = 1 + intir
                    table.insert(enttable, v)
                end
            end
        end

        functionth(intir, enttable)
    end
end

local function HandleBar_Slenderman(PillEnt, Amount)
    local goingdown = 'None'

    if Amount > 0 then goingdown = "Add" elseif Amount < 0 then goingdown = "Subtract" end
    if goingdown == "None" then return end
    if ( goingdown == "Add" and PillEnt:GetNWFloat('Bar_Slenderman_Gentoi') + Amount < 100 ) or ( goingdown == "Subtract" and PillEnt:GetNWFloat('Bar_Slenderman_Gentoi') + Amount > 0 ) then 
        PillEnt:SetNWFloat("Bar_Slenderman_Gentoi", PillEnt:GetNWFloat('Bar_Slenderman_Gentoi') + Amount)
        return (PillEnt:GetNWFloat('Bar_Slenderman_Gentoi'))
    else
        if goingdown == "Add" then
            PillEnt:SetNWFloat("Bar_Slenderman_Gentoi", 100)
        elseif goingdown == "Subtract" then
            PillEnt:SetNWFloat("Bar_Slenderman_Gentoi", 0)

        end
    end

end

local function drgtopilltrace(ply, ent, view, option)
    if not SERVER then return end
    if not IsValid(ply) or not IsValid(ent) then return end

    option = option or {}
    view = view or {}

    local normal = ply:EyeAngles():Forward()
    normal.z = 0
    normal = normal:GetNormalized()

    local normalright = normal:Angle():Right()

    local origin = ply:WorldSpaceCenter()
    local offset = view.offset or Vector(0, 0, 0)

    local startPos = origin + normal * offset.x + normalright * offset.y + Vector(0, 0, 1) * offset.z

    local tr1 = util.TraceLine({
        start = origin,
        endpos = startPos,
        filter = ply
    })

    local origin2 = tr1.HitPos
    local distance = view.dist or 50

    local tr2 = util.TraceLine({
        start = origin2,
        endpos = origin2 - normal * distance,
        filter = ply
    })

    local eyeAng = ply:EyeAngles()

    local traceData = {
        start = tr2.HitPos,
        endpos = tr2.HitPos + eyeAng:Forward() * 999999999,
        filter = {ply, ent}
    }

    for k, v in pairs(option) do
        traceData[k] = v
    end

    return util.TraceLine(traceData)
end


pk_pills.packStart("Slenderman", "AnalogHorrorPills_gentio_slenderman", "pills/PIll_slenderman_gentoi.png")

pk_pills.register('PIll_slenderman_gentoi', {

    printName='Slenderman',
        
    model="models/gentoi/anologhorror/Slenderman.mdl",
    
    modelScale='1',

    noragdoll = true,
    muteSteps = true,
    noragdoll=true,
    health=9000,
    type='ply',
        

    ThirdPersonBone = {
        'LowerTorso',
        0,
        30,
        15,
    },
    
    SlendermanCam = true,
    anims={
        default={
            idle="idle",
            run="run",
            walk="walk",
            kill="kill",
        },

        ShouldMoveRotate={
            idle= function(ent) 
                if ent:GetNWBool("Arm_tenticle_1") or ent:GetNWBool("Arm_tenticle_2") or ent:GetNWBool("Arm_tenticle_3") or ent:GetNWBool("Arm_tenticle_4") or IsValid(ent:GetNWEntity("Armtenticle_entity_1")) or IsValid(ent:GetNWEntity("Armtenticle_entity_2")) or IsValid(ent:GetNWEntity("Armtenticle_entity_3")) or IsValid(ent:GetNWEntity("Armtenticle_entity_4")) then
                    return 'notanything'
                end
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return "shiftlock"
            end,
            run= function(ent) 
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            walk= function(ent) 
                if ent:GetNWBool("Shiftlock") then return 'shiftlock' end
                return 'notshftlock'
            end,
            kill= function(ent) 
                return 'notanything'
            end,
        },

        ShouldAlternate={
            run= function(ent) 
                local alpha = ent:GetPuppet():GetColor().a or 255
                if alpha < 255 * 0.85 then
                    return "idle"
                end
            end,
            walk= function(ent) 
                local alpha = ent:GetPuppet():GetColor().a or 255
                if alpha < 255 * 0.85 then
                    return "idle"
                end
            end,
        },
    },
    

    moveSpeed = {
        walk = 45,
        run = 420,
        ducked= 120,
    },
    camera={
        offset = Vector(0, 0, 50),
        dist=130,
    },
        
    jumpPower=0,
        
    
    movePoseMode="xy",

    aim={
        xPose="aim_yaw",
        yPose="aim_pitch",
        nocrosshair = true
    },
        
    --canAim=function(ply,ent) return ent.active end,     

    HandleAnimEvent_Noodles_Slenderman_Gentoi_pill = function(ply, ent, event)
        if event == 'ragdoll' then

            if !IsValid(ent) then return end
            local jumpscare_entity = ent.jumpscare_entity
            if !(IsValid(jumpscare_entity)) then return end

            local ragdoll = ents.Create("prop_ragdoll")
            ragdoll:SetModel(jumpscare_entity:GetModel())
            ragdoll:SetPos(jumpscare_entity:GetPos())
            ragdoll:SetAngles(jumpscare_entity:GetAngles())
            ragdoll:SetSkin(jumpscare_entity:GetSkin() or 0)
            ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
            ragdoll:Spawn()


            local physCount = ragdoll:GetPhysicsObjectCount()
            if physCount <= 0 then
                ragdoll:Remove()
                return end

            if not jumpscare_entity:IsPlayer() then
                local wep = jumpscare_entity:GetActiveWeapon()
                if IsValid(wep) then
                    jumpscare_entity.OldWeapon = wep
                    wep:SetNoDraw(true)
                end
            end

            if jumpscare_entity.GetBodyGroups then
                for _, bg in ipairs(jumpscare_entity:GetBodyGroups()) do
                    ragdoll:SetBodygroup(bg.id, jumpscare_entity:GetBodygroup(bg.id))
                end
            end

            if jumpscare_entity.GetPlayerColor and ragdoll.SetPlayerColor then
                ragdoll:SetPlayerColor(jumpscare_entity:GetPlayerColor())
            end

            if jumpscare_entity.GetColor then
                ragdoll:SetColor(jumpscare_entity:GetColor())
            end

            if jumpscare_entity.GetMaterial then
                ragdoll:SetMaterial(jumpscare_entity:GetMaterial())
            end

            if ragdoll.GetNumSubMaterials and ragdoll.SetSubMaterial and jumpscare_entity.GetSubMaterial then
                for i = 0, ragdoll:GetNumSubMaterials() - 1 do
                    local sub = jumpscare_entity:GetSubMaterial(i)
                    if sub then
                        ragdoll:SetSubMaterial(i, sub)
                    end
                end
            end

            jumpscare_entity:SetNoDraw(true)
            jumpscare_entity:SetNotSolid(true)

            ent.CurrentJumpscareRagdoll = ragdoll
            ent:DeleteOnRemove(ragdoll)

            hook.Add("Think", "ragdoll_nosey".. ent:EntIndex(), function()
                if !IsValid(ragdoll) then return end
                if SERVER then
                    local headPhys = nil

                    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                        local phys = ragdoll:GetPhysicsObjectNum(i)
                        if IsValid(phys) then
                            local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                            local boneName = ragdoll:GetBoneName(boneIndex) or ""
                            if string.find(string.lower(boneName), "head") then
                                headPhys = phys
                                break
                            end
                        end
                    end

                    if !IsValid(headPhys) then
                        headPhys = ragdoll:GetPhysicsObject()
                    end

                    if IsValid(headPhys) then
                        local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))
                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos)
                        headPhys:SetPos(cam.Pos)
                        headPhys:SetAngles(cam.Ang)

                        headPhys:Wake()
                    end
                end
            end)
        end

        if event == "throw" then
            if ent.CurrentJumpscareRagdoll then
                if IsValid(ent.CurrentJumpscareRagdoll) then
                    ent:DontDeleteOnRemove(ent.CurrentJumpscareRagdoll)

                    local ragdoll = ent.CurrentJumpscareRagdoll
                    local headPhys = nil

                    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
                        local phys = ragdoll:GetPhysicsObjectNum(i)
                        if IsValid(phys) then
                            local boneIndex = ragdoll:TranslatePhysBoneToBone(i)
                            local boneName = ragdoll:GetBoneName(boneIndex) or ""
                            if string.find(string.lower(boneName), "head") then
                                headPhys = phys
                                break
                            end
                        end
                    end

                    if !IsValid(headPhys) then
                        headPhys = ragdoll:GetPhysicsObject()
                    end

                    if IsValid(headPhys) then
                        headPhys:SetVelocity(ent:GetPuppet():GetForward()*300000)
                        headPhys:Wake()
                    end
                end
            end
            hook.Remove('Think', "ragdoll_nosey".. ent:EntIndex())
        end

        if event == "Step" then
            if ent:GetPuppet():GetSequenceName(ent:GetPuppet():GetSequence()) == "run" then
                --[[
                AdvancedPillSound({
                    stringe = {
                        "redrawn/bendy/Redrawn_steprunning1.wav",
                        "redrawn/bendy/Redrawn_steprunning2.wav",
                        "redrawn/bendy/Redrawn_steprunning3.wav",
                        "redrawn/bendy/Redrawn_steprunning4.wav"
                    },
                    soundLevel = 79
                }, ent)]]
            end
        end

        if event == "Kill_entity" then
            if SERVER then
                timer.Simple(0.6,function()
                    if !IsValid(ent) then return end
                    local jumpscare_entity = ent.jumpscare_entity
                    if !(IsValid(jumpscare_entity)) or !IsValid(ent) then return end
                    ent.jumpscare_entity = nil
                    jumpscare_entity:SetPos(ent.entitylastpos)
                    jumpscare_entity:SetAngles(ent.entitylastang)
                    if jumpscare_entity:IsPlayer() then
                        net.Start('gentoi_Slenderman_cam')
                        net.WriteEntity(puppet)
                        net.WriteBool(false)
                        net.Send(jumpscare_entity)
                        jumpscare_entity:Kill(ply)
                    else
                        jumpscare_entity:NextThink(CurTime())

                        jumpscare_entity:TakeDamage(1e9, ply)
                    end
                    ent:RemoveCallOnRemove("RachelJumpscare"..ent:EntIndex())
                end)
            end
        end
    end,

    noodles_Slenderman_gentoi_initialize=function(initializetable,initializetable2,initializetable3)
        if SERVER then
            local ply = initializetable2["player"]
            if initializetable2["player"]:IsPlayer() then
                net.Start("slenderman_viewport_hands")
                net.WriteEntity(initializetable2["entity"])
                net.Send(initializetable2["player"])
            end
            ply:SetViewEntity(ply)

            initializetable2["entity"]:GetPuppet():SetRenderMode(RENDERMODE_TRANSALPHA)
            initializetable2["entity"]:GetPuppet():SetColor(Color(0,0,0,0))
            initializetable2["entity"]:SetNWInt("Slenderman_invis", 0)
            initializetable2["entity"]:SetNWBool('gentoi_slenderman', true)
            initializetable2["entity"].PointsWentFrom_1 = {}
            initializetable2["entity"].PointsWentFrom_2 = {}
            initializetable2["entity"].PointsWentFrom_3 = {}
            initializetable2["entity"].PointsWentFrom_4 = {}
        end

        initializetable2["entity"]:SetNWBool('gentoi_slenderman', true)
    end,
    noodles_Slenderman_gentoi_OnRemove=function(initializetable,initializetable2,initializetable3)
        if IsValid(initializetable2["player"]) then
            if SERVER then
                local ply = initializetable2["player"]
                ply:SetViewEntity(ply)
                ply:StripWeapon("viewmodelsetp_slenderman")
            end
        end
    end,

    think_noodles_slenderman_gentoi_pill = function(ply, ent)
        if SERVER then 
                
            local shouldStun = false
            local puppet = ent:GetPuppet()
            if not IsValid(puppet) then return end
            
            local tracecodebones = {
                [1] = {startbon= "Bone.052", endbon="Bone.058" },
                [2] = {startbon= "Bone.077", endbon="Bone.083" },
                [3] = {startbon= "Bone.006", endbon="Bone.083" },
                [4] = {startbon= "Bone.001", endbon="Bone.018" }
            }

            local eyePos = ply:EyePos()
            local eyeDir = ply:EyeAngles():Forward()
            local puppetAng = puppet:GetAngles()
            local i = 0
            if IsValid(ent:GetNWEntity("Armtenticle_entity_1")) then i = 1 end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_2")) then i = 2 end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_3")) then i = 3 end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_4")) then i = 4 end

            if i > 0 then

                local startmatrix = puppet:GetBoneMatrix(puppet:LookupBone(tracecodebones[i].startbon))
                local endmatrix = puppet:GetBoneMatrix(puppet:LookupBone(tracecodebones[i].endbon))

                local fly = ent:GetNWEntity("flyingent")
                local ragdoll = ent:GetNWEntity("Armtenticle_entity_"..i)
                local trailOrigin_entity_ = ent:GetNWEntity("trailOrigin_entity_".. i)

                if ent:GetNWBool("Arm_tenticle_"..i) then
                    if !IsValid(fly) then
                        local flyingent = ents.Create("prop_physics")

                        if !IsValid(flyingent) then return end

                        flyingent:SetModel("models/hunter/blocks/cube025x025x025.mdl")

                        local eyePos = ply:EyePos()
                        local eyeDir = ply:EyeAngles():Forward()
                            
                        flyingent:SetPos(Vector(0,0,0) + eyePos + eyeDir * (110*1))
                        flyingent:SetAngles(ply:GetAngles())
                        flyingent:Spawn()
                        flyingent:Activate()
                        flyingent:SetCollisionGroup(COLLISION_GROUP_WORLD)

                        flyingent:PhysicsInit(SOLID_VPHYSICS)
                        flyingent:SetMoveType(MOVETYPE_VPHYSICS)
                        flyingent:SetSolid(SOLID_VPHYSICS)

                        ent:DeleteOnRemove(flyingent)

                        ent:SetNWEntity("flyingent",flyingent)
                        flyingent:SetNWInt("DesginatedNumb",i)
                        
                        flyingent:SetRenderMode(RENDERMODE_TRANSALPHA)
                        flyingent:SetColor(Color(0,0,0,0))
                        flyingent:DrawShadow(false)
                    else
                        shouldStun = true
                        local speed = 13

                        local options = {
                            speed = 25,
                        }
                        
                        local phys = fly:GetPhysicsObject()

                        if phys:IsGravityEnabled() then
                            phys:EnableGravity(false)
                        end

                        --Lateral Movement
                        local move = Vector(0, 0, 0)
                        local origin = fly:GetPos()
                        local rotatedAngle = trailOrigin_entity_:GetAngles()
                        local angled-- = ply:EyeAngles()
                        local aim = Angle(0, ply:EyeAngles().y, 0)

                        if (ply:KeyDown(IN_FORWARD)) then
                            move = rotatedAngle:Forward() * options.speed
                        elseif (ply:KeyDown(IN_BACK)) then
                            move = move + rotatedAngle:Forward() * -options.speed
                        end

                        if (ply:KeyDown(IN_MOVERIGHT)) then
                            move = move + rotatedAngle:Right() * options.speed
                        elseif (ply:KeyDown(IN_MOVELEFT)) then
                            move = move + rotatedAngle:Right() * -options.speed
                        end
                        aim.p = math.Clamp(ply:EyeAngles().p, -30, 30)

                        if (ply:KeyDown(IN_JUMP)) then
                            move = move + Vector(0, 0, options.speed * 1.5 / 3)
                        elseif (ply:KeyDown(IN_DUCK)) then
                            move = move + Vector(0, 0, -options.speed * 1.5 / 3)
                        end
                        

                        local function extrmeelyoverusedffunction(hitent)
                            if hitent == fly then return false end
                            if hitent == ply then return false end
                            if hitent:IsPlayer() then return false end
                            if hitent:IsNPC() then return false end
                            if hitent.IsNextBot and hitent:IsNextBot() then return false end
                            if ragdoll == hitent then return false end
                            return true
                        end
                        local hullTrace = util.TraceHull({
                            start = origin,
                            endpos = origin + move*6,
                            mins = Vector(-2, -2, -2),
                            maxs = Vector(2, 2, 2),
                            filter = extrmeelyoverusedffunction
                        })
                                
                        if not hullTrace.Hit then
                            phys:AddVelocity(move - phys:GetVelocity() * 0.02)
                        else
                        end

                        local localAim = fly:WorldToLocalAngles(aim)

                        local moveAng = Vector(0, 0, 0)
                        moveAng.y = localAim.p * 15
                        moveAng.z = localAim.y * 15
                        moveAng.x = localAim.r * 15
                        phys:AddAngleVelocity(-1 * phys:GetAngleVelocity() + moveAng)

                        for _, ent2 in pairs(ents.FindInSphere(fly:GetPos(), 120)) do
                            if (ent2:IsPlayer() or ent2:IsNextBot() or ent2:IsNPC()) and ent2:Health() >= 0.1 then
                                if ent2 == ply then continue end
                                if ent2:IsPlayer() and ent2:Team() == TEAM_SPECTATOR then continue end

                                if IsValid(ent2) then
                                    local trace = util.TraceLine({start = origin, endpos = ent2:GetPos()+Vector(0,0,30), filter = {ent, ply}, mask = MASK_VISIBLE})
                                    if not trace.Hit then
                                        if SERVER and SherlockHNS and ent2:IsPlayer() and not SherlockHNS.CanTarget(ent2, ply) then continue end
                            ent2:SetNWEntity("gentoi_slenderman_host", ent)
                                        ent:SetNWEntity("gentoi_slenderman_target", ent2)
                                        ent:SetNWInt("Gentoi_slenderman_target_numb", i)
                                        ent:SetNWInt("GameTollerance_Slendermanside",15)
                                        ent:SetNWBool("Arm_tenticle_"..i, false)
                                        if ent2:IsNextBot() or ent2:IsNPC() then
                                            local name = "interval_clicking_exetrap_" .. ent2:EntIndex()
                                            timer.Create(name, 0.1, 0, function()
                                                if !IsValid(ent) or !IsValid(ent2) then
                                                    timer.Remove(name)
                                                    return
                                                end
                                                if math.random(1,2) == 1 then
                                                    if ent:GetNWInt("GameTollerance_Slendermanside") < -50 then
                                                        ent:SetNWInt("GameTollerance_Slendermanside", -50 )
                                                    else
                                                        ent:SetNWInt("GameTollerance_Slendermanside", ent:GetNWInt("GameTollerance_Slendermanside") - 2.5 )
                                                    end
                                                end
                                            end)
                                        end
                                        break
                                    end
                                end
                            end
                        end

                        if move == Vector(0,0,0) then 
                        else
                            ent:SetNWInt("PointsWentFrom_"..i, ent:GetNWInt("PointsWentFrom_"..i) + 1 )
                            ent["PointsWentFrom_"..i][ent:GetNWInt("PointsWentFrom_"..i)] = { ["setposarea"] = fly:GetPos() }
                        end

                    end
                
                    if ent:GetNWFloat("tenticalDur" ) > CurTime() then if not ent:GetNWBool("Cancel_boolean_tenticaldur") then ent:SetNWBool("Cancel_boolean_tenticaldur", true) end
                    else
                        if ent:GetNWBool("Cancel_boolean_tenticaldur") then
                            ent:SetNWBool("Cancel_boolean_tenticaldur", false)
                            ent:SetNWBool("Arm_tenticle_"..i, false)
                        end
                    end
                else
                    if IsValid( ent:GetNWEntity("gentoi_slenderman_target") ) then
                        if ent:GetNWInt("GameTollerance_Slendermanside") > 0 then
                        else
                            if ent:GetNWInt("GameTollerance_Slendermanside") > -45 then
                            else
                                if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then
                                    ent:GetNWEntity("gentoi_slenderman_target"):SetNWEntity("gentoi_slenderman_host", NULL)
                                end
                                ent:SetNWEntity("gentoi_slenderman_target", NULL)
                            end
                        end
                    end
                    if ent:GetNWInt("PointsWentFrom_"..i) <= 0 then
                        if SERVER then
                            if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then
                                ent:GetNWEntity("gentoi_slenderman_target"):SetNWEntity("gentoi_slenderman_host", NULL)
                            end
                            ent:SetNWEntity("gentoi_slenderman_target", NULL)
                            
                            if IsValid(fly) then                     
                                if fly:GetNWInt("DesginatedNumb") == i then
                                    --fly:Remove()
                                end
                            end
                            if IsValid(ragdoll) then
                                ragdoll:Remove()
                            end
                        end
                    else

                        local tablevalue = ent["PointsWentFrom_"..i][ent:GetNWInt("PointsWentFrom_"..i)]

                        if ent:GetNWInt("CooldownForTenticalMovement") < CurTime() then
                            if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then
                                ent:SetNWInt("PointsWentFrom_"..i, ent:GetNWInt("PointsWentFrom_"..i) - 1 )
                                ent:SetNWInt("CooldownForTenticalMovement", CurTime()+0.04) 
                            else
                                ent:SetNWInt("PointsWentFrom_"..i, ent:GetNWInt("PointsWentFrom_"..i) - 2 )
                                if ent:GetNWInt("PointsWentFrom_"..i ) < 0 then
                                    ent:SetNWInt("PointsWentFrom_"..i, 0 )
                                end
                            end
                        end
                        ent:SetNWFloat("tenticalDur" , 0)
                        ent:SetNWBool("Cancel_boolean_tenticaldur", false)

                        if IsValid(fly) then
                            fly:SetPos(tablevalue["setposarea"])

                            local angle = (ply:GetPos()-fly:GetPos()):Angle()
                            fly:SetAngles(Angle(0, angle.y, 0))
                        end
                            
                        if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then
                            HandleBar_Slenderman(ent, 0.05)


                            if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then
                                if ent:GetNWEntity("gentoi_slenderman_target"):IsPlayer() then
                                    local ang = (ply:GetPos()+Vector(0,0,40) - ent:GetNWEntity("gentoi_slenderman_target"):EyePos()):Angle()
                                    ent:GetNWEntity("gentoi_slenderman_target"):SetEyeAngles(ang)
                                end
                            end


                            local teleportent = ent:GetNWEntity("gentoi_slenderman_target")

                            local targetPos = tablevalue["setposarea"] - Vector(0,0,20)
                            local mins, maxs = teleportent:OBBMins(), teleportent:OBBMaxs()

                            local teleported = false

                            local function TraceAt(pos)
                                return util.TraceHull({
                                    start = pos,
                                    endpos = pos,
                                    mins = mins,
                                    maxs = maxs,
                                    filter = teleportent,
                                    mask = MASK_PLAYERSOLID
                                })
                            end

                            if not teleported then
                                local tr = TraceAt(targetPos)
                                if not tr.Hit then
                                    teleportent:SetVelocity(Vector(0, 0, 0))
                                    teleportent:SetPos(targetPos)
                                    teleported = true
                                end
                            end

                            for i = 1, 12 do
                                if teleported then break end

                                local pos = targetPos + Vector(0, 0, i * 8)
                                local tr = TraceAt(pos)

                                if not tr.Hit then
                                    teleportent:SetVelocity(Vector(0, 0, 0))
                                    teleportent:SetPos(pos)
                                    teleported = true
                                else
                                    local safePos = tr.HitPos + tr.HitNormal * 10
                                    local trSafe = TraceAt(safePos)

                                    if not trSafe.Hit then
                                        teleportent:SetVelocity(Vector(0, 0, 0))
                                        teleportent:SetPos(safePos)
                                        teleported = true
                                    end
                                end
                            end

                            local radial = {
                                Vector(16, 0, 0), Vector(-16, 0, 0),
                                Vector(0, 16, 0), Vector(0, -16, 0),
                                Vector(24, 24, 0), Vector(-24, -24, 0),
                                Vector(24, -24, 0), Vector(-24, 24, 0),
                                Vector(32, 0, 0), Vector(-32, 0, 0),
                                Vector(0, 32, 0), Vector(0, -32, 0)
                            }

                            for _, offset in ipairs(radial) do
                                if teleported then break end

                                local pos = targetPos + offset
                                local tr = TraceAt(pos)

                                if not tr.Hit then
                                    teleportent:SetVelocity(Vector(0, 0, 0))
                                    teleportent:SetPos(pos)
                                    teleported = true
                                else
                                    local safePos = tr.HitPos + tr.HitNormal * 10
                                    local trSafe = TraceAt(safePos)

                                    if not trSafe.Hit then
                                        teleportent:SetVelocity(Vector(0, 0, 0))
                                        teleportent:SetPos(safePos)
                                        teleported = true
                                    end
                                end
                            end

                            if not teleported then
                                local trDown = util.TraceHull({
                                    start = targetPos + Vector(0, 0, 64),
                                    endpos = targetPos - Vector(0, 0, 256),
                                    mins = mins,
                                    maxs = maxs,
                                    filter = teleportent,
                                    mask = MASK_PLAYERSOLID
                                })

                                if trDown.Hit then
                                    local safePos = trDown.HitPos + trDown.HitNormal * 10
                                    local trSafe = TraceAt(safePos)

                                    if not trSafe.Hit then
                                        teleportent:SetVelocity(Vector(0, 0, 0))
                                        teleportent:SetPos(safePos)
                                        teleported = true
                                    end
                                end
                            end

                            if not teleported then
                                local tr = TraceAt(targetPos)
                                if tr.Hit then
                                    teleportent:SetVelocity(Vector(0, 0, 0))
                                    teleportent:SetPos(tr.HitPos + tr.HitNormal * 10)
                                else
                                    teleportent:SetVelocity(Vector(0, 0, 0))
                                    teleportent:SetPos(targetPos)
                                end
                            end

                            local angle = (ply:GetPos()-ent:GetNWEntity("gentoi_slenderman_target"):GetPos()):Angle()
                            ent:GetNWEntity("gentoi_slenderman_target"):SetAngles(Angle(0, angle.y, 0))
                        end
                    end
                end


                if IsValid(fly) then

                    local puppet = ent:GetPuppet()
                    if IsValid(ragdoll) then
                                                
                        local phys1 = ragdoll:GetPhysicsObjectNum(ragdoll:TranslateBoneToPhysBone(ragdoll:LookupBone("ArmSeg1")))
                        local phys2 = ragdoll:GetPhysicsObjectNum(ragdoll:TranslateBoneToPhysBone(ragdoll:LookupBone("ArmSeg2")))
                        local phys3 = ragdoll:GetPhysicsObjectNum(ragdoll:TranslateBoneToPhysBone(ragdoll:LookupBone("ArmSeg3")))
                        local phys4 = ragdoll:GetPhysicsObjectNum(ragdoll:TranslateBoneToPhysBone(ragdoll:LookupBone("ArmSeg4")))
                        local phys5 = ragdoll:GetPhysicsObjectNum(ragdoll:TranslateBoneToPhysBone(ragdoll:LookupBone("ArmSeg5")))

                        local startPos = startmatrix:GetTranslation()
                        local endPos   = fly:GetPos()

                        local base3 = (startPos + endPos) * 0.5
                        local base2 = (startPos + base3) * 0.5
                        local base4 = (base3 + endPos) * 0.5

                        local dir = (endPos - startPos):GetNormalized()
                        local right = dir:Cross(Vector(0, 0, 1)):GetNormalized()
                        local up = right:Cross(dir):GetNormalized()

                        local t = CurTime() * 2.5

                        local flowStrength = 6
                        local twirlStrength = 4
                        local twirlSpeed = 3.5

                        local flow2 = (right * math.sin(t) + up * math.cos(t)) * flowStrength
                        local flow4 = (right * math.sin(t + math.pi) + up * math.cos(t + math.pi)) * flowStrength

                        local flow3 = (flow2 + flow4) * 0.5

                        local twirl = (right * math.cos(t * twirlSpeed) + up * math.sin(t * twirlSpeed)) * twirlStrength

                        local armAng = dir:Angle()
                        if i == 1 or i == 2 then
                            armAng:RotateAroundAxis(armAng:Right(), 180)
                        else
                            armAng:RotateAroundAxis(armAng:Right(), -180)
                        end

                        if IsValid(phys1) then
                            phys1:SetPos(startPos)
                            phys1:SetAngles(armAng)
                            phys1:Wake()
                        end

                        if IsValid(phys2) then
                            phys2:SetPos(base2 + flow2)
                            phys2:SetAngles(armAng)
                            phys2:Wake()
                        end

                        if IsValid(phys3) then
                            phys3:SetPos(base3 + flow3)
                            phys3:SetAngles(armAng)
                            phys3:Wake()
                        end

                        if IsValid(phys4) then
                            phys4:SetPos(base4 + flow4)
                            phys4:SetAngles(armAng)
                            phys4:Wake()
                        end

                        if IsValid(phys5) then
                            phys5:SetPos(endPos + twirl)
                            phys5:SetAngles(armAng)
                            phys5:Wake()
                        end
                    end

                    if IsValid(trailOrigin_entity_) then
                        local ang = ply:EyeAngles()

                        local dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                        local startpos = fly:GetPos() + ply:GetForward() * (ent.formTable.ThirdPersonBone[2]*0.25) + ply:GetUp() * (ent.formTable.ThirdPersonBone[4]*0.25)+ ply:GetRight() * (ent.formTable.ThirdPersonBone[3] *0.25)
                        local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                        local offset = LocalToWorld(Vector(-dist, 0, underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)

                        local tr = util.TraceHull({
                            start = startpos,
                            endpos = startpos + offset,
                            filter = ent.camTraceFilter,
                            mins = Vector(-5, -5, -5),
                            maxs = Vector(5, 5, 5),
                            mask = MASK_VISIBLE
                        })

                        local tr2 = util.TraceHull({
                            start = fly:GetPos(),
                            endpos = tr.HitPos,
                            filter = ent.camTraceFilter,
                            mins = Vector(-5, -5, -5),
                            maxs = Vector(5, 5, 5),
                            mask = MASK_VISIBLE
                        })
                        trailOrigin_entity_:SetPos(tr2.HitPos)
                        trailOrigin_entity_:SetAngles(ang)
                        if ply:GetViewEntity() ~= fly then ply:SetViewEntity(fly) end
                    else
                        if ply:GetViewEntity() ~= ply then ply:SetViewEntity(ply) end
                    end

                else
                    if ply:GetViewEntity() ~= ply then ply:SetViewEntity(ply) end
                end
            else
                if ply:GetViewEntity() ~= ply then ply:SetViewEntity(ply) end

                local fly = ent:GetNWEntity("flyingent")
                if IsValid(fly) then
                    fly:Remove()
                    ent:SetNWFloat("Slenderman_stretch_Cooldown_afteruse_fill", CurTime() + 0.8)
                    ent:SetNWFloat("Slenderman_stretch_Cooldown", CurTime() + 15.8)
                    pk_pills.setHNSCooldown(ent, "stretch", ent:GetNWFloat("Slenderman_stretch_Cooldown") - CurTime())
                    HandleBar_Slenderman(ent, 5)
                    ent:SetNWFloat("tenticalDur", CurTime() )
                    
                    if IsValid(trailOrigin_entity_) then trailOrigin_entity_:Remove() end
                end
            end

            if ent:GetNWFloat("Bar_Slenderman_Gentoi") >= 100 and not ent:GetNWBool("Decrease_bar") then
                ent:SetNWBool("Decrease_bar", true)
            elseif ent:GetNWFloat("Bar_Slenderman_Gentoi") <= 0 and ent:GetNWBool("Decrease_bar") then
                if ent:GetNWBool("Decrease_bar") then
                    ent:SetNWBool("Decrease_bar", false)
                end
            else
                if ent:GetNWBool("Decrease_bar") then
                    if ent:GetNWInt("DecreaseDebounce") < CurTime() then
                        if ent:GetNWInt("ChangeAmount_slenderman_gentoi", 0) < CurTime() then
                            HandleBar_Slenderman(ent, (-0.5*1.75))
                            ent:SetNWInt("ChangeAmount_slenderman_gentoi",CurTime() + 0.2)
                        end
                    end
                end
            end
            if ent:GetNWBool("Decrease_bar") then
                if not ent:GetNWBool("Decrease_bar_toggle") then
                    ent:SetNWBool("Decrease_bar_toggle", true)
                    ent:SetNWFloat("Decrease_bar_Ability1IconBelow", CurTime()+0.8)
                    ent:SetNWFloat("Decrease_bar_Ability2IconLeft", CurTime()+1.8)
                end
            else
                if ent:GetNWBool("Decrease_bar_toggle") then
                    ent:SetNWBool("Decrease_bar_toggle", false)
                    ent:SetNWFloat("Decrease_bar_Ability1IconUp", CurTime()+1.8)
                    ent:SetNWFloat("Decrease_bar_Ability2IconRight", CurTime()+0.8)
                end
            end

            local alpha = ent:GetPuppet():GetColor().a or 255
            if alpha >= 255 * 0.85 then
                tracefuntion(ply, false, function(Repeat)
                    for i=1,Repeat do
                        if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then
                            HandleBar_Slenderman(ent, 0.35*0.2)
                        else
                            HandleBar_Slenderman(ent, 1*(0.3*0.85))
                        end
                        ent:SetNWInt("DecreaseDebounce", CurTime()+0.067)
                    end
                end)
            else
                tracefuntion(ply, true, function(Repeat)
                end)
            end

            local puppet = ent:GetPuppet()
            if ent.jumpscare_entity then
                local entity = ent.jumpscare_entity
                if IsValid(entity) then

                    local lengthofentitybody = (entity:EyePos() - entity:GetPos()):Length() /2

                    local cam = ent:GetPuppet():GetAttachment(ent:GetPuppet():LookupAttachment('camera'))

                    if entity:Health() < 0.1 and entity:IsPlayer() then
                        ent.jumpscare_entity = nil
                    else
                        local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
                        local lengthofentitybody = ((maxs.z - mins.z)/2)*4

                        local lerpFactor = math.Clamp((CurTime() - ent.JuumpscareStart) / 0.5, 0, 1)
                        local newAngle = LerpAngle(lerpFactor, ent.entitylastang, cam.Ang)
                        local NewVector = LerpVector(lerpFactor, ent.entitylastpos, cam.Pos - entity:GetUp() * lengthofentitybody)
                        entity:SetPos(NewVector)
                        entity:SetAngles(newAngle)
                    end
                end
            end

            local changeSpeed = 400 * FrameTime()

            local inv = ent:GetNWInt("Slenderman_invis") == 0
            if inv then
                local col = puppet:GetColor()
                local newAlpha = col.a - changeSpeed
                ent:SetNWInt("newAlpha_gentoi_slenderman", newAlpha)
                if newAlpha < 0 then newAlpha = 0 end

                puppet:SetColor(Color(0, 0, 0, 0))
                ent:SetNWInt("gentoi_slenderman_Invis", CurTime()+0.3)
            else
                local col = puppet:GetColor()
                local newAlpha = col.a + changeSpeed
                if newAlpha > 255 then newAlpha = 255 end

                ent:SetNWInt("newAlpha_gentoi_slenderman", newAlpha)
                
                puppet:SetColor(Color(255, 255, 255, 255))
                if not ent:GetNWBool("Decrease_bar") then
                    shouldStun = true
                end
            end
            if ent._slenderSpeedState ~= inv then
                ent._slenderSpeedState = inv
                if inv then
                    pk_pills.setCostumeMoveSpeed(ent, 900, 900, 900)
                else
                    pk_pills.setCostumeMoveSpeed(ent, 45, 420, 45)
                end
            end

            if shouldStun then

                ply:SetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun2", CurTime()+0.1)
            end
        end
    end,

    noodles_Slenderman_gentoi_keybinds = function(ply,ent,button)
        if button == KEY_1 then

            if ent:GetNWBool("Arm_tenticle_1") then return end
            if ent:GetNWBool("Arm_tenticle_2") then return end
            if ent:GetNWBool("Arm_tenticle_3") then return end
            if ent:GetNWBool("Arm_tenticle_4") then return end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_1")) then return end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_2")) then return end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_3")) then return end
            if IsValid(ent:GetNWEntity("Armtenticle_entity_4")) then return end

            --if ent:GetNWBool("Decrease_bar") then return end
            if ent:GetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun") > CurTime() then return end
            if ent:GetNWInt("Slenderman_invis_Cooldown", CurTime()) > CurTime() then return end

            ent:SetNWInt("Slenderman_invis_Cooldown", CurTime() + 6.8)
            pk_pills.setHNSCooldown(ent, "invis", ent:GetNWInt("Slenderman_invis_Cooldown") - CurTime())
            ent:SetNWInt("Slenderman_invis_Cooldown_fill", CurTime() + 0.8)

            if ent:GetNWInt("Slenderman_invis") == 0 then
                ent:SetNWInt("Slenderman_invis", 1)
                    
                tracefuntion(ply, true, function(Repeat, table2)
                    local startTime = CurTime()
                    local data = {}

                    local FAST_TIME, SLOW_TIME, HOLD_TIME = 0.3, 0.1, 0.85

                    local TOTAL_MOVE  = FAST_TIME + SLOW_TIME
                    local END_TIME    = TOTAL_MOVE + HOLD_TIME

                    AdvancedPillSound({
                        stringe = "Gentoi/slenderman/Slender Jumpscare Sound.wav",
                        soundLevel = 79
                    }, ent)
                    for _, ent2 in ipairs(table2) do
                        if !IsValid(ent2) then continue end

                        if ent2:IsPlayer() then
                            data[ent2] = {
                                isPlayer = true,
                                start = ent2:EyeAngles(),
                                target = (ply:GetPos() - ent2:GetPos()):Angle()
                            }


                            --net.Start("SlenderMan_PlaySpotSound_gentoi")
                            --net.Send(ent2)

                        else
                            local dir = (ply:GetPos() - ent2:GetPos())
                            dir.z = 0

                            data[ent2] = {
                                isPlayer = false,
                                start = ent2:GetAngles(),
                                target = dir:Angle()
                            }
                        end
                    end

                    local name = "slenderman_characters_" .. ply:EntIndex()

                    hook.Add("Think", name, function()
                        local elapsed = CurTime() - startTime

                        if elapsed <= TOTAL_MOVE then
                            local t = elapsed / TOTAL_MOVE
                            t = math.ease.OutCubic(math.Clamp(t, 0, 1))

                            for ent2, info in pairs(data) do
                                if !IsValid(ent2) then continue end

                                local ang = LerpAngle(t, info.start, info.target)

                                if info.isPlayer then
                                    ent2:SetEyeAngles(ang)
                                else
                                    ent2:SetAngles(ang)
                                end
                            end
                            return
                        end

                        if elapsed <= END_TIME then
                            for ent2, info in pairs(data) do
                                if !IsValid(ent2) then continue end

                                if info.isPlayer then
                                    ent2:SetEyeAngles(info.target)
                                else
                                    ent2:SetAngles(info.target)
                                end
                            end
                            return
                        end

                        hook.Remove("Think", name)
                    end)
                end)

                local savedHook

                local hookTable = hook.GetTable()
                if hookTable["PlayerCanPickupWeapon"] and hookTable["PlayerCanPickupWeapon"]["pk_pill_pickupWeapon"] then
                    savedHook = hookTable["PlayerCanPickupWeapon"]["pk_pill_pickupWeapon"]
                end
                if savedHook then
                    hook.Remove("PlayerCanPickupWeapon", "pk_pill_pickupWeapon")
                end
                
                if SERVER then
                    ply:SetSuppressPickupNotices(true)
                    ply:Give("viewmodelsetp_slenderman")
                    ply:SelectWeapon("viewmodelsetp_slenderman")
                    ply:SetSuppressPickupNotices(false)
                    if savedHook then
                        hook.Add("PlayerCanPickupWeapon", "pk_pill_pickupWeapon", savedHook)
                    end
                end

                ply:SetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun", CurTime()+0.5)

            else
                ply:StripWeapon("viewmodelsetp_slenderman")
                ent:SetNWInt("Slenderman_invis", 0)
            end

        elseif button == KEY_2 then

            if SERVER then
                if ent:GetNWInt("Slenderman_stretch_Cooldown_beforeuse") > CurTime() then return end
                if ent:GetNWInt("Slenderman_stretch_Cooldown") > CurTime() then return end
                local puppet = ent:GetPuppet()
                if not IsValid(puppet) then return end
                if ent:GetNWBool("Arm_tenticle_1") or ent:GetNWBool("Arm_tenticle_2") or ent:GetNWBool("Arm_tenticle_3") or ent:GetNWBool("Arm_tenticle_4") then
                    ent:SetNWBool("Arm_tenticle_1", false)
                    ent:SetNWBool("Arm_tenticle_2", false)
                    ent:SetNWBool("Arm_tenticle_3", false)
                    ent:SetNWBool("Arm_tenticle_4", false)
                    ent:SetNWFloat("Slenderman_stretch_Cooldown_afteruse_fill", CurTime() + 0.8)
                    ent:SetNWFloat("Slenderman_stretch_Cooldown", CurTime() + 15.8)
                    pk_pills.setHNSCooldown(ent, "stretch", ent:GetNWFloat("Slenderman_stretch_Cooldown") - CurTime())
                    ent:SetNWFloat("tenticalDur", CurTime() )
                    return
                end
                if IsValid(ent:GetNWEntity("Armtenticle_entity_1")) then return end
                if IsValid(ent:GetNWEntity("Armtenticle_entity_2")) then return end
                if IsValid(ent:GetNWEntity("Armtenticle_entity_3")) then return end
                if IsValid(ent:GetNWEntity("Armtenticle_entity_4")) then return end
     
                local alpha = ent:GetPuppet():GetColor().a or 255
                if alpha < 255 * 0.85 then return end

                ent:SetNWInt("Slenderman_stretch_Cooldown_fill", CurTime() + 0.8)
                ent:SetNWInt("Slenderman_stretch_Cooldown_beforeuse", CurTime() + 1.6)
                local randomintchoose = math.random(1,4)

                local rag = ents.Create("prop_ragdoll")
                if IsValid(rag) then
                    rag:SetModel("models/Gentoi/anologhorror/Slenderman/Tentical"..randomintchoose..".mdl")
                    rag:SetPos(ent:GetPos())
                    rag:SetAngles(ent:GetAngles())
                    rag:Spawn()
                    rag:Activate()
                    ent:SetNWEntity("Armtenticle_entity_"..randomintchoose, rag)
                    ent:DeleteOnRemove(rag)

                    ent:SetNWInt("PointsWentFrom_"..randomintchoose, 0 )
                    ent:SetNWFloat("tenticalDur", CurTime()+30 )
                    ent:SetNWBool("Arm_tenticle_"..randomintchoose, true)

                    local trailOrigin = ents.Create("prop_physics")
                    trailOrigin:SetModel("models/hunter/blocks/cube025x025x025.mdl")
                    trailOrigin:PhysicsInit(SOLID_NONE)
                    trailOrigin:SetMoveType(MOVETYPE_NONE)
                    trailOrigin:SetSolid(SOLID_NONE)
                    trailOrigin:SetPos(ent:GetPos())
                    trailOrigin:Spawn()
                    rag:DeleteOnRemove(trailOrigin)

                    trailOrigin:SetRenderMode(RENDERMODE_TRANSALPHA)
                    trailOrigin:SetColor(Color(0,0,0,0))
                    trailOrigin:DrawShadow(false)

                    ent:SetNWEntity("trailOrigin_entity_"..randomintchoose, trailOrigin)
                end
            end
        elseif button == KEY_3 then
    
        elseif button == KEY_SPACE then
            if IsValid(ent:GetNWEntity("gentoi_slenderman_target")) then 
                ply:SetNWFloat("PressIcon_SlendermanPill_gentoi", CurTime()+0.25 )
                if ent:GetNWInt("GameTollerance_Slendermanside") > 50 then
                    ent:SetNWInt("GameTollerance_Slendermanside", 50 )
                else
                    ent:SetNWInt("GameTollerance_Slendermanside", ent:GetNWInt("GameTollerance_Slendermanside") + 1.5 )
                end
            end
        end
        if button == KEY_R then
            if SERVER then
                if ent:GetNWBool("Shiftlock") then
                    ent:SetNWBool("Shiftlock", false)
                else
                    ent:SetNWBool("Shiftlock", true)
                end
            end
        end
    end,
    
    attack = {
        mode = 'trigger',
        func = function(ply, ent)
            if SERVER then
                if ent:GetNWBool("Arm_tenticle_1") then return false end
                if ent:GetNWBool("Arm_tenticle_2") then return false end
                if ent:GetNWBool("Arm_tenticle_3") then return false end
                if ent:GetNWBool("Arm_tenticle_4") then return false end
                if not ent:GetNWBool("Decrease_bar") then return false end
                if ply:GetNWInt("DisablePlayerMovement_gentoi_Slenderman_stun") > CurTime() then return false end

                local alpha = ent:GetPuppet():GetColor().a or 255
                if alpha < 255 * 0.85 then return false end

                local dur = ent:GetPuppet():SequenceDuration(ent:GetPuppet():LookupSequence("kill"))
                return racheljackietien_jumpscare(
                    ply,
                    ent,
                    dur,
                    function()

                        AdvancedPillSound({
                            stringe = "gentoi/slenderman/slenderkill.wav",
                            soundLevel = 79
                        }, ent)

                        ent:PillAnim('kill')
                    end
                )
            end
        end
    },

    attack2 = {
        mode = "trigger",
        func = function(ply, ent)
        end,

    },


    reload=function(ply,ent)
    end,
    flashlight = function(ply, ent)
    end,
        
    jump = function(ply, ent)


    end
}, function(form)
    -- The legacy damage branches are for Sandbox and NPCs.
    form.hnsKillAPI = true
    form.hnsAbilities = {
        { id = "attack", name = "Ataque", key = IN_ATTACK, OnUse = form.attack.func },
    }
    form.attack, form.attack2, form.reload = nil, nil, nil
    pk_pills.bindHNSButtons(form, "noodles_Slenderman_gentoi_keybinds", {
        { id = "invis", name = "Invisibilidade", button = KEY_1, keyLabel = "1" },
        { id = "stretch", name = "Tentáculos", button = KEY_2, keyLabel = "2" },
        { id = "struggle", name = "Disputar controle", button = KEY_SPACE, keyLabel = "ESPAÇO" },
        { id = "shiftlock", name = "Travar corrida", button = KEY_R, keyLabel = "R" },
    })
end)
