local getEncumbranceMult_orig
local bBearFromFGU

function onInit()
	local featureNamePath = "charsheet.*.featurelist.*.name"
	DB.addHandler(featureNamePath, "onAdd", onFeatureNameAddOrUpdate)
	DB.addHandler(featureNamePath, "onUpdate", onFeatureNameAddOrUpdate)
	bBearFromFGU = checkBearFromFGU()

	if bBearFromFGU then
		getEncumbranceMult_orig = CharEncumbranceManager5E.getEncumbranceMult
		CharEncumbranceManager5E.getEncumbranceMult = getEncumbranceMultOverride
	else
		getEncumbranceMult_orig = CharManager.getEncumbranceMult
		CharManager.getEncumbranceMult = getEncumbranceMultOverride
	end
end

function checkBearFromFGU()
	local nMajor, nMinor, nPatch = Interface.getVersion()
	if nMajor >= 5 then return true end
	if nMajor == 4 and nMinor >= 2 then return true end
	return nMajor == 4 and nMinor == 1 and nPatch >= 14
end

-- This is entered on strength change or trait change (not feature)
-- due to the way record_char_inventory.xml works.
-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
function getEncumbranceMultOverride(nodeChar)
	local mult = getEncumbranceMult_orig(nodeChar)
	if isBarbarianOfLevelSixOrHigher(nodeChar) and
	   hasQualifyingBearFeature(nodeChar) then
		mult = mult * 2
	end

	return mult
end

function hasQualifyingBearFeature(nodeChar)
	local bBear, bBeastBear
	for _,nodeFeature in pairs(DB.getChildren(nodeChar, "featurelist")) do
		local name = DB.getValue(nodeFeature, "name", ""):lower()
		if string.match(name, "^%W*aspect%W+of%W+the%W+beast%W*bear%W*$") then
			bBeastBear = true;
		elseif string.match(name, "^%W*aspect%W+of%W+the%W+bear%W*$") then
			bBear = true;
		end
	end

	return (bBear and not bBearFromFGU) or
		   (bBeastBear and not bBearFromFGU) or
		   (bBeastBear and not bBear and bBearFromFGU)
end

function isBarbarianOfLevelSixOrHigher(nodeChar)
	for _,nodeClass in pairs(DB.getChildren(nodeChar, "classes")) do
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

	if bBearFromFGU then
		CharEncumbranceManager5E.updateEncumbranceLimit(nodeChar)
	else
		local windowCharsheet = Interface.findWindow("charsheet", nodeChar)
		updateInventoryPaneEncumbranceBaseIfLoaded(windowCharsheet)
	end
end

function updateInventoryPaneEncumbranceBaseIfLoaded(w)
	if not (w and w.inventory
			  and w.inventory.subwindow
			  and w.inventory.subwindow.contents
			  and w.inventory.subwindow.contents.subwindow
			  and w.inventory.subwindow.contents.subwindow.encumbrancebase
			  and w.inventory.subwindow.contents.subwindow.encumbrancebase.onTraitsUpdated) then
		return
	end

	-- See: <number_linked name="encumbrancebase" source="encumbrance.encumbered">
	w.inventory.subwindow.contents.subwindow.encumbrancebase.onTraitsUpdated()
end
