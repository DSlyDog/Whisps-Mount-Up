local SummonParent = CreateFrame("Frame", "WhispsMountupSummonParent", UIParent)
SummonParent:SetFrameStrata("MEDIUM")
SummonParent:SetFrameLevel(100)
SummonParent:SetAllPoints(UIParent)

local SummonFrame = CreateFrame("Frame", "WhispsMountupSummonFrame", SummonParent, "BackdropTemplate")
SummonFrame:SetSize(300, 400)
SummonFrame:SetFrameStrata("MEDIUM")
SummonFrame:SetFrameLevel(200)
SummonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
SummonFrame:SetMovable(true)
SummonFrame:EnableMouse(true)
SummonFrame:RegisterForDrag('LeftButton')
SummonFrame:SetScript("OnDragStart", SummonFrame.StartMoving)
SummonFrame:SetScript("OnDragStop", SummonFrame.StopMovingOrSizing)
SummonFrame:Hide()

-- Add this to the SummonFrame setup
SummonFrame:SetScript("OnHide", function()
    -- Clean up any ongoing drag operation
    if isDragActive then
        isDragActive = false
        draggedListName = nil
        _G.WHISPS_DRAGGED_LIST = nil
        ResetCursor()
    end
    UpdateList()
end)

-- Visual Elements
if BackdropTemplateMixin then
    Mixin(SummonFrame, BackdropTemplateMixin)
end

