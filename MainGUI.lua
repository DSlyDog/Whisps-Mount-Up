-- Frame Creation
local MountUpFrame = CreateFrame("Frame", "WhispsMountupFrame", UIParent, "BackdropTemplate")
MountUpFrame:SetSize(420, 500)
MountUpFrame:SetFrameStrata("MEDIUM")
MountUpFrame:SetFrameLevel(50)
MountUpFrame:SetPoint("CENTER")
MountUpFrame:SetMovable(true)
MountUpFrame:EnableMouse(true)
MountUpFrame:RegisterForDrag("LeftButton")
MountUpFrame:SetScript("OnDragStart", MountUpFrame.StartMoving)
MountUpFrame:SetScript("OnDragStop", MountUpFrame.StopMovingOrSizing)
MountUpFrame:Hide()

if BackdropTemplateMixin then
    Mixin(MountUpFrame, BackdropTemplateMixin)
end

MountUpFrame:SetBackdrop({
    bgFile = "Interface/FrameGeneral/UI-Background-Marble",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    title = true,
    titleSize = 32,
    edgeSize = 32,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

MountUpFrame:SetBackdropColor(1, 1, 1, 0.9)

local titleBar = CreateFrame("Frame", nil, MountUpFrame, "BackdropTemplate")
titleBar:SetPoint("TOPLEFT", MountUpFrame, "TOPLEFT", 2.5, 0)
titleBar:SetPoint("TOPRIGHT", MountUpFrame, "TOPRIGHT", 0, 0)
titleBar:SetHeight(30)

titleBar:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})

titleBar:SetBackdropColor(0.4, 0.4, 0.4, 1)

local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
title:SetText("Whisp's MountUp")

local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
closeButton:SetSize(30, 30)
closeButton:SetScript("OnClick", function() MountUpFrame:Hide() end)

local mountListDropdown = CreateFrame("Frame", "WhispsMountupListDropdown", MountUpFrame, "UIDropDownMenuTemplate")
mountListDropdown:ClearAllPoints()
mountListDropdown:SetPoint("TOPLEFT", MountUpFrame, "TOPLEFT", 0, -45)
mountListDropdown:SetWidth(180)


local function InitializeMountListDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    local mountLists = MountSet or {}
    local mountListNames = {}

    for name, _ in pairs(mountLists) do
        table.insert(mountListNames, name)
    end

    table.sort(mountListNames)

    if #mountListNames == 0 then
        info.text = "No lists available"
        info.disabled = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
    else
        for _, name in ipairs(mountListNames) do
            info.text = name
            info.value = name
            info.func = function(self)
                local dropdownFrame = WhispsMountupListDropdown
                UIDropDownMenu_SetSelectedValue(dropdownFrame, self.value)
                UIDropDownMenu_SetText(dropdownFrame, self.value)
                
                MountUpFrame.selectedMounts = {}
                
                UpdateMountList(self.value)
                CloseDropDownMenus()
            end
            info.checked = (UIDropDownMenu_GetSelectedValue(mountListDropdown) == name)
            info.notCheckable = false
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

UIDropDownMenu_Initialize(mountListDropdown, InitializeMountListDropdown)
UIDropDownMenu_SetWidth(mountListDropdown, 160)
UIDropDownMenu_SetButtonWidth(mountListDropdown, 174)
UIDropDownMenu_JustifyText(mountListDropdown, "LEFT")
UIDropDownMenu_SetSelectedValue(mountListDropdown, nil)
UIDropDownMenu_SetText(mountListDropdown, "Select mount list...")

local buttonContainer = CreateFrame("Frame", nil, MountUpFrame)
buttonContainer:SetSize(180, 30)
buttonContainer:ClearAllPoints()
buttonContainer:SetPoint("LEFT", mountListDropdown, "RIGHT", 15, 2.5)

local newListButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
newListButton:SetSize(85, 25)
newListButton:SetPoint("LEFT", buttonContainer, "LEFT")
newListButton:SetText("New List")
newListButton:SetScript("OnClick", function()
    StaticPopupDialogs["WHISPS_MOUNTUP_NEW_LIST"] = {
        text = "Enter a name for the new mount list",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = 1,
        maxLetters = 32,
        OnAccept = function(self)
            local listName = self.EditBox:GetText()
            if listName and listName ~= "" then
                MountSet = MountSet or {}
                if MountSet[listName] then
                    StaticPopupDialogs["WHISPS_MOUNTUP_LIST_EXISTS"] = {
                        text = "A list with that name already exists!",
                        button1 = "Ok",
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                        preferredIndex = 3,
                    }

                    StaticPopup_Show("WHISPS_MOUNTUP_LIST_EXISTS")
                    return
                end

                MountSet[listName] = {}
                RefreshMountListDropdown()

                UIDropDownMenu_SetSelectedValue(mountListDropdown, listName)
                UIDropDownMenu_SetText(mountListDropdown, listName)

                UpdateMountList(listName)
                
                if UpdateList then
                    UpdateList()
                end
            end
        end,
        OnShow = function(self)
            self.EditBox:SetFocus()
        end,
        OnHide = function(self)
            self.EditBox:SetText("")
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local dialog = StaticPopupDialogs["WHISPS_MOUNTUP_NEW_LIST"]
            if dialog and dialog.OnAccept then
                dialog.OnAccept(parent)
                parent:Hide()
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("WHISPS_MOUNTUP_NEW_LIST")
end)

local deleteListButton = CreateFrame("Button", nil, buttonContainer, "UIPanelButtonTemplate")
deleteListButton:SetSize(85, 25)
deleteListButton:SetPoint("RIGHT", buttonContainer, "RIGHT")
deleteListButton:SetText("Delete List")
deleteListButton:SetScript("OnClick", function()
    local selectedList = UIDropDownMenu_GetSelectedValue(mountListDropdown)

    if not selectedList or not MountSet or not MountSet[selectedList] then
        print("No mount list selected")
        return
    end

    StaticPopupDialogs["WHISPS_MOUNTUP_DELETE_LIST"] = {
        text = "Are you sure you want to delete the mount list: " .. selectedList .. "?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function(self)
            MountSet[selectedList] = nil
            print("Deleted mount list: " .. selectedList)
            RefreshMountListDropdown()

            UIDropDownMenu_Initialize(mountListDropdown, InitializeMountListDropdown)
            UIDropDownMenu_SetSelectedValue(mountListDropdown, nil)
            UIDropDownMenu_SetText(mountListDropdown, "Select mount list...")

            UpdateMountList(nil)
            
            if UpdateList then
                UpdateList()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("WHISPS_MOUNTUP_DELETE_LIST")
end)

local mountListLabel = MountUpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mountListLabel:SetPoint("TOPLEFT", mountListDropdown, "BOTTOMLEFT", 20, -15)
mountListLabel:SetText("Mounts in this list:")

local scrollFrame = CreateFrame("ScrollFrame", "WhispsMountupMainScrollFrame", MountUpFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(350, 320)
scrollFrame:SetPoint("TOPLEFT", mountListLabel, "BOTTOMLEFT", 0, -10)

local contentFrame = CreateFrame("Frame", "WhispsMountupMainContentFrame", scrollFrame)
contentFrame:SetSize(scrollFrame:GetWidth() - 16, 1)
scrollFrame:SetScrollChild(contentFrame)

MountUpFrame:SetScript("OnShow", function()
    mountListLabel:Hide()
    scrollFrame:Hide()

    MountUpFrame.selectedMounts = {}

    local selectedList = UIDropDownMenu_GetSelectedValue(mountListDropdown)
    if selectedList then
        UpdateMountList(selectedList)
    end
end)

local bottomButtonContainer = CreateFrame("Frame", nil, MountUpFrame)
bottomButtonContainer:SetSize(250, 30)
bottomButtonContainer:ClearAllPoints()
bottomButtonContainer:SetPoint("TOP", scrollFrame, "BOTTOM", 20, -20)

local addMountButton = CreateFrame("Button", nil, bottomButtonContainer, "UIPanelButtonTemplate")
addMountButton:SetSize(115, 22)
addMountButton:SetText("Add Mounts")
addMountButton:SetPoint("LEFT", bottomButtonContainer, "LEFT", 5, 0)

addMountButton:SetScript("OnClick", function()
    ShowMountSelectionDialog(UIDropDownMenu_GetSelectedValue(mountListDropdown))
end)

addMountButton:Hide()

local removeMountButton = CreateFrame("Button", nil, bottomButtonContainer, "UIPanelButtonTemplate")
removeMountButton:SetSize(115, 22)
removeMountButton:SetText("Remove Mounts")
removeMountButton:SetPoint("RIGHT", bottomButtonContainer, "RIGHT", -5,0)

removeMountButton:SetScript("OnClick", function()
    if MountUpFrame.selectedMounts == nil then
        MountUpFrame.selectedMounts = {}
    end
    
    local selectedCount = 0
    for _ in pairs(MountUpFrame.selectedMounts) do
        selectedCount = selectedCount + 1
    end
    
    if selectedCount == 0 then
        StaticPopupDialogs["WHISPS_MOUNTUP_REMOVE_NS"] = {
            text = "Please select mounts to remove before pressing the 'Remove Mounts' button!",
            button1 = "Ok",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }

        StaticPopup_Show("WHISPS_MOUNTUP_REMOVE_NS")
        return
    end
    removeMount(UIDropDownMenu_GetSelectedValue(mountListDropdown), MountUpFrame.selectedMounts)
    MountUpFrame.selectedMounts = {}
    UpdateMountList(UIDropDownMenu_GetSelectedValue(mountListDropdown))
    
    if UpdateList then
        UpdateList()
    end
end)

removeMountButton:Hide()

local mountButtons = {}

function RefreshMountListDropdown()
    if not mountListDropdown then
        return
    end

    local currentSelection = UIDropDownMenu_GetSelectedValue(mountListDropdown)
    UIDropDownMenu_Initialize(mountListDropdown, InitializeMountListDropdown)

    if currentSelection and MountSet and MountSet[currentSelection] then
        UIDropDownMenu_SetSelectedValue(mountListDropdown, currentSelection)
        UIDropDownMenu_SetText(mountListDropdown, currentSelection)
    else
        UIDropDownMenu_SetSelectedValue(mountListDropdown, nil)
        UIDropDownMenu_SetText(mountListDropdown, "Select mount list...")
    end
end

function UpdateMountList(listName)
    for _, button in ipairs(mountButtons) do
        button:Hide()
    end
    wipe(mountButtons)

    if not MountSet or not MountSet[listName] then
        scrollFrame:Hide()
        mountListLabel:Hide()
        addMountButton:Hide()
        removeMountButton:Hide()
        return
    end

    scrollFrame:Show()
    mountListLabel:Show()
    addMountButton:Show()
    removeMountButton:Show()

    local mountIds = MountSet[listName]
    if not mountIds or #mountIds == 0 then
        mountListLabel:SetText("No mounts in this list")
        return
    else
        mountListLabel:SetText("Mounts in " .. listName .. ":")
    end

    local buttonHeight = 30
    local buttonWidth = scrollFrame:GetWidth() - 25
    local yOffset = 0

    for i, mountId in ipairs(mountIds) do
        local name, spellId, icon = C_MountJournal.GetMountInfoByID(mountId)

        if name then
            local button = CreateFrame("Button", "WhispsMountupMount" .. i, contentFrame, "BackdropTemplate")
            button:SetSize(buttonWidth, buttonHeight)
            button:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 5, -yOffset)

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

            local iconTexture = button:CreateTexture(nil, "ARTWORK")
            iconTexture:SetSize(buttonHeight - 6, buttonHeight - 6)
            iconTexture:SetPoint("LEFT", button, "LEFT", 3, 0)
            iconTexture:SetTexture(icon)

            local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", iconTexture, "RIGHT", 8, 0)
            label:SetText(name)
            label:SetJustifyH("LEFT")

            button:SetScript("OnClick", function(self, buttonType, down)
                if not MountUpFrame.selectedMounts then
                    MountUpFrame.selectedMounts = {}
                end

                if MountUpFrame.selectedMounts[mountId] then
                    MountUpFrame.selectedMounts[mountId] = nil
                    button:UnlockHighlight()
                    button.isHighlighted = false
                else
                    MountUpFrame.selectedMounts[mountId] = {id = mountId, name = name}
                    button:LockHighlight()
                    button.isHighlighted = true
                end
            end)

            table.insert(mountButtons, button)
            yOffset = yOffset + buttonHeight + 2
        end
    end

    contentFrame:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
end

-- Slash Commands
SLASH_MOUNTGUI1 = "/mountgui"
SLASH_MOUNTGUI2 = "/mg"
SlashCmdList.MOUNTGUI = function()
    if MountUpFrame:IsShown() then
        MountUpFrame:Hide()
    else
        MountUpFrame:Show()
    end
end
