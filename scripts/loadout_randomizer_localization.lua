local localizations = {
    mod_name = {
        en = "Loadout Randomizer",
    },
    mod_description = {
        en = "Randomizes loadouts.",       
    },
    weapon_group_id = {
        en = "Weapon Settings",       
    },
    weapon_weight_group_id = {
        en = "Weapon Weights",       
    },
    view_randomize_loadout_id = {
        en = "Open Loadout Randomizer View",       
    },
    view_randomize_loadout_tip_id = {
        en = "Opens the Loadout Randomizer view. \n\n Can also be accessed with the following chat commands: \n\n/rl \n/randomize_loadout",       
    },
    generate_loadout_cmd_description_id = {
        en = "Suggests a randomized loadout.",       
    },
    sett_weapon_display_format_id = {
        en = "Weapon Display Format",
    },
    weapon_mark_family_id = {
        en = "Mark and Family Only",
    },
    weapon_pattern_mark_family_id = {
        en = "Pattern, Mark, and Family",
    },
    sett_weapon_chance_id = {
        en = "Display Chance",
    },
    sett_randomize_weapons_id = {
        en = "Enable Weapon Randomization",
    },
    talent_group_id = {
        en = "Talent Settings",
    },
    sett_talent_tree_select_fill_nodes_id = {
        en = "Path Between Talent Tree Nodes",
    },
    sett_talent_tree_select_enabled_id = {
        en = "Automatically Select Talent Tree Nodes",
    },
    archetype_generic_group_id = {
        en = "      Operative Modifiers",
    },
    talent_weight_group_id = {
        en = "Talent Weights",
    },
    sett_randomize_talent_ability_id = {
        en = "Randomize Ability",
    },
    sett_randomize_talent_blitz_id = {
        en = "Randomize Blitz",
    },
    sett_randomize_talent_keystone_id = {
        en = "Randomize Keystone(s)",
    },
    sett_randomize_talent_aura_id = {
        en = "Randomize Aura",
    },
    loc_talent_enabled_id = {
        en = "Enabled",
    },
    loc_talent_group_weight_id = {
        en = "Group Weight",
    },
    loc_talent_unroll_chance_id = {
        en = "Unroll Chance",
    },
    loc_talent_freeroll_chance_id = {
        en = "Free Roll Chance",
    },
    loc_talent_order_id = {
        en = "Order",
    },
    loc_talent_max_group_rolls_id = {
        en = "Max Rolls",
    },
    loc_talent_ability_unrolled = {
        en = "Ability Unrolled!",
    },
    cosmetic_group_id = {
        en = "Cosmetic Settings",
    },
}

local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")
local WeaponTemplates = require("scripts/settings/equipment/weapon_templates/weapon_templates")
local Archetypes = require("scripts/settings/archetype/archetypes")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local talent_category_settings = TalentBuilderViewSettings.settings_by_node_type

local patterns = UISettings.weapon_patterns

local localization = Managers.localization and Managers.localization:language()

for pattern_name, pattern in pairs(patterns) do
    localizations["pattern_".. pattern_name .. "_group_id"] = {}
    localizations["pattern_".. pattern_name .. "_group_id"][localization] = "       " .. Localize(pattern.display_name)
    for _, mark in pairs(pattern.marks) do
        if WeaponTemplates[mark.name] then
            local loc = Localize(string.format("loc_weapon_pattern_%s", mark.name)) .. " " .. Localize(string.format("loc_weapon_mark_%s", mark.name)) .. " " .. Localize(string.format("loc_weapon_family_%s", mark.name))
            localizations["weapon_".. mark.name .. "_weight_id"] = {}
            localizations["weapon_".. mark.name .. "_weight_id"][localization] = loc
        end
    end
end

local map_talent_tree_to_data = function(archetype)
	local all_talent_data = archetype.talents
	local talent_tree_path = string.format("scripts/ui/views/talent_builder_view/layouts/%s_tree", archetype.name)
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

	local talents = {}

	for key, node in pairs(tree.nodes) do
		if node.type ~= "start" and all_talent_data[node.talent] then
			if not talents[node.type] then
				talents[node.type] = {}
			end

			talents[node.type][node.talent] = {}
			talents[node.type][node.talent].display_name = all_talent_data[node.talent].display_name
			talents[node.type][node.talent].icon = node.icon
			talents[node.type][node.talent].requirements = node.requirements
		end
	end

    return talents
end

for _, archetype in pairs(Archetypes) do
    local categories = map_talent_tree_to_data(archetype)

    for category_id, category in pairs(categories) do
        localizations["archetype_".. archetype.name .. "_talent_" .. category_id .. "_group_id"] = {}
        localizations["archetype_".. archetype.name .. "_talent_" .. category_id .. "_group_id"][localization] = "      " .. Localize(talent_category_settings[category_id].display_name)
        for talent_id, talent in pairs(category) do
            localizations["talent_".. talent_id .. "_weight_id"] = {}
            localizations["talent_".. talent_id .. "_weight_id"][localization] = Localize(talent.display_name)
        end
    end

    localizations["archetype_".. archetype.name .. "_group_id"] = {}
    localizations["archetype_".. archetype.name .. "_group_id"][localization] = Localize(archetype.archetype_name)
end

for node_id, node in pairs(talent_category_settings) do
    localizations["talent_" .. node_id .. "_group_id"] = {}
    localizations["talent_" .. node_id .. "_group_id"][localization] = "        " .. Localize(node.display_name)
end

for slot_name, slot in pairs(ItemSlotSettings) do
    if slot.equipped_in_inventory then
        localizations["sett_".. slot_name .. "_enabled_id"] = {}
        localizations["sett_".. slot_name .. "_enabled_id"][localization] = "       " .. Localize(slot.display_name)
    end
end

return localizations