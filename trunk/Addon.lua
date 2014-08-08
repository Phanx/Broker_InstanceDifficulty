--[[--------------------------------------------------------------------
	Broker Instance Difficulty
	Shows the current instance difficulty on your DataBroker display.
	Copyright 2014 Phanx <addons@phanx.net>. All rights reserved.
	See the accompanying README and LICENSE files for more information.
	http://www.wowinterface.com/downloads/info22729-InstanceDifficulty
	http://www.curse.com/addons/wow/broker-instancedifficulty
----------------------------------------------------------------------]]

-- Change the "" to something else (eg. "None") if you want to see text
-- when you're not in a dungeon, raid, or scenario.
local DEFAULT_TEXT = ""

------------------------------------------------------------------------

local DIFFICULTY = "Difficulty"
local LFR, FLEXIBLE, NORMAL, HEROIC, CHALLENGE = "LFR", "FLEX", "N", "H", "C"
if GetLocale() == "deDE" then
	DIFFICULTY = "Schwierigkeit"
	LFR = "SNS"
elseif GetLocale():match("^es") then
	DIFFICULTY = "Dificultad"
	LFR, CHALLENGE = "BdB", "D"
elseif GetLocale() == "frFR" then
	DIFFICULTY = "Difficulté"
	LFR, FLEXIBLE, CHALLENGE = "RDR", "DYN", "D"
elseif GetLocale() == "itIT" then
	DIFFICULTY = "Difficoltà"
	LFR, FLEXIBLE, HEROIC, CHALLENGE = "RDI", "DIN", "E", "S"
elseif GetLocale() == "ptBR" then
	DIFFICULTY = "Dificuldade"
	LFR, CHALLENGE = "PR", "D"
elseif GetLocale() == "ruRU" then
	DIFFICULTY = "Сложность"
	LFR, FLEXIBLE, NORMAL, HEROIC, CHALLENGE = "ир", "Гбк", "Н", "Г", "И"
elseif GetLocale() == "koKR" then
	DIFFICULTY = "난이도"
	LFR, FLEXIBLE, NORMAL, HEROIC, CHALLENGE = "공찾", "탄력적", "표준", "영웅", "도전" -- needs check
elseif GetLocale() == "zhCN" then
	DIFFICULTY = "难度"
	LFR, FLEXIBLE, NORMAL, HEROIC, CHALLENGE = "查找", "弹缩", "正常", "英勇", "挑战" -- needs check
elseif GetLocale() == "zhTW" then
	DIFFICULTY = "難度"
	LFR, FLEXIBLE, NORMAL, HEROIC, CHALLENGE = "搜尋", "彈性", "普通", "英雄", "挑戰" -- needs check
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
	local _, _, isHeroic, isChallengeMode = GetDifficultyInfo(difficulty)

	local color
	if isGuildGroup then
		color = ChatTypeInfo["GUILD"]
	elseif instanceType == "scenario" then
		color = ChatTypeInfo["INSTANCE_CHAT"]
	else
		color = ChatTypeInfo[strupper(instanceType)] -- matches: party, raid | won't match: none, pvp, scenario
	end

	if color and maxPlayers > 0 then
		if difficulty == 7 then -- LFR
			obj.text = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, LFR)
		elseif difficulty == 14 then -- Flex
			obj.text = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, FLEXIBLE)
		else
			obj.text = format("|cff%02x%02x%02x%s%d|r", color.r * 255, color.g * 255, color.b * 255,
				isChallengeMode and CHALLENGE or isHeroic and HEROIC or NORMAL, maxPlayers)
		end
	else
		obj.text = DEFAULT_TEXT
	end
end)