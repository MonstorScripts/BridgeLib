---@type table?
local saved = nil

---skinchanger reads and writes the whole skin table, so the snapshot is taken before the first
---uniform goes on and loaded back verbatim.
---@return table?
local function currentSkin()
	local skin
	TriggerEvent("skinchanger:getSkin", function(current)
		skin = current
	end)
	return skin
end

---@type BridgeLib.Clothing.Client
local provider = {
	SetUniform = function(uniform)
		saved = saved or currentSkin()
		TriggerEvent("skinchanger:loadClothes", saved, uniform)
	end,

	RevertUniform = function()
		if not saved then
			return
		end

		TriggerEvent("skinchanger:loadSkin", saved)
		saved = nil
	end,
}

return provider
