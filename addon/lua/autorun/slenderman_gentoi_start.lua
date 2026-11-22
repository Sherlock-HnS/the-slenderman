if !pcall(require,"pk_pills") then
    if SERVER then
        hook.Add("PlayerInitialSpawn","pk_pill_extfail_cl",function(ply)
            if game.SinglePlayer() || ply:IsListenServerHost() then
                ply:SendLua('notification.AddLegacy("One or more pill extensions failed to load. Did you forget to install Parakeet\'s Pill Pack?",NOTIFY_ERROR,30)')
            end
        end)
        hook.Add("Initialize","pk_pill_extfail_sv",function(ply)
            print("[ALERT] One or more pill extensions failed to load. Did you forget to install Enhanced Parakeet's Pill Base?")
        end)
    end
    return
end

AddCSLuaFile()
include("include/slenderman_gentoi_pill.lua")

if SERVER then
    util.AddNetworkString("slenderman_viewport_hands")
    util.AddNetworkString('gentoi_slenderman_cam')
    util.AddNetworkString("SlenderMan_PlaySpotSound_gentoi")

    hook.Add("Think", "slenderman_starebarmanagement_gentoi", function()
        for _, ply in ipairs(player.GetAll()) do
            if !IsValid(ply) then continue end
            if ply:GetNWFloat("ChangeAmount_slenderman_gentoi") > CurTime() then
                if ply:GetNWFloat("Amount_slenderman_gentoi") < 100 then
                    ply:SetNWFloat("Amount_slenderman_gentoi", ply:GetNWFloat("Amount_slenderman_gentoi")+1.5)
                else
                    ply:SetNWFloat("Amount_slenderman_gentoi", 100)
                end
            else
                if ply:GetNWFloat("Amount_slenderman_gentoi") > 0 then
                    ply:SetNWFloat("Amount_slenderman_gentoi", ply:GetNWFloat("Amount_slenderman_gentoi")-3)
                else
                    ply:SetNWFloat("Amount_slenderman_gentoi", 0)
                end
            end
            if ply:GetNWFloat("ambianceAmount_slenderman_gentoi") > CurTime() then
                if ply:GetNWFloat("AmbientAmount_slenderman_gentoi") < 65 then
                    ply:SetNWFloat("AmbientAmount_slenderman_gentoi", ply:GetNWFloat("AmbientAmount_slenderman_gentoi")+1.5)
                else
                    ply:SetNWFloat("AmbientAmount_slenderman_gentoi", 65)
                end
            else
                if ply:GetNWFloat("AmbientAmount_slenderman_gentoi") > 0 then
                    ply:SetNWFloat("AmbientAmount_slenderman_gentoi", ply:GetNWFloat("AmbientAmount_slenderman_gentoi")-3)
                else
                    ply:SetNWFloat("AmbientAmount_slenderman_gentoi", 0)
                end
            end
        end
    end)
