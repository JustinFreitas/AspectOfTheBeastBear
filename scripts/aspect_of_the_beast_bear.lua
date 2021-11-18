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
	local featureNamePath = "charsheet.*.featurelist.*.name"
	DB.addHandler(featureNamePath, "onAdd", onFeatureNameAddOrUpdate)
	DB.addHandler(featureNamePath, "onUpdate", onFeatureNameAddOrUpdate)
end

-- This is entered on strength change or trait change (not feature) due to the way record_char_inventory.xml works.
-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
function getEncumbranceMultOverride(nodeChar)
	local mult = CharManager.getEncumbranceMultAspectOfTheBeastBear(nodeChar)
	if isBarbarianOfLevelSixOrHigher(nodeChar) and
	   hasAspectOfTheBeastBear(nodeChar) then
		mult = mult * 2
	end

	return mult
end

function hasAspectOfTheBeastBear(nodeChar)
	for _, nodeFeature in pairs(DB.getChildren(nodeChar, "featurelist")) do
		-- Allow for any number of spaces at each word and any non-alphanumeric separator zero or more times.
		if string.match(DB.getValue(nodeFeature, "name", ""):lower(), "^%s*aspect%s+of%s+the%s+beast%W*bear%W*$") then
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

function onFeatureNameAddOrUpdate(nodeFeatureName)
	local nodeChar = nodeFeatureName.getParent().getParent().getParent()
	-- Operate on barbarians of level 6 or higher only.
	if not isBarbarianOfLevelSixOrHigher(nodeChar) then return end

	-- If the character sheet has is open and the inventory tab has been visited, we'll need to update that view since it's not automatic by default.
	local windowCharsheet = Interface.findWindow("charsheet", nodeChar)
	return updateInventoryPaneEncumbranceBaseIfLoaded(windowCharsheet)
end

function updateInventoryPaneEncumbranceBaseIfLoaded(w)
	if not (w and w.inventory and w.inventory.subwindow and w.inventory.subwindow.contents and w.inventory.subwindow.contents.subwindow
			and w.inventory.subwindow.contents.subwindow.encumbrancebase) then return end

	-- The inventory tab is loaded, update the encumbrancebase value.
	-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
	w.inventory.subwindow.contents.subwindow.encumbrancebase.onTraitsUpdated()
end
