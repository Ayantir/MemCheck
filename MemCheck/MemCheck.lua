--[[
-------------------------------------------------------------------------------
-- MemCheck, by Ayantir
-------------------------------------------------------------------------------
This software is under : CreativeCommons CC BY-NC-SA 4.0
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)

You are free to:

    Share — copy and redistribute the material in any medium or format
    Adapt — remix, transform, and build upon the material
    The licensor cannot revoke these freedoms as long as you follow the license terms.


Under the following terms:

    Attribution — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
    NonCommercial — You may not use the material for commercial purposes.
    ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
    No additional restrictions — You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.


Please read full licence at : 
http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
]]

local ADDON_NAME = "MemCheck"
local refreshRate = 100
local nextDotIs = 400
local ordinate100 = 64
local anchorController = {}

local function RoundToDecimal(value, precision)
	local mult = 10^(precision or 0)
	return math.floor(value * mult + 0.5) / mult
end

local function RefreshMemCheck()
	
	local xShift = 10
	
	local memUsed = collectgarbage("count") / 1024
	local percUsed = memUsed / ordinate100 * 100
	local y = (200 - percUsed * 2)
	local value = RoundToDecimal(memUsed, 2)
	
	local actualValue = GetControl("MemCheckActualValue")
	actualValue:SetText(value .. " MB")
		
	for backupIndex=nextDotIs, 400 do
		if backupIndex == 400 then
			anchorController[backupIndex] = y
		else
			anchorController[backupIndex] = anchorController[backupIndex + 1]
		end
	end
	
	for dotIndex=400, nextDotIs, -1 do
		local x = xShift + dotIndex
		
		-- :GetAnchor() cannot be used, ClearAnchors + SetAnchor + GetAnchor too fast returns incorrect data.
		local control = GetControl("MemCheckDot"..dotIndex)
		control:SetHidden(false)
		control:ClearAnchors()
		control:SetAnchor(TOPLEFT, MemCheck, TOPLEFT, x, anchorController[dotIndex])
		control:SetAnchor(BOTTOMRIGHT, MemCheck, TOPLEFT, x, anchorController[dotIndex] + 1) -- +1 mandatory or control won't be drawned

	end
	
	nextDotIs = math.max(nextDotIs - 1, 1)
	
end

local function ConsiderArg(arg)

	local refreshRate = 100
	
	if arg and arg ~= "" then
		local desiredRefreshRate = tonumber(arg)
		if type(desiredRefreshRate) == "number" then
			if desiredRefreshRate >= 50 and desiredRefreshRate <= 60000 then
				refreshRate = desiredRefreshRate
			else
				refreshRate = 100
			end
		end
	end
	
	return refreshRate

end

local function ToggleMemCheck(arg)

	local _, memUsedExponent = math.frexp(collectgarbage("count") / 1024)
	local memUsedLimit = 2 ^ memUsedExponent
	
	ordinate100 = math.max(ordinate100, memUsedLimit)
	
	local ordinate80 = zo_round(ordinate100 * 0.8)
	local ordinate60 = zo_round(ordinate100 * 0.6)
	local ordinate40 = zo_round(ordinate100 * 0.4)
	local ordinate20 = zo_round(ordinate100 * 0.2)
	
	local abscissaLabel0 = GetControl("MemCheckAbscissaLabel0")
	local abscissaLabel20 = GetControl("MemCheckAbscissaLabel20")
	local abscissaLabel40 = GetControl("MemCheckAbscissaLabel40")
	local abscissaLabel60 = GetControl("MemCheckAbscissaLabel60")
	local abscissaLabel80 = GetControl("MemCheckAbscissaLabel80")
	local abscissaLabel100 = GetControl("MemCheckAbscissaLabel100")
	
	abscissaLabel0:SetText("0 MB")
	abscissaLabel20:SetText(ordinate20 .. " MB")
	abscissaLabel40:SetText(ordinate40 .. " MB")
	abscissaLabel60:SetText(ordinate60 .. " MB")
	abscissaLabel80:SetText(ordinate80 .. " MB")
	abscissaLabel100:SetText(ordinate100 .. " MB")
	
	local control = GetControl("MemCheck")
	
	if control:IsHidden() then
		refreshRate = ConsiderArg(arg)
		EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, refreshRate, RefreshMemCheck)
		control:SetHidden(false)
	elseif arg and arg ~= "" then
		refreshRate = ConsiderArg(arg)
		EVENT_MANAGER:UnregisterForUpdate(ADDON_NAME)
		EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, refreshRate, RefreshMemCheck)
		control:SetHidden(false)
	else
		nextDotIs = 400
		anchorController = {}
		lastDotDefined = false
		EVENT_MANAGER:UnregisterForUpdate(ADDON_NAME)
		control:SetHidden(true)
	end

end

local function InitializeMemCheck()
	
	for dotIndex=1, 400 do
		local dotControl = CreateControlFromVirtual("$(parent)Dot", MemCheck, "MemCheckDot", dotIndex)
	end
	
	SLASH_COMMANDS["/mem"] = ToggleMemCheck

end

local function OnAddonLoaded(_, addonName)

	if addonName == ADDON_NAME then
		InitializeMemCheck()
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
	end
	
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)