end
if CLIENT then
    --[[
    local jumpscareSound

    net.Receive("SlenderMan_PlaySpotSound_gentoi", function()
        if not IsValid(LocalPlayer()) then
            timer.Simple(0, function()
                net.Receive("SlenderMan_PlaySpotSound_gentoi")
            end)
            return
        end

        if jumpscareSound then
            jumpscareSound:Stop()
        end

        local ply = LocalPlayer()
        util.PrecacheSound("Gentoi/slenderman/Slender Jumpscare Sound.wav")

        jumpscareSound = CreateSound(ply, "Gentoi/slenderman/Slender Jumpscare Sound.wav")
        jumpscareSound:Play()
        jumpscareSound:ChangeVolume(1, 0)
    end)
    ]]



    hook.Add("SetupPlayerVisibility", "VisibilityHandler_slender_gent", function( ply, viewEntity )
        local pillentity = LocalPlayer().pk_pill_ent

        if IsValid(ply:GetNWEntity("gentoi_slenderman_host")) then
            AddOriginToPVS(pillentity:GetNW2Vector("phys5_pos"))
        end
    end)

    surface.CreateFont("CreditsText_Large", {
        font = "Arial",
        size = 70,
        weight = 700,
        antialias = true,
    })

    net.Receive('gentoi_slenderman_cam', function()
        local ent = net.ReadEntity()
        local state = net.ReadBool()
        local startTime = CurTime()

        local hookID = "gentoi_Slenderman_cam_" .. LocalPlayer():SteamID()

        if not state then
            hook.Remove('CalcView', hookID)
        else
            hook.Add('CalcView', hookID, function(ply, pos, angles, fov)
                if not IsValid(ply) or not ply:Alive() or !IsValid(ent) then
                    hook.Remove('CalcView', hookID)
                    if IsValid(ply) then
                        ply:RemoveFlags(FL_NOTARGET)
                        ply:Freeze(false)
                        ply:DrawViewModel(true)
                    end
                    return
                end

                local cam = ent:GetAttachment(ent:LookupAttachment('camera'))

                ply:AddFlags(FL_NOTARGET)
                ply:Freeze(true)
                ply:DrawViewModel(false)

                local lerpFactor = math.Clamp((CurTime() - startTime) / (0.7/3), 0, 1)
                
                local targetFOV = 80 

                local orgiginlerpto = LerpVector(lerpFactor, pos, cam.Pos)
                local angleslerpto = LerpAngle(lerpFactor, angles, cam.Ang)
                local interpolatedFOV = Lerp(lerpFactor, fov, targetFOV)

                local view = {
                    origin = orgiginlerpto,
                    angles = angleslerpto,
                    fov = interpolatedFOV,
                    drawviewer = false
                }
                return view
            end)
        end
    end)
        
    local mat_videoglitch, mat_Filmgrain = Material("effects/shaders/merc_videoglitch"), Material("effects/shaders/merc_filmgrain")
    local pp_videoglitch, pp_filmgrain = CreateClientConVar("pp_mercvideoglitch", "0", false, false, "Enable videoglitch", 0, 1), CreateClientConVar("pp_mercfilmgrain", "0", false, false, "Enable film grain", 0, 1)
    local beginSound, loopSound, ambientSound
    local QUIET_MULT, FADE_OUT_TIME = 0.45, 1

    local wasActive1, wasActive2 = false, false
    local loopTimerName = "Slenderman_Madness_LoopStart"

    hook.Add("RenderScreenspaceEffects", "slenderman_static_effects", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local amount = ply:GetNWFloat("Amount_slenderman_gentoi", 0)
        local factor = math.Clamp(amount / 100, 0, 1)
        local isActive = amount > 0

        if isActive and not wasActive1 then
            timer.Remove(loopTimerName)

            if not beginSound then
                beginSound = CreateSound(ply, "Gentoi/slenderman/MadnessBeginning.wav")
            end

            if beginSound then
                beginSound:Play()
                beginSound:ChangeVolume(QUIET_MULT, 0)
            end

            local duration = SoundDuration("Gentoi/slenderman/MadnessBeginning.wav") - 0.2

            timer.Create(loopTimerName, duration, 1, function()
                if not IsValid(ply) then return end
                if ply:GetNWFloat("Amount_slenderman_gentoi", 0) <= 0 then return end

                if not loopSound then
                    loopSound = CreateSound(ply, "Gentoi/slenderman/MadnessLOOP.wav")
                end

                if loopSound and not loopSound:IsPlaying() then
                    loopSound:Play()
                    loopSound:ChangeVolume(QUIET_MULT, 0)
                end
            end)
        end

        if not isActive and wasActive1 then
            timer.Remove(loopTimerName)

            if beginSound then
                beginSound:FadeOut(FADE_OUT_TIME)
            end

            if loopSound then
                loopSound:FadeOut(FADE_OUT_TIME)
            end
        end
        wasActive1 = isActive

        local isActive1 = ply:GetNWFloat("AmbientAmount_slenderman_gentoi", 0) > 0

        if isActive1 and not wasActive2 then
            if not ambientSound then
                ambientSound = CreateSound(ply, "Gentoi/slenderman/Slender Ambience1.wav")
            end

            if ambientSound then
                ambientSound:Play()
                --ambientSound:ChangeVolume(QUIET_MULT, 0)
            end
        end

        if not isActive1 and wasActive2 then
            if ambientSound then
                ambientSound:FadeOut(FADE_OUT_TIME)
            end
        end

        wasActive2 = isActive1


        if factor <= 0 then return end

        if not pp_videoglitch:GetBool() then
            render.UpdateScreenEffectTexture()
            mat_videoglitch:SetTexture("$basetexture", render.GetScreenEffectTexture())
            mat_videoglitch:SetFloat("$c0_y", factor * 0.6)
            mat_videoglitch:Recompute()
            render.SetMaterial(mat_videoglitch)
            render.DrawScreenQuad()
        end

        if not pp_filmgrain:GetBool() then
            render.UpdateScreenEffectTexture()

            mat_Filmgrain:SetInt("$c0_y", 3)
            mat_Filmgrain:SetFloat("$c1_y", 0.5 * factor)
            mat_Filmgrain:SetFloat("$c1_x", 0)
            mat_Filmgrain:SetFloat("$c0_z", 4.6460 * factor)
            mat_Filmgrain:SetFloat("$c0_w", 0.2130 * factor)

            render.SetMaterial(mat_Filmgrain)
            render.DrawScreenQuad()
        end
    end)

    local preservedmats = {
        [0] = Material("gentoi_slendermanicon/BarBackground.png"),
        [1] = Material("gentoi_slendermanicon/BarOutline.png"),
        ["space"] = Material("gentoi_slendermanicon/Space.png"),
        [2] = Material("gentoi_slendermanicon/Button_A.png"),
        ["Flight_bar"] = Material("gentoi_slendermanicon/RedBAR.png"),

        -- final stuff
        ["Slender_Spacenonpress"] = Material("gentoi_slendermanicon/Slender_Spacenonpress.png"),
        ["Slender_Spacepress"] = Material("gentoi_slendermanicon/Slender_Spacepress.png"),

        ["Slender_Struggleminigame"] = Material("gentoi_slendermanicon/Slender_Struggleminigame.png"),

        ["Invis_INVIS"] = Material("gentoi_slendermanicon/Slender_Supernaturalphase.png"),
        ["Invis_Vis"] = Material("gentoi_slendermanicon/Slender_Supernaturalphaseactive.png"),
        ["LunacyGrasp"] = Material("gentoi_slendermanicon/Slender_LunacyGrasp.png"),
        ["Button_Cancel"] = Material("gentoi_slendermanicon/Slender_LunacyGrasp.png"),

        ["Slender_Madnessmeter"] = Material("gentoi_slendermanicon/Slender_Madnessmeter.png"),
    }

    hook.Add("RenderScreenspaceEffects", "GentoiSlendermanVisionEffect", function()

        local ply = LocalPlayer()
        local pillentity = LocalPlayer().pk_pill_ent
        if !IsValid(pillentity) then return end

        local puppet = pillentity:GetPuppet()
        if !IsValid(puppet) then return end

        if !pillentity:GetNWBool("gentoi_slenderman") then return end

        if pillentity:GetNWInt("gentoi_slenderman_Invis") > CurTime() then
            local alpha = pillentity:GetNWInt("newAlpha_gentoi_slenderman", 255)

            alpha = math.Clamp(alpha, 0, 255)

            local factor = 1 - math.abs(alpha - 127.5) / 127.5

            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = -0.075 * factor,
                ["$pp_colour_contrast"] = 1 - 0.6 * ((255 - alpha) / 255),
                ["$pp_colour_colour"] = 1 - 1 * ((255 - alpha) / 255),
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0,
            })
        end
    end)

    hook.Add("HUDPaint", "gent_slenderman_hudpaint", function()
        if SherlockHNS then return end
        local ply = LocalPlayer()
        local pillentity = LocalPlayer().pk_pill_ent

        if IsValid(ply:GetNWEntity("gentoi_slenderman_host")) then
            local screenW, screenH = ScrW(), ScrH()
                    

            if input.IsKeyDown(KEY_SPACE) then
                surface.SetMaterial(preservedmats["Slender_Spacepress"])
            else
                surface.SetMaterial(preservedmats["Slender_Spacenonpress"])
            end

            surface.SetDrawColor(255, 255, 255, 255)
            local iconH = ScreenScale(175)*1.7
            local iconW = ScreenScale(58) *5
            local posX = screenW * 0.5 - iconW * 0.5
            local posY = screenH * 0.75- iconH * 0.56
            surface.DrawTexturedRect(posX, posY, iconW, iconH)

            local iconW = ScreenScale(48)*8
            local iconH = ScreenScale(25)*6
            local posY = screenH * 0.75- iconH * -0.7
            local startY = posY - iconH*2
            local posX = screenW * 0.5 - iconW * 0.5

            surface.SetDrawColor(45, 45, 45, 255)
            surface.DrawRect(posX+ScreenScale(38), startY+ScreenScale(38), iconW-ScreenScale(76), iconH-ScreenScale(76))
            local bar = math.Clamp(ply:GetNWEntity("gentoi_slenderman_host"):GetNWFloat("GameTollerance_Slendermanside")+50 or 0, 0, 100)
            local barFrac = bar / 100

            local fillWidth = (iconW-ScreenScale(76)) * barFrac

            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(posX+ScreenScale(38), startY+ScreenScale(38), fillWidth, iconH-ScreenScale(76))

            surface.SetMaterial(preservedmats["Slender_Struggleminigame"])
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(posX, startY, iconW, iconH)
                
        end

        if IsValid(pillentity) then
            if not pillentity.GetPuppet then return end
            if !IsValid(pillentity:GetPuppet()) then return end
            if pillentity:GetNWBool("gentoi_slenderman") then
            
                local screenW, screenH = ScrW(), ScrH()
                local iconW = ScreenScale(48 * 3)*2
                local iconH = ScreenScale(24*2)*1.5
                local startY = iconH * 0.005
                local posX = screenW * 0.5 - iconW * 0.5

                local bar = math.Clamp(pillentity:GetNWFloat("Bar_Slenderman_Gentoi") or 0, 0, 100)
                local barFrac = bar / 100

                surface.SetDrawColor(35, 0, 0, 255)
                surface.DrawRect(posX + ScreenScale(28), startY + ScreenScale(20), (iconW - ScreenScale(57)), iconH - ScreenScale(38))

                local fillWidth = (iconW - ScreenScale(57)) * barFrac

                surface.SetDrawColor(255, 0, 0, 255)
                surface.DrawRect(posX + ScreenScale(28), startY + ScreenScale(20), fillWidth, iconH - ScreenScale(38))

                surface.SetMaterial(preservedmats["Slender_Madnessmeter"])
                surface.SetDrawColor(255, 255, 255, 255)
                surface.DrawTexturedRect(posX, startY, iconW, iconH)

                local xaxis, yaxis = screenW/2 + screenW/5, screenH - ScreenScale(80)
                --[[
                if pillentity:GetNWBool("Decrease_bar_toggle") then
                    if pillentity:GetNWFloat("Decrease_bar_Ability1IconBelow") > CurTime() then
                        local iconsize_bar = math.Clamp((pillentity:GetNWFloat("Decrease_bar_Ability1IconBelow") - CurTime() ) / 0.8, 0, 1)
                        yaxis = Lerp(iconsize_bar, screenH + ScreenScale(180), yaxis)
                    else
                        yaxis = screenH+ScreenScale(180)
                    end
                else
                    if pillentity:GetNWFloat("Decrease_bar_Ability1IconUp") > CurTime() then
                        local iconsize_bar = math.Clamp((pillentity:GetNWFloat("Decrease_bar_Ability1IconUp")  - CurTime() ) / 1.8, 0, 1)
                        yaxis = Lerp(iconsize_bar, yaxis, screenH + ScreenScale(180))
                    end
                end
                ]]

                surface.SetDrawColor(255, 255, 255, 255)
                local alpha = pillentity:GetNWInt("newAlpha_gentoi_slenderman")
                if alpha < 255 * 0.85 then
                    surface.SetMaterial(preservedmats["Invis_INVIS"])
                else
                    surface.SetMaterial(preservedmats["Invis_Vis"])
                end
                surface.DrawTexturedRectUV(xaxis, yaxis, ScreenScale(70), ScreenScale(70) , 0, 0, 1, 1)

                if pillentity:GetNWInt("Slenderman_invis_Cooldown_fill") > CurTime() then
                    local iconsize_bar = math.Clamp((pillentity:GetNWInt("Slenderman_invis_Cooldown_fill") - CurTime() ) / 0.8, 0, 1)

                    surface.SetDrawColor(25, 25, 25, 255)
                    local lerpfactoriconsize_bar = Lerp(iconsize_bar, ScreenScale(70),0)
                    local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis, yaxis+ScreenScale(70))
                    local lerpiconsize_bar = Lerp(iconsize_bar, 0,1)

                    surface.DrawTexturedRectUV(xaxis, lerpfactoriyaxis_bar, ScreenScale(70), lerpfactoriconsize_bar, 0, lerpiconsize_bar, 1, 1)
                elseif pillentity:GetNWInt("Slenderman_invis_Cooldown") > CurTime() then
                    local iconsize_bar = math.Clamp((pillentity:GetNWInt("Slenderman_invis_Cooldown") - CurTime() ) / 6, 0, 1)

                    surface.SetDrawColor(25, 25, 25, 255)
                    local lerpfactoriconsize_bar = Lerp(iconsize_bar,0, ScreenScale(70))
                    local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis+ScreenScale(70), yaxis)
                    local lerpiconsize_bar = Lerp(iconsize_bar, 1,0)

                    surface.DrawTexturedRectUV(xaxis, lerpfactoriyaxis_bar, ScreenScale(70), lerpfactoriconsize_bar, 0, lerpiconsize_bar, 1, 1)
                end

                draw.SimpleTextOutlined(
                    "1", 
                    "CreditsText_Large", 
                    xaxis + ScreenScale(5), 
                    yaxis + ScreenScale(2), 
                    Color(255, 255, 255),
                    TEXT_ALIGN_CENTER, 
                    TEXT_ALIGN_CENTER, 
                    6,
                    Color(0, 0, 0)
                )

                local xaxis, yaxis = screenW/2 + screenW/3, screenH - ScreenScale(80)
                --[[
                if pillentity:GetNWBool("Decrease_bar_toggle") then
                    if pillentity:GetNWFloat("Decrease_bar_Ability2IconLeft") > CurTime() then
                        local iconsize_bar = math.Clamp((pillentity:GetNWFloat("Decrease_bar_Ability2IconLeft") - CurTime() ) / 0.8, 0, 1)
                        xaxis = Lerp(iconsize_bar, screenW/2 + screenW/5, xaxis)
                    else
                        xaxis = screenW/2 + screenW/5
                    end
                else
                    if pillentity:GetNWFloat("Decrease_bar_Ability1IconUp") > CurTime() then
                        local iconsize_bar = math.Clamp((pillentity:GetNWFloat("Decrease_bar_Ability1IconUp")  - CurTime() ) / 1.8, 0, 1)
                        xaxis = Lerp(iconsize_bar, xaxis, screenW/2 + screenW/5)
                    end
                end
                ]]

                surface.SetDrawColor(255, 255, 255, 255)
                if (IsValid(pillentity:GetNWEntity("flyingent")) and pillentity:GetNWInt("Slenderman_stretch_Cooldown_fill") < CurTime()) or pillentity:GetNWFloat("Slenderman_stretch_Cooldown_afteruse_fill") > CurTime() then
                    surface.SetMaterial(preservedmats["Button_Cancel"])
                else
                    surface.SetMaterial(preservedmats["LunacyGrasp"])
                end
                surface.DrawTexturedRectUV(xaxis, yaxis, ScreenScale(70), ScreenScale(70) , 0, 0, 1, 1)

                if pillentity:GetNWInt("Slenderman_stretch_Cooldown_fill") > CurTime() then
                    local iconsize_bar = math.Clamp((pillentity:GetNWInt("Slenderman_stretch_Cooldown_fill") - CurTime() ) / 0.8, 0, 1)

                    surface.SetDrawColor(0, 0, 0, 255)
                    local lerpfactoriconsize_bar = Lerp(iconsize_bar, ScreenScale(70),0)
                    local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis, yaxis+ScreenScale(70))
                    local lerpiconsize_bar = Lerp(iconsize_bar, 0,1)
                    surface.DrawTexturedRectUV(xaxis, lerpfactoriyaxis_bar, ScreenScale(70), lerpfactoriconsize_bar, 0, lerpiconsize_bar, 1, 1)
                elseif pillentity:GetNWInt("Slenderman_stretch_Cooldown_beforeuse") > CurTime() then
                    local iconsize_bar = math.Clamp((pillentity:GetNWInt("Slenderman_stretch_Cooldown_beforeuse") - CurTime() ) / 0.8, 0, 1)

                    surface.SetDrawColor(0, 0, 0, 255)
                    local lerpfactoriconsize_bar = Lerp(iconsize_bar,0,ScreenScale(70))
                    local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis+ScreenScale(70), yaxis)
                    local lerpiconsize_bar = Lerp(iconsize_bar, 1,0)

                    surface.DrawTexturedRectUV(xaxis, lerpfactoriyaxis_bar, ScreenScale(70), lerpfactoriconsize_bar, 0, lerpiconsize_bar, 1, 1)
                elseif pillentity:GetNWFloat("Slenderman_stretch_Cooldown_afteruse_fill") > CurTime() then
                    local iconsize_bar = math.Clamp((pillentity:GetNWFloat("Slenderman_stretch_Cooldown_afteruse_fill") - CurTime() ) / 0.8, 0, 1)

                    surface.SetDrawColor(0, 0, 0, 255)
                    local lerpfactoriconsize_bar = Lerp(iconsize_bar, ScreenScale(70),0)
                    local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis, yaxis+ScreenScale(70))
                    local lerpiconsize_bar = Lerp(iconsize_bar, 0,1)
                    surface.DrawTexturedRectUV(xaxis, lerpfactoriyaxis_bar, ScreenScale(70), lerpfactoriconsize_bar, 0, lerpiconsize_bar, 1, 1)
                elseif pillentity:GetNWFloat("Slenderman_stretch_Cooldown") > CurTime() then
                    local iconsize_bar = math.Clamp((pillentity:GetNWFloat("Slenderman_stretch_Cooldown") - CurTime() ) / 15, 0, 1)

                    surface.SetDrawColor(0, 0, 0, 255)
                    local lerpfactoriconsize_bar = Lerp(iconsize_bar,0,ScreenScale(70))
                    local lerpfactoriyaxis_bar = Lerp(iconsize_bar, yaxis+ScreenScale(70), yaxis)
                    local lerpiconsize_bar = Lerp(iconsize_bar, 1,0)
                    surface.DrawTexturedRectUV(xaxis, lerpfactoriyaxis_bar, ScreenScale(70), lerpfactoriconsize_bar, 0, lerpiconsize_bar, 1, 1)
                end
                if pillentity:GetNWFloat("tenticalDur") > CurTime() then
                    draw.SimpleTextOutlined(
                        math.floor(pillentity:GetNWFloat("tenticalDur") - CurTime()), 
                        "CreditsText_Large", 
                        xaxis + ScreenScale(70*0.5), 
                        yaxis + ScreenScale(70*0.5), 
                        Color(255, 255, 255),
                        TEXT_ALIGN_CENTER, 
                        TEXT_ALIGN_CENTER, 
                        6,
                        Color(0, 0, 0)
                    )
                end

                draw.SimpleTextOutlined(
                    "2", 
                    "CreditsText_Large", 
                    xaxis + ScreenScale(5), 
                    yaxis + ScreenScale(2), 
                    Color(255, 255, 255),
                    TEXT_ALIGN_CENTER, 
                    TEXT_ALIGN_CENTER, 
                    6,
                    Color(0, 0, 0)
                )

                if IsValid(pillentity:GetNWEntity("gentoi_slenderman_target")) then
                    local screenW, screenH = ScrW(), ScrH()
                    
                    if input.IsKeyDown(KEY_SPACE) then
                        surface.SetMaterial(preservedmats["Slender_Spacepress"])
                    else
                        surface.SetMaterial(preservedmats["Slender_Spacenonpress"])
                    end


                    surface.SetDrawColor(255, 255, 255, 255)
                    local iconH = ScreenScale(175)*1.7 *0.8
                    local iconW = ScreenScale(58) *5 *0.8
                    local posX = screenW * 0.5 - iconW * 0.5
                    local posY = screenH * 0.75- iconH * 0.56
                    surface.DrawTexturedRect(posX, posY, iconW, iconH)
                    local stretch = 1.567

                    local iconW = ScreenScale(48) * 8 * 0.8 * stretch
                    local iconH = ScreenScale(25) * 6 * 0.8

                    local posY = screenH * 0.75 - iconH * -0.7
                    local startY = posY - iconH * 2

                    local posX = screenW * 0.5 - iconW * 0.5

                    surface.SetDrawColor(45, 45, 45, 255)
                    surface.DrawRect(
                        posX + ScreenScale(38) * 0.8 * stretch,
                        startY + ScreenScale(38) * 0.8,
                        (iconW - ScreenScale(76) * 0.8 * stretch),
                        iconH - ScreenScale(76) * 0.8
                    )

                    local bar = math.Clamp((pillentity:GetNWFloat("GameTollerance_Slendermanside") or 0) + 50, 0, 100)
                    local barFrac = bar / 100

                    local fillWidth = (iconW - ScreenScale(76) * 0.8 * stretch) * barFrac

                    surface.SetDrawColor(255, 0, 0, 255)
                    surface.DrawRect(
                        posX + ScreenScale(38) * 0.8 * stretch,
                        startY + ScreenScale(38) * 0.8,
                        fillWidth,
                        iconH - ScreenScale(76) * 0.8
                    )

                    surface.SetMaterial(preservedmats["Slender_Struggleminigame"])
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.DrawTexturedRect(posX, startY, iconW, iconH)

                end
            end
        end
    end)



    local storedmats = {
        [0] = Material("gentoi_slendermanicon/fadeoutaz.png")
    }
    net.Receive("slenderman_viewport_hands", function()
        local ply = LocalPlayer()
        local ent = net.ReadEntity()

        local hookID = "SlenderViewport2D_" .. ply:Nick()
        local hookID2 = "SlenderViewport_" .. ply:Nick()

        timer.Simple(0,function()
            if !IsValid(ent) then return end
            local mdl
            local idle

            hook.Add("PreRender", "slenderman_bright".. ply:UserID(), function()
                if !IsValid(ent) then
                    hook.Remove("PreRender", "slenderman_bright".. ply:UserID())
                    render.SetLightingMode(1)
                    return
                end

                local puppet = ent:GetPuppet()
                if !IsValid(puppet) then return end

                local alpha = ent:GetNWInt("newAlpha_gentoi_slenderman")

                if alpha > 255 * 0.5 then 
                    render.SetLightingMode(0)
                else
                    render.SetLightingMode(1)
                end
            end)

            hook.Add("PostRender", "slenderman_bright".. ply:UserID(), function()
                if !IsValid(ent) then
                    hook.Remove("PostRender", "slenderman_bright".. ply:UserID())
                    render.SetLightingMode(0)
                    return
                end

                local puppet = ent:GetPuppet()
                if !IsValid(puppet) then return end

                local alpha = ent:GetNWInt("newAlpha_gentoi_slenderman")

                if alpha > 255 * 0.5 then 
                    render.SetLightingMode(1)
                else
                    render.SetLightingMode(0)
                end
            end)
            hook.Add("PreDrawHUD", "slenderman_bright".. ply:UserID(), function()
                if !IsValid(ent) then
                    hook.Remove("PreDrawHUD", "slenderman_bright".. ply:UserID())
                    render.SetLightingMode(0)
                    return
                end

                local puppet = ent:GetPuppet()
                if !IsValid(puppet) then return end

                local alpha = ent:GetNWInt("newAlpha_gentoi_slenderman")

                if alpha > 255 * 0.5 then 
                    render.SetLightingMode(0)
                else
                    render.SetLightingMode(0)
                end
            end)

            local savedCalcViewHooks = {}

            local calcViewHooks = hook.GetTable().CalcView or {}
            for k, v in pairs(calcViewHooks) do
                if k ~= hookID then
                    savedCalcViewHooks[k] = v
                    hook.Remove("CalcView", k)
                end
            end

            local name5 = "slenderman_remove".. ply:Nick()

            hook.Add( "PreDrawHalos", name5, function()
                local ply = LocalPlayer()
                local pillentity = LocalPlayer().pk_pill_ent

                local entities = {}

                for _, v in ipairs(ents.GetAll()) do
                    if not IsValid(v) or v == ply then continue end
                    if v == ent then continue end
                    if v:IsPlayer() or v:IsNPC() or v:IsNextBot() then if v:Health()<0.1 then continue end else continue end
                    if v == ent:GetPuppet() then continue end
                    if IsValid(ent:GetPuppet()) then
                        local alpha = ent:GetPuppet():GetColor().a or 255
                        if alpha < 255 * 0.85 then
                            table.insert(entities, v)
                        end
                    end

                end
                halo.Add(entities, Color(255,255,255), 2, 2, 5, true, false)
                halo.Add(entities, Color(255,255,255), 1, 1, 5, true, false)

            end )

            --[[
            hook.Add("PostDrawTranslucentRenderables", name5, function()
                local ply = LocalPlayer()

                local pillentity = LocalPlayer().pk_pill_ent
                local isdrgbase = false

                local screenW, screenH = ScrW(), ScrH()
                local middlex, middley = screenW*0.5, screenH*0.5
                local iconsize = screenW / 13

                if not IsValid(pillentity) then return end

                for _, v in ipairs(ents.GetAll()) do
                    if not IsValid(v) or v == ply then continue end
                    if v == ent then continue end
                    if v:IsPlayer() or v:IsNPC() or v:IsNextBot() then if v:Health()<0.1 then continue end else continue end
                    if v == ent:GetPuppet() then continue end
                    if IsValid(ent:GetPuppet()) then
                        local alpha = ent:GetPuppet():GetColor().a or 255
                        local rightval = ent.formTable.ThirdPersonBone[3]
                        if alpha < 255 * 0.85 then

                            render.ClearStencil()
                            render.SetStencilEnable(true)

                            render.SetStencilWriteMask(255)
                            render.SetStencilTestMask(255)
                            render.SetStencilReferenceValue(1)

                            render.SetStencilCompareFunction(STENCIL_ALWAYS)
                            render.SetStencilPassOperation(STENCIL_REPLACE)
                            render.SetStencilFailOperation(STENCIL_KEEP)
                            render.SetStencilZFailOperation(STENCIL_KEEP)

                            cam.IgnoreZ(false)
                            v:DrawModel()

                            render.SetStencilCompareFunction(STENCIL_EQUAL)

                            local mat_white = Material("models/debug/debugwhite")

                            render.MaterialOverride(mat_white)
                            render.SuppressEngineLighting(true)

                            render.SetBlend(1)
                            render.SetColorModulation(1, 1, 1)

                            v:DrawModel()

                            render.SuppressEngineLighting(false)
                            render.MaterialOverride(nil)
                            render.SetBlend(1)
                            render.SetColorModulation(1, 1, 1)
                            render.SetStencilEnable(false)
                            cam.IgnoreZ(false)

                        end
                    end
                end
            end)]]

            hook.Add("EntityRemoved", name5, function(removedent)
                if removedent == ent then
                    hook.Remove('CalcView', hookID)
                    hook.Remove("EntityRemoved", name5)
                    hook.Remove("PreDrawHalos", name5)
                    --hook.Remove("PostDrawTranslucentRenderables", name5)
                    for savedID, func in pairs(savedCalcViewHooks) do
                        hook.Add("CalcView", savedID, func)
                    end
                    savedCalcViewHooks = {}
                end
            end)


            local name6 = "momo_calcview_slender".. ply:Nick()
            hook.Add("CalcView", name6, function(ply, pos, ang, fov)
                if !IsValid(ent) then
                    hook.Remove("CalcView", name6)
                    return
                end

                if !IsValid(ent:GetPuppet()) then return end
                local ent = pk_pills.getMappedEnt(LocalPlayer())
                local bonename = ent.formTable.ThirdPersonBone[1]
                local boneID = ent:GetPuppet():LookupBone(bonename)
                local bonePos, boneAng = ent:GetPuppet():GetBonePosition(boneID)
                local dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                --and ply:GetViewEntity() == ply
                if IsValid(ent) then

                    if IsValid(ent:GetNWEntity("flyingent")) then
                        local startpos = ent:GetNWEntity("flyingent"):GetPos() + LocalPlayer():GetForward() * (ent.formTable.ThirdPersonBone[2]*0.25) + LocalPlayer():GetUp() * (ent.formTable.ThirdPersonBone[4]*0.25)+ LocalPlayer():GetRight() * (ent.formTable.ThirdPersonBone[3] *0.25)
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
                            start = ent:GetNWEntity("flyingent"):GetPos(),
                            endpos = tr.HitPos,
                            filter = ent.camTraceFilter,
                            mins = Vector(-5, -5, -5),
                            maxs = Vector(5, 5, 5),
                            mask = MASK_VISIBLE
                        })
                        local view = {}
                        view.origin = tr2.HitPos
                        view.angles = ang
                        view.fov = fov
                        view.drawviewer = true

                        return view
                    end

                    local startpos = pos
                    if pk_pills.convars.cl_thirdperson:GetBool() then
                        if IsValid(ent:GetPuppet()) then
                                    local alpha = ent:GetPuppet():GetColor().a or 255
                                    local rightval = ent.formTable.ThirdPersonBone[3]
                                    if alpha < 255 * 0.85 then
                                        rightval = 0
                                        dist = 0
                                    end
                                    local startpos = bonePos + LocalPlayer():GetForward() * (ent.formTable.ThirdPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.ThirdPersonBone[4])+ LocalPlayer():GetRight() * (rightval)
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
                                start = bonePos,
                                endpos = tr.HitPos,
                                filter = ent.camTraceFilter,
                                mins = Vector(-5, -5, -5),
                                maxs = Vector(5, 5, 5),
                                mask = MASK_VISIBLE
                            })
                            local view = {}
                            view.origin = tr2.HitPos
                            view.angles = ang
                            view.fov = fov
                            view.drawviewer = true

                            return view
                        end
                    else
                        if ent:GetNWInt("Slenderman1stperson") < CurTime() then
                            --[[
                            local view = {}
                            view.origin = ent:GetPos() + Vector(0,0,100)
                            view.angles = ang
                            view.fov = fov
                            view.drawviewer = true
                                
                            return view
                            ]]
                        else
                            if ent.formTable.ThirdPersonBone then
                                if IsValid(ent:GetPuppet()) then
                                    local alpha = ent:GetPuppet():GetColor().a or 255
                                    local rightval = ent.formTable.ThirdPersonBone[3]
                                    if alpha < 255 * 0.85 then
                                        rightval = 0
                                        dist = 0
                                    end
                                    local startpos = bonePos + LocalPlayer():GetForward() * (ent.formTable.ThirdPersonBone[2]) + LocalPlayer():GetUp() * (ent.formTable.ThirdPersonBone[4])+ LocalPlayer():GetRight() * (rightval)
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
                                        start = bonePos,
                                        endpos = tr.HitPos,
                                        filter = ent.camTraceFilter,
                                        mins = Vector(-5, -5, -5),
                                        maxs = Vector(5, 5, 5),
                                        mask = MASK_VISIBLE
                                    })
                                    local view = {}
                                    view.origin = tr2.HitPos
                                    view.angles = ang
                                    view.fov = fov
                                    view.drawviewer = true

                                    return view
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end)
end