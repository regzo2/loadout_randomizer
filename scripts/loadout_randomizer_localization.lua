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
    sett_keystoneless_chance_id = {
        en = "Chance for Keystoneless",
    },
}

local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")
local WeaponTemplates = require("scripts/settings/equipment/weapon_templates/weapon_templates")

local patterns = UISettings.weapon_patterns

for pattern_name, pattern in pairs(patterns) do
    localizations["pattern_".. pattern_name .. "_group_id"] = {}
    localizations["pattern_".. pattern_name .. "_group_id"]["en"] = Localize(pattern.display_name)
    for _, mark in pairs(pattern.marks) do
        if WeaponTemplates[mark.name] then
            local loc = Localize(string.format("loc_weapon_pattern_%s", mark.name)) .. " " .. Localize(string.format("loc_weapon_mark_%s", mark.name)) .. " " .. Localize(string.format("loc_weapon_family_%s", mark.name))
            localizations["weapon_".. mark.name .. "_weight_id"] = {}
            localizations["weapon_".. mark.name .. "_weight_id"]["en"] = loc
        end
    end
end

return localizations