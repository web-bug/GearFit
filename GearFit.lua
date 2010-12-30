-- we want the GF data to remain on screen until explicitly closed
-- therefore, we will be using ItemRefTooltip rather than GameTooltip

local function showTooltip(self,linkData)
-- used only for showing the hyperlink data from a chat frame
	local linkType = string.split(":", linkData)	
	if linkType =="item"
	or linkType =="spell"
	or linkType =="enchant"
	or linkType =="quest"
	or linkType =="talent"
	or linkType =="glyph"
	or linkType =="unit"
	or linkType =="achievement" then
		GameTooltip:SetOwner(self,"ANCHOR_CUSOR")
		GameTooltip:SetHyperlink(linkData)
		GameTooltip:Show()
	end
end

local function hideTooltip(...)
	GameTooltip:Hide()
end

local function setOrHookHandler(frame, script, func)
	if frame:GetScript(script) then
		frame:HookScript(script, func) -- substitue our function for the one already there
	else
		frame:SetScript(script, func) -- otherwise just set ours
	end
end

-- grab global game space event handlers and overload with our own
-- I don't know why, but this has to be in done in the global space, not in a function
for i = 1, NUM_CHAT_WINDOWS do
	local frame = getglobal("ChatFrame"..i)
	if frame then
		setOrHookHandler(frame, "OnHyperLinkEnter", showTooltip)
		setOrHookHandler(frame, "OnHyperLinkLeave", hideTooltip)
	end
end

-- everything below here is our namespace
-- define our color scheme
local gf_Color = {
	["White"] = "|c00ffffff",
	["Red"] = "|c00ff0000",
	["Green"] = "|c00009900",
	["Pink"] = "|c00ff00ff",
	["Blue"] = "|c0000ffff";
}

-- Set the standard color for our name
local gf_Name = gf_Color["Green"].."GearFit|r";

local gf_InvSlotName = {"head","neck","shoulder","shirt","chest","belt","legs","feet",
	"wrist","gloves","finger 1","finger 2","trinket 1","trinket 2","back",
	"main hand","off hand","ranged"}
	
-- map blizzard names to appropriate slot numbers
local gf_EquipSlotName = {
	["INVTYPE_HEAD"] = 1,
	["INVTYPE_NECK"] = 2,
	["INVTYPE_SHOULDER"] = 3,
	["INVTYPE_BODY"] = 0, -- actually 4, but we don't care about shirts
	["INVTYPE_CHEST"]= 5,
	["INVTYPE_ROBE"] = 5,
	["INVTYPE_WAIST"] = 6,
	["INVTYPE_LEGS"] = 7,
	["INVTYPE_FEET"] = 8,
	["INVTYPE_WRIST"] = 9,
	["INVTYPE_HAND"] = 10,
	["INVTYPE_FINGER"] = 11, -- or 12 actually
	["INVTYPE_TRINKET"] = 13, -- or 14 actually
	["INVTYPE_CLOAK"] = 15,
	["INVTYPE_WEAPON"] = 16, -- or 17 actually
	["INVTYPE_2HWEAPON"] = 16,
	["INVTYPE_WEAPONMAINHAND"] = 16,
	["INVTYPE_WEAPONOFFHAND"] = 17,
	["INVTYEP_HOLDABLE"] = 17,
	["INVTYPE_RANGEDRIGHT"] = 18,
	["INVTYPE_THROWN"] = 18,
	["INVTYPE_RANGED"] = 18;
}
	
local gf_Class_Data = {
	["Mage"] = "Intellect",
	["Mage2"] = "Spirit",
	["MageA"] = "Cloth",
	["Priest"] = "Intellect",
	["Priest2"] = "Spirit",
	["PriestA"] = "Cloth",
	["Warlock"] = "Spirit",
	["Warlock2"] = "Intellect",
	["WarlockA"] = "Cloth",
	["Paladin"] = "Stamina",
	["Paladin2"] = "Strength",
	["PaladinA"] = "Plate",
	["Warrior"] = "Strength",
	["Warrior2"] = "Stamina",
	["WarriorA"] = "Plate",
	["Death Knight"] = "Strenght",
	["Death Knight2"] = "Stamina",
	["Death KnightA"] = "Plate",
	["Rogue"] = "Agility",
	["Rogue2"] = "Strength",
	["RogueA"] = "Leather",
	["Druid"] = "Strength",
	["Druid2"] = "Stamina",
	["DruidA"] = "Leather",
	["Hunter"] = "Agility",
	["Hunter2"] = "Stamina",
	["HunterA"] = "Leather",
	["Shaman"] = "Intellect",
	["Shaman2"] = "Stamina",
	["ShamanA"] = "Chain";
}

