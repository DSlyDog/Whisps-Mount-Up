MountSet = {}
MountIndexes = {}

local player = {

	name = UnitName("player"),
	level = UnitLevel("player")

}

local function mountCommand(args)
	local mountIDs = C_MountJournal.GetMountIDs()

	for i, id in ipairs(mountIDs) do
		local mount = C_MountJournal.GetMountInfoByID(id)
		if mount == args then
			C_MountJournal.SummonByID(id)
		end
	end
end

local function split (input, regex)
	local result = {}
	if input == nil then
		return nil
	elseif not string.match(input, regex) then
		return nil
	end
	for str in string.gmatch(input, "([^"..regex.."]+)") do
		table.insert(result, str)
	end
	return result
end

function addMount(category, selectedMounts)
	for id, mountInfo in pairs(selectedMounts) do
		if MountSet[category][mountInfo.name] == nil then
			MountSet[category][mountInfo.name] = mountInfo.id
			table.insert(MountSet[category], mountInfo.id)
			if MountSet[category]["count"] == nil then
				MountSet[category]["count"] = 1
			else
				MountSet[category]["count"] = MountSet[category]["count"] + 1
			end
			MountIndexes[category] = MountSet[category]["count"]
			print("Successfully added " .. mountInfo.name)
		end
	end
end

local function addCategory(args)
	if MountSet[args] ~= nil then
		print("That category already exists")
		return
	end

	MountSet[args] = {}
	print("Category added")
end

function orderedMount(arg)
	if arg == "" then
		print("You must enter a category")
		return;
	end
	if MountSet[arg] == nil then
		print("That category does not exist")
		return;
	end
	if MountIndexes[arg] == nil then
		MountIndexes[arg] = 1
	end

	current = MountIndexes[arg]
	limit = MountSet[arg]["count"]

	if current >= limit then
		current = 1
	else
		current = current + 1
	end
	MountIndexes[arg] = current

	if MountSet[arg][current] ~= nil then
		C_MountJournal.SummonByID(MountSet[arg][current])
	end
end

function randomMount(arg)
	if arg == "" then
		print("You must enter a category")
		return;
	end
	if MountSet[arg] == nil then
		print("That category does not exist")
		return;
	end
	if MountSet[arg]["count"] == nil or MountSet[arg]["count"] == 0 then
		print("You have not added any mounts")
		return;
	end
	result = math.random(1, MountSet[arg]["count"])
	C_MountJournal.SummonByID(MountSet[arg][result])
end

function removeMount(category, selectedMounts)
	for id, mountInfo in pairs(selectedMounts) do
		if MountSet[category][mountInfo.name] ~= nil then
			id = MountSet[category][mountInfo.name]
			MountSet[category][mountInfo.name] = nil;
			MountSet[category]["count"] = MountSet[category]["count"] - 1;
			for i, x in ipairs(MountSet[category]) do
				if x == id then
					table.remove(MountSet[category], i)
				end
			end
		end
	end
end

local function removeCategory(arg)
	if MountSet[arg] ~= nil then
		MountSet[arg] = nil
		print("Category removed")
	else
		print("No category found with that name")
	end
end

local function list(arg)
	if arg == "" then
		print("You must enter a category")
		return;
	end

	if MountSet[arg] == nil then
		print("No category found with that name")
		return;
	end

	for mount in pairs(MountSet[arg]) do
		if string.len(mount) > 1 then
			print(mount)
		end
	end
end

local function help()
	print("/addmount:/am <category> <mount name, replacing spaces with underscores> - Adds a mount to a category")
	print("/addcategory:/ac <category> - Adds a category")
	print("/removemount:/rm <category> <mount name, replacing spaces with underscores> - Removes a mount from a category")
	print("/removecategory:/rc <category> - Removes a category")
	print("/mountlist:/ml <category> - Lists the mounts in the given category")
	print("/random <category> - Summons a random mount in the category")
	print("/ordered <category> - Summons the next mount in the category")
	print("/mounthelp:/mh - Displays this help message")
end

local function registerCommands()
	SLASH_AddMount1 = "/addmount"
	SLASH_AddMount2 = "/am"
	SlashCmdList.AddMount = addMount

	SLASH_AddCategory1 = "/addcategory"
	SLASH_AddCategory2 = "/ac"
	SlashCmdList.AddCategory = addCategory

	SLASH_Ordered1 = "/ordered"
	SlashCmdList.Ordered = orderedMount

	SLASH_Random1 = "/random"
	SlashCmdList.Random = randomMount

	SLASH_RemoveMount1 = "/removemount"
	SLASH_RemoveMount2 = "/rm"
	SlashCmdList.RemoveMount = removeMount

	SLASH_RemoveCategory1 = "/removecategory"
	SLASH_RemoveCategory2 = "/rc"
	SlashCmdList.RemoveCategory = removeCategory

    SLASH_MountList1 = "/mountlist"
    SLASH_MountList2 = "/ml"
	SlashCmdList.MountList = list

	SLASH_MountHelp1 = "/mounthelp"
	SLASH_MountHelp2 = "/mh"
	SlashCmdList.MountHelp = help
end

local function init(event, table, name)
	if name == "Whisp's Mount Up" then
		MountSet = _G["MountSet"]
		MountIndexes = _G["MountIndexes"]
		WhispsMountupDB = _G["WhispsMountupDB"]

		registerCommands();
		InitializeMinimapIcon()

		tinsert(UISpecialFrames, "WhispsMountupFrame")
		tinsert(UISpecialFrames, "WhispsMountupSelectionFrame")
		tinsert(UISpecialFrames, "WhispsMountupSummonFrame")
	end
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", init);