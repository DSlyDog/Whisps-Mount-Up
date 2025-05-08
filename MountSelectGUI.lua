function ShowMountSelectionDialog(listName)
    if not WhispsMountupSelectionFrame then
        local mountSelectFrame = CreateFrame("Frame", "WhispsMountupSelectionFrame", UIParent, "BackdropTemplate")
        mountSelectFrame:SetSize(300, 400)
        mountSelectFrame:SetPoint("CENTER")
        mountSelectFrame:SetFrameStrata("DIALOG")
        mountSelectFrame:SetMovable(true)
        mountSelectFrame:EnableMouse(true)
        mountSelectFrame:RegisterForDrag('LeftButton')
        mountSelectFrame:SetScript("OnDragStart", mountSelectFrame.StartMoving)
        mountSelectFrame:SetScript("OnDragStop", mountSelectFrame.StopMovingOrSizing)

        if BackdropTemplateMixin then
            Mixin(mountSelectFrame, BackdropTemplateMixin)
        end

        mountSelectFrame:SetBackdrop({
            bgFile = "Interface/FrameGeneral/UI-Background-Marble",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 128,
            edgeSize = 32,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        mountSelectFrame:SetBackdropColor(1, 1, 1, 0.9)
        mountSelectFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

        local titleBar = CreateFrame("Frame", nil, mountSelectFrame, "BackdropTemplate")
        titleBar:SetPoint("TOPLEFT", mountSelectFrame, "TOPLEFT", 2.5, 0)
        titleBar:SetPoint("TOPRIGHT", mountSelectFrame, "TOPRIGHT", 0, 0)
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

        local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
        title:SetText("Select Mount to Add")

        local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
        closeButton:SetScript("OnClick", function() mountSelectFrame:Hide() end)

        local scrollFrame = CreateFrame("ScrollFrame", nil, mountSelectFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 15, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(scrollFrame:GetWidth(), 1)
        scrollFrame:SetScrollChild(content)

        local confirmButton = CreateFrame("Button", nil, mountSelectFrame, "UIPanelButtonTemplate")
        confirmButton:SetSize(100, 22)
        confirmButton:SetPoint("BOTTOM", 0, 15)
        confirmButton:SetText("Add Selected")
        confirmButton:SetScript("OnClick", function()
            if listName then
                addMount(listName, mountSelectFrame.selectedMounts)
                UpdateMountList(listName)
                mountSelectFrame:Hide()
            end
        end)

        mountSelectFrame.PopulateMounts = function()
            for _, child in ipairs({content:GetChildren()}) do
                child:Hide()
                child:SetParent(nil)
            end

            local mounts = C_MountJournal.GetMountIDs()
            local buttonHeight = 30

            local collectedMounts = {}
            for i, mountID in ipairs(mounts) do
                local name, spellID, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
                if isCollected then
                    table.insert(collectedMounts, {id = mountID, name = name, icon = icon})
                end
            end

            local totalHeight = #collectedMounts * buttonHeight
            content:SetHeight(totalHeight)

            for i, mountInfo in ipairs(collectedMounts) do
                local yOffset = -(i-1) * buttonHeight
                local button = CreateFrame("Button", "WhispsMountupMount" .. i, content, "BackdropTemplate")
                button:SetSize(content:GetWidth() - 10, buttonHeight)
                button:SetPoint("TOPLEFT", content, "TOPLEFT", 5, yOffset)
                button:SetPoint("TOPRIGHT", content, "TOPRIGHT", -5, yOffset)

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
                iconTexture:SetTexture(mountInfo.icon)

                local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("LEFT", iconTexture, "RIGHT", 8, 0)
                label:SetText(mountInfo.name)
                label:SetJustifyH("LEFT")

                button:SetScript("OnClick", function()
                    if not mountSelectFrame.selectedMounts then
                        mountSelectFrame.selectedMounts = {}
                    end

                    if mountSelectFrame.selectedMounts[mountInfo.id] then
                        mountSelectFrame.selectedMounts[mountInfo.id] = nil
                    else
                        mountSelectFrame.selectedMounts[mountInfo.id] = mountInfo
                    end

                    if button.isHighlighted then
                        button:UnlockHighlight()
                        button.isHighlighted = false
                    else
                        for _, child in ipairs(content:GetChildren()) do
                            if child.isHighlighted then
                                child:UnlockHighlight()
                                child.isHighlighted = false
                            end
                        end
                        button:LockHighlight()
                        button.isHighlighted = true
                    end
                end)
            end
        end
    end

    WhispsMountupSelectionFrame.PopulateMounts()
    WhispsMountupSelectionFrame:Show()
end