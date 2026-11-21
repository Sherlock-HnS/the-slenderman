
AddCSLuaFile()

SWEP.PrintName = "No-Ammo Crowbar"

SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.ViewModel  = "models/gentoi/anologhorror/Slenderman.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = false
SWEP.DrawWorldModel = false

SWEP.Slot    = -1
SWEP.SlotPos = -1

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary = SWEP.Primary

SWEP.ViewModelBobScale = 0
SWEP.ViewModelLagScale = 0

SWEP.VM_Pos = Vector(0, -12, 0)
SWEP.VM_Ang = Angle(0, 0, 0)

function SWEP:Initialize()
    self.CurrentSeq = nil
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

function SWEP:Deploy()
    local ply = self:GetOwner()
    if not IsValid(ply) then return true end

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return true end

    local seq = vm:LookupSequence("hand_idle")
    if seq >= 0 then
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(0)
        self.CurrentSeq = seq
    end

    return true
end

SWEP.VM_Pos = Vector(0,-12,0)
SWEP.VM_Ang = Angle(0, 0, 0)

function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
    oldPos = oldPos + oldAng:Right()   * self.VM_Pos.x + oldAng:Forward() * self.VM_Pos.y + oldAng:Up() * self.VM_Pos.z

    oldAng:RotateAroundAxis(oldAng:Right(),   self.VM_Ang.p)
    oldAng:RotateAroundAxis(oldAng:Up(),      self.VM_Ang.y)
    oldAng:RotateAroundAxis(oldAng:Forward(), self.VM_Ang.r)

    return oldPos, oldAng
end

function SWEP:Think()
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end

    local vel = ply:GetVelocity():Length2D()
    local moving = vel > 10

    local seqName = moving and "hand_walk" or "hand_idle"
    local seq = vm:LookupSequence(seqName)
    if seq < 0 then return end

    if self.CurrentSeq ~= seq then
        vm:SendViewModelMatchingSequence(seq)
        vm:SetPlaybackRate(1)
        self.CurrentSeq = seq
    end
end

if CLIENT then
    function SWEP:Think()
        if self.VMColorApplied then return end

        local ply = self:GetOwner()
        if not IsValid(ply) then return end
        local vm = ply:GetViewModel()
        if not IsValid(vm) then return end
        local ent = ply.pk_pill_ent:GetPuppet()

        vm:SetRenderMode(RENDERMODE_TRANSCOLOR)
        vm:SetColor(Color(255,255,255,255))

        self.VMColorApplied = true
    end

    function SWEP:Holster()
        local ply = self:GetOwner()
        if IsValid(ply) then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                vm:SetColor(Color(255, 255, 255, 255))
                vm:SetRenderMode(RENDERMODE_NORMAL)
            end
        end
        return true
    end
    
    function SWEP:OnRemove()
        local ply = self:GetOwner()
        if IsValid(ply) then
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                vm:SetColor(Color(255, 255, 255, 255))
                vm:SetRenderMode(RENDERMODE_NORMAL)
            end
        end
    end

end
