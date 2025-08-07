local CustomActionBar = CreateFrame("Frame", "WhispsMountupActionBar", UIParent)
CustomActionBar:SetSize(400, 72)
CustomActionBar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CustomActionBar:SetMovable(true)
CustomActionBar:EnableMouse(true)
CustomActionBar:RegisterForDrag('LeftButton')
CustomActionBar:Hide()

local dragHandle = CreateFrame("Frame", nil, CustomActionBar, "BackdropTemplate")
dragHandle:SetSize(20, 72)
dragHandle:SetPoint("LEFT", CustomActionBar, "RIGHT", 2, 0)
dragHandle:SetMovable(true)
dragHandle:EnableMouse(true)
dragHandle:RegisterForDrag('LeftButton')

dragHandle:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
dragHandle:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
dragHandle:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

for i = 1, 3 do
    local dot = dragHandle:CreateTexture(nil, "ARTWORK")
    dot:SetSize(3, 3)
    dot:SetPoint("CENTER", dragHandle, "CENTER", 0, (i-2) * 8)
    dot:SetColorTexture(0.6, 0.6, 0.6, 0.8)
end

local function InitializeActionBarDB()
    if not WhispsMountupDB then
        WhispsMountupDB = {}
    end
    if not WhispsMountupDB.ActionBar then
        WhispsMountupDB.ActionBar = {
            slots = {},
            visible = false,
            position = { point = "CENTER", x = 0, y = 0 }
        }
    end
end

actionBarSlots = {}
local SLOT_COUNT = 8
local SLOT_SIZE = 72

local function CreateActionBarSlot(index)
    local slot = CreateFrame("Button", "WhispsMountupActionBarSlot" .. index, CustomActionBar)
    slot:SetSize(SLOT_SIZE, SLOT_SIZE)
    slot:SetPoint("LEFT", CustomActionBar, "LEFT", 2 + (index - 1) * (SLOT_SIZE - 25), 4)
    
    slot:SetNormalTexture("Interface/Buttons/UI-Quickslot")
    local normalTex = slot:GetNormalTexture()
    if normalTex then
        normalTex:SetTexCoord(0, 1, 0, 1)
        normalTex:SetVertexColor(1, 1, 1, 0.6)
    end
    
    slot:SetDisabledTexture("")

    slot:SetHighlightTexture("Interface/Buttons/UI-ActionButton-Border", "ADD")
    local highlight = slot:GetHighlightTexture()
    if highlight then
        highlight:SetSize(SLOT_SIZE - 8, SLOT_SIZE - 8)
        highlight:SetPoint("CENTER", slot, "CENTER")
        highlight:SetVertexColor(1, 1, 0, 0.4)
        highlight:SetBlendMode("ADD")
    end

    slot:SetScript("OnMouseDown", function(self)
        self:GetHighlightTexture():SetVertexColor(1, 1, 0, 1)
    end)

    slot:SetScript("OnMouseUp", function(self)
        self:GetHighlightTexture():SetVertexColor(1, 1, 0, 0.4)
    end)

    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetSize(SLOT_SIZE - 28, SLOT_SIZE - 28)
    slot.icon:SetPoint("CENTER")
    slot.icon:Hide()

    slot.cooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
    slot.cooldown:SetAllPoints(slot.icon)
    slot.cooldown:SetHideCountdownNumbers(true)

    slot:SetScript("OnEnter", function(self)
        ShowSlotTooltip(self)
    end)

    slot:SetScript("OnLeave", function(self)
        HideSlotTooltip()
    end)

    slot.slotIndex = index
    slot.listName = nil

    return slot
end

for i = 1, SLOT_COUNT do
    actionBarSlots[i] = CreateActionBarSlot(i)
end

function UpdateSlotDisplay(slot)
    if slot.listName and MountSet and MountSet[slot.listName] and #MountSet[slot.listName] > 0 then
        local firstMountId = MountSet[slot.listName][1]
        local mountName, _, icon = C_MountJournal.GetMountInfoByID(firstMountId)

        if icon and icon ~= "" then
            slot.icon:SetTexture(icon)
            slot.icon:Show()
        else
            slot.icon:SetTexture("Interface/Icons/Ability_Mount_RidingHorse")
            slot.icon:Show()
        end

    else
        slot.icon:Hide()
        slot.listName = nil
    end
end

function SaveActionBarState()
    if not WhispsMountupDB.ActionBar then return end

    for i, slot in ipairs(actionBarSlots) do
        WhispsMountupDB.ActionBar.slots[i] = slot.listName
    end

    local point, _, _, x, y = CustomActionBar:GetPoint()
    WhispsMountupDB.ActionBar.position = { point = point, x = x, y = y }
    WhispsMountupDB.ActionBar.visible = CustomActionBar:IsShown()
end

dragHandle:SetScript("OnDragStart", function(self)
    CustomActionBar:StartMoving()
end)
dragHandle:SetScript("OnDragStop", function(self)
    CustomActionBar:StopMovingOrSizing()
    SaveActionBarState()
end)