-- calculates the suitability data for an item passed as an itemLink
local function GF_ItemScore(itemLink)
	-- calculate suitability for class
	-- and how much suitable stat gain you get from item
	local gf_ItemSuit = "Not Suitable"
	local gf_Stat = 0
	local gf_Level = "Too High"
	local gf_Slot = 1
	local gf_Equippable = 0
	local myLevel = UnitLevel("player")
	local myClass = UnitClass("player")
	

	-- class specific armor changes
	if (myClass == "Shaman") then
	-- check if our level is over 40
		if (myLevel > 39 ) then
			gf_Class_Data["ShamanA"] = "Chain"
		else
			gf_Class_Data["ShamanA"] = "Leather"
		end
	end
	if (myClass == "Paladin") then
	-- check if our level is over 40
		if (myLevel > 39 ) then
			gf_Class_Data["PaladinA"] = "Plate"
		else
			gf_Class_Data["PaladinA"] = "Chain"
		end
	end
	
	-- if you haven't seen an item before, blizzard will sometimes return the item link as nil
	if (itemLink ~= nil) then
		local stats  = GetItemStats(itemLink)
		local i_Name, i_Link, i_Rarity, i_iLevel, i_MinLevel, i_Type, i_SubType, i_StackCount, i_Slot = GetItemInfo(itemLink);
		
		-- first off, let's find out if it equipable
		gf_Equippable = IsEquippableItem(itemLink)
		if (gf_Equippable ~= nil) then
			-- yes it Is
			local c_Name, c_Link, c_Rarity, c_iLevel, c_MinLevel, c_iType, C_SubType, c_Stack, c_Slot = GetItemInfo(itemLink)
			gf_Slot = gf_EquipSlotName[c_Slot]
		end
		
		-- first thing we need to know. Is it weapon or armor?
		if (i_Type == "Weapon" or i_Type == "Armor") then
			if (myLevel >= i_MinLevel) then
			-- we can use it so go ahead
				gf_Level = "Usable"
			end
			for stat, value in pairs(stats) do
				if (_G[stat] == gf_Class_Data[myClass] or _G[stat] == gf_Class_Data[myClass.."2"]) then
					gf_ItemSuit = "Suitable"
					gf_Stat = gf_Stat + value
				end
			end
			gf_ItemSuit = gf_ItemSuit
		else
			gf_ItemSuit = i_Type..": "..i_SubType
		end
		if i_SubType then
			if (i_SubType == "Fishing Poles") then
				gf_ItemSuit = "Suitable: use often!"
			end
			if (i_SubType == "Food & Drink") then
				gf_ItemSuit = "Food! Yum!"
			end
			if (i_SubType == "Meat") then
				gf_ItemSuit = "Why not cook it?"
			end
		end
	else
		gf_ItemSuit = "No Data Returned"
		gf_Stat = 0
	end
	return gf_ItemSuit, gf_Stat, gf_Slot
end

-- returns the players overall iLevel, a table of items, a table of item scores for each equiped slot
local function GF_Score()
	local slotItemID = {}
	local slotItemData= {}
	local slotItemStat = {}
	local gf_iLevels = 0
	local gf_Tally = 0
	local gf_Stat = 0

	-- load the items and use iLevel for upgrade notice
	for i=1, 18 do
		slotItemID[i] = GetInventoryItemID("player",i)
		if (slotItemID[i] == nil) then
			slotItemData[i] = "Needed"
		else
			local i_Name, i_Link, i_Rarity, i_iLevel, i_MinLevel, i_Type, i_SubType, i_StackCount = GetItemInfo(slotItemID[i]);
			if i_iLevel ~= nil then
				gf_iLevels = gf_iLevels + i_iLevel
			end
			slotItemData[i], slotItemStat[i] = GF_ItemScore(i_Link)
		end
		if (slotItemData[i] == "Suitable") then
			gf_Tally = gf_Tally + 1
		end
	end
	gf_iLevels = gf_iLevels/17
	
	return gf_iLevels, slotItemID, slotItemData, slotItemStat, gf_Tally
end


