local getEncumbranceMult_orig

function onInit()
	getEncumbranceMult_orig = CharManager.getEncumbranceMult
	CharManager.getEncumbranceMult = getEncumbranceMultOverride

	local featureNamePath = "charsheet.*.featurelist.*.name"
	DB.addHandler(featureNamePath, "onAdd", onFeatureNameAddOrUpdate)
	DB.addHandler(featureNamePath, "onUpdate", onFeatureNameAddOrUpdate)
end

-- This is entered on strength change or trait change (not feature)
-- due to the way record_char_inventory.xml works.
-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
function getEncumbranceMultOverride(nodeChar)
	local mult = getEncumbranceMult_orig(nodeChar)
	if isBarbarianOfLevelSixOrHigher(nodeChar) and
	   hasAspectOfTheBeastBear(nodeChar) then
		mult = mult * 2
	end

	return mult
end

function hasAspectOfTheBeastBear(nodeChar)
	for _, nodeFeature in pairs(DB.getChildren(nodeChar, "featurelist")) do
		local name = DB.getValue(nodeFeature, "name", ""):lower()
		if string.match(name, "^%W*aspect%W+of%W+the%W+beast%W*bear%W*$") then
			return true
		end
	end

	return false
end

function isBarbarianOfLevelSixOrHigher(nodeChar)
	for _, nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
		if DB.getValue(nodeClass, "name", ""):lower() == "barbarian" and
		   DB.getValue(nodeClass, "level", 0) >= 6 then
			return true
		end
	end

	return false
end

function onFeatureNameAddOrUpdate(nodeFeatureName)
	-- Node hierarchy to character sheet: charsheet.featurelist.feature.name
	local nodeChar = nodeFeatureName.getParent().getParent().getParent()
	if not isBarbarianOfLevelSixOrHigher(nodeChar) then return end

	local windowCharsheet = Interface.findWindow("charsheet", nodeChar)
	updateInventoryPaneEncumbranceBaseIfLoaded(windowCharsheet)
end

function updateInventoryPaneEncumbranceBaseIfLoaded(w)
	if not (w and w.inventory
			  and w.inventory.subwindow
			  and w.inventory.subwindow.contents
			  and w.inventory.subwindow.contents.subwindow
			  and w.inventory.subwindow.contents.subwindow.encumbrancebase
			  and w.inventory.subwindow.contents.subwindow.encumbrancebase.onTraitsUpdated) then return end

	-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
	w.inventory.subwindow.contents.subwindow.encumbrancebase.onTraitsUpdated()
end
