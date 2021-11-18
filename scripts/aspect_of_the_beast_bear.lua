-- (c) Copyright Justin Freitas 2021+ except where explicitly stated otherwise.
-- Fantasy Grounds is Copyright (c) 2004-2021 SmiteWorks USA LLC.
-- Copyright to other material within this file may be held by other Individuals and/or Entities.
-- Nothing in or from this LUA file in printed, electronic and/or any other form may be used, copied,
-- transmitted or otherwise manipulated in ANY way without the explicit written consent of
-- Justin Freitas or, where applicable, any and all other Copyright holders.

function onInit()
	-- Because of the way that the inventory window works, the override will only be called on update to strength or traits (not features).
	CharManager.getEncumbranceMultAspectOfTheBeastBear = CharManager.getEncumbranceMult
	CharManager.getEncumbranceMult = getEncumbranceMultOverride

	-- Handlers to watch the feature list and call add/change handlers that update the character sheet inventory window if it happens to be open/loaded.
	DB.addHandler("charsheet.*.featurelist.*.name", "onAdd", onFeatureNameAdd)
	DB.addHandler("charsheet.*.featurelist.*.name", "onUpdate", onFeatureNameUpdate)
end

-- This is entered on strength change or trait change (not feature) due to the way record_char_inventory.xml works.
-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
function getEncumbranceMultOverride(nodeChar)
	local mult = CharManager.getEncumbranceMultAspectOfTheBeastBear(nodeChar)
	if not isBarbarianOfLevelSixOrHigher(nodeChar) then return mult end

	if hasAspectOfTheBeastBear(nodeChar) then
		mult = mult * 2
	end

	return mult
end

function hasAspectOfTheBeastBear(nodeChar)
	for _, nodeFeature in pairs(DB.getChildren(nodeChar, "featurelist")) do
		-- Allow for any number of spaces at each word and allow for either dash or colon separator.
		if string.match(DB.getValue(nodeFeature, "name", ""):lower(), "^%s*aspect%s+of%s+the%s+beast%s*[-:]%s*bear%s*$") then
			return true
		end
	end

	return false
end

function isBarbarianOfLevelSixOrHigher(nodeChar)
	for _, nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
		if DB.getValue(nodeClass, "name", ""):lower() == "barbarian" and DB.getValue(nodeClass, "level", 0) >= 6 then
			return true
		end
	end

	return false
end

function onFeatureNameAdd(nodeFeatureNameAdded)
	updateInventoryContents(nodeFeatureNameAdded)
end

function onFeatureNameUpdate(nodeFeatureNameUpdated)
	updateInventoryContents(nodeFeatureNameUpdated)
end

function updateInventoryContents(nodeFeatureName)
	if not nodeFeatureName then return end
	local nodeFeatureRecord = nodeFeatureName.getParent(); if not nodeFeatureRecord then return end
	local nodeFeatureList = nodeFeatureRecord.getParent(); if not nodeFeatureList then return end
	local nodeChar = nodeFeatureList.getParent(); if not nodeChar then return end

	-- Operate on barbarians of level 6 or higher only.
	if not isBarbarianOfLevelSixOrHigher(nodeChar) then return end

	-- If the character sheet has is open and the inventory tab has been visited, we'll need to update that view since it's not automatic by default.
	local wCharsheet = Interface.findWindow("charsheet", nodeChar)
	if not wCharsheet or not wCharsheet.inventory or not wCharsheet.inventory.subwindow
	   or not wCharsheet.inventory.subwindow.contents or not wCharsheet.inventory.subwindow.contents.subwindow
	   or not wCharsheet.inventory.subwindow.contents.subwindow.encumbrancebase then return end

	-- The condition has been met and we have to update the encumbrancebase value
	wCharsheet.inventory.subwindow.contents.subwindow.encumbrancebase.onTraitsUpdated()
end