-- run when use types one of the slash commands
function GearFit_OnSlash(arguments)
	
	local chatFrame = ""	
	local slotItemID = {}
	local slotItemData = {}
	local slotItemStat ={}
	local gf_iLevels = 0
	local gf_Tally = 0
	
	-- get the data for each item
	gf_iLevels, slotItemID, slotItemData, slotItemStat, gf_Tally = GF_Score()
	
	
	-- display the results where wanted
	if (arguments=="g") then
	-- messages go to guild chat
		chatFrame = "Guild"
	elseif (arguments=="s") then
	-- message go to say chat
		chatFrame = "Say"
	elseif (arguments=="p") then
	-- messages go to party chat
		chatFrame = "Party"
	elseif (arguments=="r") then
	-- messages go to raid chat
		chatFrame = "Raid"
	elseif (arguments=="b") then
	-- messages go to battle ground chat
		chatFrame = "Battleground"	
	elseif (arguments=="?") then
		chatFrame="None"
		DEFAULT_CHAT_FRAME:AddMessage(gf_Name..":|r ? for help, g, s, p, b, r, a for guild, say, party, battelground, raid, full report")
		DEFAULT_CHAT_FRAME:AddMessage(gf_Name..":|r GearFit score is the iLevel you are currently working towards")
		DEFAULT_CHAT_FRAME:AddMessage(gf_Name..":|r Yes or No is class suitablity. Some sockets are rarely suitable")
		DEFAULT_CHAT_FRAME:AddMessage(gf_Name..":|r the number after Yes or No is the amount of suitable stat gain")
		
	elseif (arguments=="") then
	-- message go to default message frame
		chatFrame = "Default"
	elseif (arguments == "a") then
	-- report for all gear
		chatFrame = "None"
		for i=1, 18 do
			if (i ~= 4) then
				if (slotItemID[i] == nil ) then
					-- item slot is blank
					DEFAULT_CHAT_FRAME:AddMessage("GF: "..gf_InvSlotName[i].." is empty.")
				else
					local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(slotItemID[i]);
					slotItemData[i], slotItemStat[i] = GF_ItemScore(sLink)
					DEFAULT_CHAT_FRAME:AddMessage("GF: "..gf_InvSlotName[i].." "..sLink.." "..slotItemData[i]..": "..slotItemStat[i])
				end
			end
		end
	end
	
	if (chatFrame == "Default") then
		DEFAULT_CHAT_FRAME:AddMessage(string.format("GearFit: %3.1f %2i/17",gf_iLevels, gf_Tally))
		for i=1, 18 do
			if (i ~= 4) then
				if (slotItemID[i] == nil) then
					-- item is empty
					DEFAULT_CHAT_FRAME:AddMessage("GF: "..gf_InvSlotName[i].." is empty.")
				else
					local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(slotItemID[i]);
					slotItemData[i], slotItemStat[i] = GF_ItemScore(sLink)
					if (iLevel < gf_iLevels-10 ) then
						DEFAULT_CHAT_FRAME:AddMessage("Upgrade: "..gf_InvSlotName[i]..sLink.." "..slotItemStat[i])
					end
				end
			end
		end
	elseif (chatFrame=="None") then
		-- don't print a message
	else
		SendChatMessage(string.format(UnitName("player").."'s GearFit Score is: %3.f %2i/17",gf_iLevels,gf_Tally),chatFrame)
		-- which slots to upgrade
		for i=1, 18 do
			if (i ~= 4) then
				if (slotItemID[i] == nil) then
					-- slot is empty
					SendChatMessage("GF: "..gf_InvSlotName[i].." is empty.", chatFrame)
				else
					local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(slotItemID[i]);
					slotItemData[i], slotItemStat[i] = GF_ItemScore(sLink)
					if (iLevel < gf_iLevels-10 ) then
						SendChatMessage("Upgrade "..gf_InvSlotName[i]..sLink.." "..slotItemStat[i], chatFrame)
					end
				end
			end
		end
	end
	table.wipe(slotItemID)
	table.wipe(slotItemData)
	table.wipe(slotItemStat)
end

-- run when the UI calls for an update
function GearFit_OnUpdate()

	DEFAULT_CHAT_FRAME:AddMessage( "[GearFit]: GearFit Updated. Use /gearfit or /gf to trigger report" );
end

-- run when UI loads the Addon
function GearFit_OnLoad()

	SlashCmdList[ "GearFit" ] = GearFit_OnSlash;
	SLASH_GearFit1 = "/gearfit";
	SLASH_GearFit2 = "/gf";

	GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared)
	

	DEFAULT_CHAT_FRAME:AddMessage( gf_Name.." Loaded. Use"..gf_Color["Green"].." /gearfit |r or"..gf_Color["Green"].." /gf|r to trigger report" );
end

function OnTooltipSetItem(tooltip, linkData)
	local itemName, itemLink = GameTooltip:GetItem(linkData)
	local gf_Score, gf_Stat, gf_Slot = GF_ItemScore(itemLink)

	local eq_Score = "Unequiped"
	local eq_Stat = 0
	local eq_Slot = 0
		
	local t_ItemLink = GetInventoryItemLink("player", gf_Slot);
	if (t_ItemLink ~= nil ) then
		eq_Score, eq_Stat, eq_Slot = GF_ItemScore(t_ItemLink)
	end
	local gf_iLevels, slotItemID,slotItemData = GF_Score()
	tooltip:AddDoubleLine("GearFit: "..string.format("%2.0f",gf_iLevels),gf_Score.." "..gf_Stat)
	
	-- add second line appropriate
	local gf_Equippable = IsEquippableItem(itemLink)
	if (gf_Equippable ~= nil) then
		if (t_ItemLink ~= nil) then
			local c_Name, c_Link, c_Rarity, c_iLevel, c_MinLevel, c_iType, C_SubType, c_Stack, c_Slot = GetItemInfo(t_ItemLink)
			tooltip:AddDoubleLine("GearFit: Yours: "..c_iLevel, eq_Score.." "..eq_Stat)
		end
	end
end
 
function OnTooltipCleared(tooltip, ...)
--   lineAdded = false
end


