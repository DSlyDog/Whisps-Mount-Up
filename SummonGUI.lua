local SummonFrame = CreateFrame("Frame", "WhispsMountupSummonFrame", UIParent, "BackdropTemplate")
SummonFrame:SetSize(300, 400)
SummonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
SummonFrame:SetMovable(true)
SummonFrame:EnableMouse(true)
SummonFrame:RegisterForDrag('LeftButton')
SummonFrame:SetScript("OnDragStart", SummonFrame.StartMoving)
SummonFrame:SetScript("OnDragStop", SummonFrame.StopMovingOrSizing)
SummonFrame:SetScript("OnShow", function()
    UpdateList()
end)
SummonFrame:Hide()

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

function InitializeMountListDropdown(self, level)
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
        end
        info.checked = (UIDropDownMenu_GetSelectedValue(mountListDropdown) == method)
        info.notCheckable = false
        UIDropDownMenu_AddButton(info, level)
    end
end

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

local scrollFrame = CreateFrame("ScrollFrame", "WhispsMountupScrollFrame", SummonFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(SummonFrame:GetWidth(), SummonFrame:GetHeight() - 100)
scrollFrame:SetPoint("TOPLEFT", mountListDropdown, "BOTTOMLEFT", -70, 0)

local contentFrame = CreateFrame("Frame", "WhispsMountupContentFrame", scrollFrame)
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
            local button = CreateFrame("Button", "WhispsMountupSummonButton" .. i, contentFrame, "BackdropTemplate")
            button:SetSize(buttonWidth, buttonHeight)
            button:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 50, -yOffset)

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

            button:SetScript("OnClick", function()
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
            end)

            table.insert(mountListButtons, button)
            yOffset = yOffset + buttonHeight + 2
        end

        contentFrame:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
    end
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
        UIDropDownMenu_Initialize(mountListDropdown, InitializeMountListDropdown)
    end
end