SummonFrame:SetBackdrop({
    bgFile = "Interface/FrameGeneral/UI-Background-Marble",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 128,
    edgeSize = 32,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

SummonFrame:SetBackdropColor(1, 1, 1, 0.9)
SummonFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

local titleBar = CreateFrame("Frame", nil, SummonFrame, "BackdropTemplate")
titleBar:SetPoint("TOPLEFT", SummonFrame, "TOPLEFT", 2.5, 0)
titleBar:SetPoint("TOPRIGHT", SummonFrame, "TOPRIGHT", 0, 0)
titleBar:SetHeight(24)

titleBar:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

titleBar:SetBackdropColor(0.4, 0.4, 0.4, 1)

local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
title:SetText("Summon Mounts")

local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetSize(20, 20)
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -2, -2)
closeButton:SetScript("OnClick", function() SummonFrame:Hide() end)

local mountListDropdown = CreateFrame("Frame", "WhispsMountupSummonDropdown", SummonFrame, "UIDropDownMenuTemplate")
mountListDropdown:SetPoint("TOP", titleBar, "BOTTOM", -12, -10)

local function InitializeMountListDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()

    local summonMethods = {
        { text = "Random", value = "Random", description = "Summons a random mount from the list" },
        { text = "Cycled", value = "Cycled", description = "Cycles through mounts in the list sequentially" }
    }

    for _, method in ipairs(summonMethods) do
        info.text = method.text
        info.value = method.value
        info.tooltipTitle = method.text
        info.tooltipText = method.description

        info.func = function(self)
            UIDropDownMenu_SetSelectedValue(mountListDropdown, self.value)
            UIDropDownMenu_SetText(mountListDropdown, self.value)
            CloseDropDownMenus()

            if WhispsMountupDB then
                WhispsMountupDB["selectedSummonMethod"] = method
            end
        end
        info.checked = (UIDropDownMenu_GetSelectedValue(mountListDropdown) == method)
        info.notCheckable = false
        UIDropDownMenu_AddButton(info, level)
    end

    if WhispsMountupDB and WhispsMountupDB["selectedSummonMethod"] then
        UIDropDownMenu_SetSelectedValue(mountListDropdown, WhispsMountupDB["selectedSummonMethod"].value)
        UIDropDownMenu_SetText(mountListDropdown, WhispsMountupDB["selectedSummonMethod"].value)
    end
end

SummonFrame:SetScript("OnShow", function()
    UpdateList()
    -- Only reinitialize if not already set up
    if not UIDropDownMenu_GetSelectedValue(mountListDropdown) then
        UIDropDownMenu_Initialize(mountListDropdown, InitializeMountListDropdown)
    end
end)

UIDropDownMenu_Initialize(mountListDropdown, InitializeMountListDropdown)
UIDropDownMenu_SetWidth(mountListDropdown, 160)
UIDropDownMenu_SetButtonWidth(mountListDropdown, 174)
UIDropDownMenu_JustifyText(mountListDropdown, "LEFT")
UIDropDownMenu_SetSelectedValue(mountListDropdown, nil)
UIDropDownMenu_SetText(mountListDropdown, "Select summon type...")

local noListText = SummonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
noListText:SetPoint("CENTER", SummonFrame, "CENTER", 0, 0)
noListText:SetText("No mount lists available")
noListText:Hide()

local scrollFrame = CreateFrame("ScrollFrame", "WhispsMountupSummonScrollFrame", SummonFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(SummonFrame:GetWidth(), SummonFrame:GetHeight() - 100)
scrollFrame:SetPoint("TOPLEFT", mountListDropdown, "BOTTOMLEFT", -70, 0)

local contentFrame = CreateFrame("Frame", "WhispsMountupSummonContentFrame", scrollFrame)
contentFrame:SetSize(scrollFrame:GetWidth() - 16, 1)
scrollFrame:SetScrollChild(contentFrame)

local listManagementButton = CreateFrame("Button", nil, SummonFrame, "UIPanelButtonTemplate")
listManagementButton:SetSize(180, 22)
listManagementButton:SetPoint("BOTTOM", SummonFrame, "BOTTOM", 0, 10)
listManagementButton:SetText("List Management")

listManagementButton:SetScript("OnClick", function()
    if WhispsMountupFrame and not WhispsMountupFrame:IsShown() then
        WhispsMountupFrame:Show()
    end
end)


local lastMountID = nil
lastMountName = nil
local function HookMountFunction()
    local originalSummonByID = C_MountJournal.SummonByID
    C_MountJournal.SummonByID = function(mountID, ...)
        lastMountID = mountID
        lastMountName = C_MountJournal.GetMountInfoByID(mountID) or "mount"
        return originalSummonByID(mountID, ...)
    end
end

local mountListButtons = {}

local function ShowSlotAssignmentPopup(listName, x, y)
    local popup = CreateFrame("Frame", "WhispsMountupSlotPopup", UIParent, "BackdropTemplate")
    popup:SetSize(280, 320)  -- Made wider and taller for better spacing
    popup:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    popup:SetFrameStrata("TOOLTIP")
    popup:SetFrameLevel(1000)

    if BackdropTemplateMixin then
        Mixin(popup, BackdropTemplateMixin)
    end
    
    popup:SetBackdrop({
        bgFile = "Interface/FrameGeneral/UI-Background-Marble",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 128,
        edgeSize = 32,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    popup:SetBackdropColor(1, 1, 1, 0.9)
    popup:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    local titleBar = CreateFrame("Frame", nil, popup, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", popup, "TOPLEFT", 2.5, 0)
    titleBar:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 0, 0)
    titleBar:SetHeight(28)  -- Made taller to match other panels

    titleBar:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    titleBar:SetBackdropColor(0.4, 0.4, 0.4, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    title:SetText("Assign to Action Bar Slot")

    local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
    closeButton:SetSize(30, 30)
    closeButton:SetScript("OnClick", function() popup:Hide() end)

    local subtitle = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", titleBar, "BOTTOM", 0, -10)
    subtitle:SetText("List: " .. listName)

    local buttonHeight = 22
    local buttonWidth = 240
    
    for i = 1, 8 do
        local slotButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        slotButton:SetSize(buttonWidth, buttonHeight)
        slotButton:SetPoint("TOP", subtitle, "BOTTOM", 0, -15 - (i-1) * (buttonHeight + 4))  -- More spacing between buttons

        local currentSlot = actionBarSlots[i]
        local buttonText = "Slot " .. i
        if currentSlot and currentSlot.listName then
            buttonText = buttonText .. " (currently: " .. currentSlot.listName .. ")"
        else
            buttonText = buttonText .. " (empty)"
        end
        
        slotButton:SetText(buttonText)
        
        slotButton:SetScript("OnClick", function()
            if WhispsMountupActionBar and WhispsMountupActionBar.AssignListToSlot then
                WhispsMountupActionBar.AssignListToSlot(listName, currentSlot)
                print("Assigned '" .. listName .. "' to slot " .. i)
            else
                currentSlot.listName = listName
                UpdateSlotDisplay(currentSlot)
                SaveActionBarState()
            end
            popup:Hide()
        end)
    end

    local cancelButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    cancelButton:SetSize(100, 22)
    cancelButton:SetPoint("BOTTOM", popup, "BOTTOM", 0, 15)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function() popup:Hide() end)

    popup:SetScript("OnHide", function() popup:SetParent(nil) end)

    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            popup:Hide()
        end
    end)
    popup:EnableKeyboard(true)
    popup:SetPropagateKeyboardInput(true)
    
    popup:Show()
end

function UpdateList()
    for _, button in ipairs(mountListButtons) do
        button:Hide()
    end
    wipe(mountListButtons)

    if not MountSet or not type(MountSet) == "table" then
        scrollFrame:Hide()
        noListText:Show()
        return
    end

    scrollFrame:Show()
    noListText:Hide()

    local buttonHeight = 30
    local buttonWidth = scrollFrame:GetWidth() - 50
    local yOffset = 0

    local mountListNames = {}

    for listName, _ in pairs(MountSet) do
        table.insert(mountListNames, listName)
    end

    table.sort(mountListNames)

    for i, listName in ipairs(mountListNames) do
        if MountSet[listName] and #MountSet[listName] > 0 then
            local button = CreateFrame("Button", "WhispsMountupSummonListButton" .. i, contentFrame, "BackdropTemplate")
            button:SetSize(buttonWidth, buttonHeight)
            button:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 50, -yOffset)

            -- Button setup code (backdrop, icon, etc.)
            button:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                title = true,
                titleSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            button:SetBackdropColor(0.1, 0.1, 0.1, 1)
            button:SetHighlightTexture("Interface\\Buttons\\UI-ListBox-Highlight", "ADD")

            local firstMountId = MountSet[listName][1]
            local _, _, icon = C_MountJournal.GetMountInfoByID(firstMountId)

            local iconTexture = button:CreateTexture(nil, "ARTWORK")
            iconTexture:SetSize(buttonHeight - 6, buttonHeight - 6)
            iconTexture:SetPoint("LEFT", button, "LEFT", 3, 0)
            iconTexture:SetTexture(icon)

            local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", iconTexture, "RIGHT", 8, 0)
            label:SetText(listName)
            label:SetJustifyH("LEFT")

            -- Simple drag detection using timers
            button:SetScript("OnMouseDown", function(self, mouseButton)
                if mouseButton == "LeftButton" then
                    dragStartTime = GetTime()
                    draggedListName = listName
                    
                    -- Use a timer to start drag after 0.3 seconds
                    C_Timer.After(0.3, function()
                        -- Check if we're still holding down the button on this specific button
                        if IsMouseButtonDown("LeftButton") and draggedListName == listName and not isDragActive then
                            isDragActive = true
                            _G.WHISPS_DRAGGED_LIST = listName
                            SetCursor("Interface\\Cursor\\Item")
                        end
                    end)
                end
            end)

            button:SetScript("OnMouseUp", function(self, mouseButton)
                if mouseButton == "LeftButton" then
                    -- Regular click (summon mount)
                    local summonMethod = UIDropDownMenu_GetSelectedValue(mountListDropdown)
                    if summonMethod == "Random" then
                        randomMount(listName)
                    elseif summonMethod == "Cycled" then
                        orderedMount(listName)
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
                elseif mouseButton == "RightButton" then
                    -- Right-click: show slot assignment popup
                    local x, y = GetCursorPosition()
                    local scale = UIParent:GetEffectiveScale()
                    ShowSlotAssignmentPopup(listName, x/scale, y/scale)
                end
            end)

            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(listName, 1, 1, 1, 1, true)
                GameTooltip:AddLine("|cff00ff00Left-click:|r Summon mount", 0.8, 0.8, 0.8, true)
                GameTooltip:AddLine("|cffff8000Right-click:|r Assign to action bar slot", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            table.insert(mountListButtons, button)
            yOffset = yOffset + buttonHeight + 2
        end
    end

    contentFrame:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
end

HookMountFunction()
UpdateList()

-- Commands
SLASH_QUICKMOUNT1 = "/qm"
SLASH_QUICKMOUNT2 = "/quickmount"
SlashCmdList.QUICKMOUNT = function()
    if SummonFrame:IsShown() then
        SummonFrame:Hide()
    else
        SummonFrame:Show()
    end
end