--[[--------------------------------------------------------------------
	Broker Instance Difficulty
	Shows the current instance difficulty on your DataBroker display.
	Copyright (c) 2014-2016 Phanx <addon@phanx.net>. All rights reserved.
	https://www.wowinterface.com/downloads/info22729-InstanceDifficulty
	https://www.curseforge.com/wow/addons/broker-instance-difficulty
	https://github.com/phanx-wow/Broker_InstanceDifficulty
----------------------------------------------------------------------]]

-- Change the "" to something else (eg. "None") if you want to see text
-- when you're not in a dungeon, raid, or scenario.
local DEFAULT_TEXT = ""

------------------------------------------------------------------------

local DIFFICULTY = "Difficulty"
local LFR, NORMAL, HEROIC, MYTHIC, CHALLENGE, TIMEWALK = "LFR", "N", "H", "M", "C", "TW"
if GetLocale() == "deDE" then
	DIFFICULTY = "Schwierigkeit"
	LFR, TIMEWALK = "SNS", "ZW"
elseif GetLocale():match("^es") then
	DIFFICULTY = "Dificultad"
	LFR, CHALLENGE, TIMEWALK = "BdB", "D", "PT"
elseif GetLocale() == "frFR" then
	DIFFICULTY = "Difficulté"
	LFR, FLEXIBLE, CHALLENGE, TIMEWALK = "RDR", "D", "D", "MT"
elseif GetLocale() == "itIT" then
	DIFFICULTY = "Difficoltà"
	LFR, HEROIC, CHALLENGE, TIMEWALK = "RDI", "E", "S", "VT"
elseif GetLocale() == "ptBR" then
	DIFFICULTY = "Dificuldade"
	LFR, CHALLENGE, TIMEWALK = "LdR", "D", "CT"
elseif GetLocale() == "ruRU" then
	DIFFICULTY = "Сложность"
	LFR, NORMAL, HEROIC, MYTHIC, CHALLENGE, TIMEWALK = "Пр", "О", "Г", "Э", "И", "ПВ"
elseif GetLocale() == "koKR" then
	DIFFICULTY = "난이도"
	LFR, NORMAL, HEROIC, MYTHIC, CHALLENGE, TIMEWALK = "공찾", "일반", "영웅", "신화", "도전", "시간여행" -- needs check
elseif GetLocale() == "zhCN" then
	DIFFICULTY = "难度"
	LFR, NORMAL, HEROIC, MYTHIC, CHALLENGE, TIMEWALK = "查找", "普通", "英雄", "史诗", "挑战", "时空漫游" -- needs check
elseif GetLocale() == "zhTW" then
	DIFFICULTY = "難度"
	LFR, NORMAL, HEROIC, MYTHIC, CHALLENGE, TIMEWALK = "搜尋", "普通", "英雄", "傳奇", "挑戰", "時光漫遊" -- needs check
end

------------------------------------------------------------------------

local isActive, isGuildGroup

local obj = LibStub("LibDataBroker-1.1"):NewDataObject("InstanceDifficulty", {
	type = "data source",
	icon = "Interface\\ICONS\\PVECurrency-Valor",
	label = DIFFICULTY,
	text = DEFAULT_TEXT,
	OnTooltipShow = function(tooltip)
		local instanceName, instanceType, _, difficultyName = GetInstanceInfo()

		local color
		if isGuildGroup then
			color = ChatTypeInfo["GUILD"]
		elseif instanceType == "scenario" then
			color = ChatTypeInfo["INSTANCE_CHAT"]
		else
			color = ChatTypeInfo[strupper(instanceType)] -- matches: party, raid | won't match: none, pvp, scenario
		end

		if color and difficultyName then
			tooltip:AddLine(instanceName, 1, 0.82, 0)
			tooltip:AddLine(difficultyName, 1, 1, 1)
			if isGuildGroup then
				tooltip:AddLine(GUILD, 1, 1, 1)
			end
		else
			tooltip:AddLine(DIFFICULTY, 1, 0.82, 0)
			tooltip:AddLine(NONE, 0.64, 0.64, 0.64)
		end
		tooltip:Show()
	end,
})

local difficultyText = {
	-- see http://wow.gamepedia.com/DifficultyID
	[2]  = HEROIC, -- Heroic Dungeon
	[5]  = HEROIC, -- 10 Player (Heroic)
	[6]  = HEROIC, -- 25 Player (Heroic)
	[7]  = LFR,
	[8]  = CHALLENGE,
	[11] = HEROIC, -- Heroic Scenario
	[15] = HEROIC,
	[16] = MYTHIC,
	[17] = LFR,
	[23] = MYTHIC, -- Mythic Dungeon
	[24] = TIMEWALK,
}

local hideCount = {
	[7]  = true, -- old LFR
	[14] = true, -- new Normal
	[15] = true, -- new Heroic
	[17] = true, -- new LFR
}

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GUILD_PARTY_STATE_UPDATED")
f:RegisterEvent("PARTY_MEMBER_DISABLE")
f:RegisterEvent("PARTY_MEMBER_ENABLE")
f:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
f:RegisterEvent("PLAYER_GUILD_UPDATE")
f:RegisterEvent("UPDATE_INSTANCE_INFO")
f:SetScript("OnEvent", function(self, event, ...)
	if event == "GUILD_PARTY_STATE_UPDATED" then
		isGuildGroup = ...
	elseif event ~= "UPDATE_INSTANCE_INFO" then
		RequestGuildPartyState()
	end

	local _, instanceType, difficulty, _, maxPlayers = GetInstanceInfo()

	if instanceType == "none" or difficulty == 0 or maxPlayers == 0
	or C_Garrison.IsOnGarrisonMap() or C_Garrison.IsOnShipyardMap() then
		obj.text = DEFAULT_TEXT
		return
	end

	local color
	if isGuildGroup then
		color = ChatTypeInfo["GUILD"]
	elseif instanceType == "pvp" then
		color = ChatTypeInfo["BG_SYSTEM_" .. strupper(UnitFactionGroup("player") or "NEUTRAL")]
	elseif instanceType == "scenario" then
		color = ChatTypeInfo["INSTANCE_CHAT"]
	else
		color = ChatTypeInfo[strupper(instanceType)] -- matches: party, raid | won't match: none, pvp, scenario
	end

	if instanceType == "pvp" then
		-- Battleground, don't show difficulty
		obj.text = format("|cff%02x%02x%02x%d|r", color.r * 255, color.g * 255, color.b * 255,
			maxPlayers)
	elseif hideCount[difficulty] then
		-- Flexible raid size, don't show max count
		obj.text = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255,
			difficultyText[difficulty] or NORMAL)
	else
		obj.text = format("|cff%02x%02x%02x%d%s|r", color.r * 255, color.g * 255, color.b * 255,
			maxPlayers,
			difficultyText[difficulty] or NORMAL)
	end
end)
