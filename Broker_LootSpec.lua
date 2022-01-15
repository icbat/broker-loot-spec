-------------------
--- Data structures
-------------------
local id_to_name_cache = {}

local function initialize_cache()
    if next(id_to_name_cache) ~= nil then
        return
    end
    -- needs to be run after player has finished entering the world, else there will be nils
    for index = 1, GetNumSpecializations() + 1, 1 do
        local id, name = GetSpecializationInfo(index)
        id_to_name_cache[id] = name
    end
end

-------------
--- View Code
-------------

local function add_line(self, spec_id, text)
    local prefix = ""

    if spec_id == GetLootSpecialization() then
        prefix = ">"
    end

    local line = self:AddLine(prefix, text)

    if spec_id ~= GetLootSpecialization() then
        local callback = function()
            self:Clear()
            SetLootSpecialization(spec_id)
        end
        self:SetLineScript(line, "OnMouseUp", callback)
    end
end

local function build_tooltip(self)
    -- col 1 is for highlighting what you're currently queued for
    -- col 2 is general text

    self:AddHeader("", "Select a Loot Specialization")
    self:AddSeparator()

    local current_spec_index = GetSpecialization()
    local _id, current_spec_name = GetSpecializationInfo(current_spec_index)

    for spec_id, spec_name in pairs(id_to_name_cache) do
        add_line(self, spec_id, spec_name)
    end
    add_line(self, 0, "Current Specialization")

    -- make the indicators green
    self:SetColumnTextColor(1, 0, 1, 0, 1)
end

--------------------
--- Wiring/LDB/QTip
--------------------

local ADDON, namespace = ...
local LibQTip = LibStub('LibQTip-1.0')
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject(ADDON, {
    type = "data source",
    text = "-"
})

local function OnRelease(self)
    LibQTip:Release(self.tooltip)
    self.tooltip = nil
end

local function anchor_OnEnter(self)
    if self.tooltip then
        LibQTip:Release(self.tooltip)
        self.tooltip = nil
    end

    local tooltip = LibQTip:Acquire(ADDON, 2, "LEFT", "LEFT")
    self.tooltip = tooltip
    tooltip.OnRelease = OnRelease
    tooltip.OnLeave = OnLeave
    tooltip:SetAutoHideDelay(.1, self)

    build_tooltip(tooltip)

    tooltip:SmartAnchorTo(self)

    tooltip:Show()
end

function dataobj:OnEnter()
    anchor_OnEnter(self)
end

--- Nothing to do. Needs to be defined for some display addons apparently
function dataobj:OnLeave()
end

local function set_label(self)
    initialize_cache()
    local current_loot_spec = GetLootSpecialization()
    if current_loot_spec == 0 then
        local current_spec_index = GetSpecialization()
        local _id, current_spec_name, _desc, icon = GetSpecializationInfo(current_spec_index)
        dataobj.text = "Current Specialization (" .. current_spec_name .. ")"
        dataobj.icon = icon
    else
        dataobj.text = "" .. id_to_name_cache[current_loot_spec]
        local _id, _name, _desc, icon = GetSpecializationInfoByID(current_loot_spec)
        dataobj.icon = icon
    end

end

-- invisible frame for updating/hooking events
local f = CreateFrame("frame")

f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
f:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
-- on login
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", set_label)