dragHandle:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
end)
dragHandle:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.2, 0.2, 0.2, 0.6)
end)

dragHandle:SetScript("OnMouseDown", function(self)
    self:SetBackdropColor(0.5, 0.5, 0, 0.8)
end)

dragHandle:SetScript("OnMouseUp", function(self)
    self:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
end)

local function LoadActionBarState()
    if not WhispsMountupDB.ActionBar then return end

    for i, listName in pairs(WhispsMountupDB.ActionBar.slots) do
        if actionBarSlots[i] then
            actionBarSlots[i].listName = listName
            UpdateSlotDisplay(actionBarSlots[i])
        end
    end

    local pos = WhispsMountupDB.ActionBar.position

    if pos then
        CustomActionBar:ClearAllPoints()
        CustomActionBar:SetPoint(pos.point or "CENTER", UIParent, pos.point or "CENTER", pos.x or 0, pos.y or 0)
    end

    if WhispsMountupDB.ActionBar.visible then
        CustomActionBar:Show()
    else
        CustomActionBar:Hide()
    end
end

local function OnSlotClick(self, button)
    if button == "LeftButton" and self.listName then
        local summonMethod = nil
        if WhispsMountupSummonDropdown then
            summonMethod = UIDropDownMenu_GetSelectedValue(WhispsMountupSummonDropdown)
        end
        
        if summonMethod == "Random" then
            randomMount(self.listName)
        elseif summonMethod == "Cycled" then
            orderedMount(self.listName)
        else
            StaticPopupDialogs["WHISPS_MOUNTUP_NO_SMETHOD"] = {
                text = "Please select a summon method first!",
                button1 = "Ok",
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("WHISPS_MOUNTUP_NO_SMETHOD")
        end
    elseif button == "RightButton" and self.listName then
        self.listName = nil
        UpdateSlotDisplay(self)
        SaveActionBarState()
    end
    
    self:SetButtonState("NORMAL")
end

for _, slot in ipairs(actionBarSlots) do
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot:SetScript("OnClick", OnSlotClick)
end

function ShowSlotTooltip(self)
    if self.listName then
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 4)
        GameTooltip:SetText(self.listName, 1, 1, 1, 1, true)

        if MountSet and MountSet[self.listName] then
            local mountCount = #MountSet[self.listName]
            GameTooltip:AddLine("Contains " .. mountCount .. " mount" .. (mountCount == 1 and "" or "s"), 1, 1, 1, true)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("|cff00ff00Left-click:|r Summon mount", 1, 1, 1, true)
            GameTooltip:AddLine("|cffff0000Right-click:|r Remove from bar", 1, 1, 1, true)
        end

        GameTooltip:Show()
    else
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 4)
        GameTooltip:SetText("Empty Mount Slot", 1, 1, 1, 1, true)
        GameTooltip:AddLine("Right-click a mount list in the Summon GUI to assign it here", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end
end

function HideSlotTooltip()
    GameTooltip:Hide()
end

local function SetupKeybinds()
    for i = 1, SLOT_COUNT do
        if i <= 8 then
            _G["BINDING_HEADER_WHISPMOUNTUP"] = "Whisp's MountUp"
            _G["BINDING_NAME_MOUNTSLOT" .. i] = "Mount Slot " .. i
        end
    end
end

local function FindEmptySlot()
    for _, slot in ipairs(actionBarSlots) do
        if not slot.listName then
            return slot
        end
    end
    return nil
end

local function AssignListToSlot(listName, targetSlot)
    if not targetSlot then
        targetSlot = FindEmptySlot()
    end

    if targetSlot then
        targetSlot.listName = listName
        UpdateSlotDisplay(targetSlot)
        SaveActionBarState()
        return true
    end

    return false
end

function UpdateActionBarSlots()
    for _, slot in ipairs(actionBarSlots) do
        if slot.listName and (not MountSet or not MountSet[slot.listName] or #MountSet[slot.listName] == 0) then
            slot.listName = nil
        end
        UpdateSlotDisplay(slot)
    end
    SaveActionBarState()
end

function ToggleCustomActionBar()
    if CustomActionBar:IsShown() then
        CustomActionBar:Hide()
    else
        CustomActionBar:Show()
    end
    SaveActionBarState()
end

function InitActionBar()
    InitializeActionBarDB()
    LoadActionBarState()
    SetupKeybinds()
end

WhispsMountupActionBar = {
    AssignListToSlot = AssignListToSlot,
    UpdateSlots = UpdateActionBarSlots,
    Toggle = ToggleCustomActionBar,
    Show = function() CustomActionBar:Show(); SaveActionBarState() end,
    Hide = function() CustomActionBar:Hide(); SaveActionBarState() end,
    IsShown = function() return CustomActionBar:IsShown() end
}

SLASH_MOUNTACTIONBAR1 = "/mab"
SLASH_MOUNTACTIONBAR2 = "/mountbar"
SlashCmdList.MOUNTACTIONBAR = function()
    ToggleCustomActionBar()
end

CustomActionBar:Hide()
