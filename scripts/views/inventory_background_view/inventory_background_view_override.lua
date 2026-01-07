local mod = get_mod("loadout_randomizer")

local Breeds = require("scripts/settings/breed/breeds")
local Definitions = require("scripts/ui/views/inventory_background_view/inventory_background_view_definitions")
local InventoryBackgroundViewSettings = require("scripts/ui/views/inventory_background_view/inventory_background_view_settings")
local Items = require("scripts/utilities/items")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local MasterItems = require("scripts/backend/master_items")
local Mastery = require("scripts/utilities/mastery")
local PlayerProgressionUnlocks = require("scripts/settings/player/player_progression_unlocks")
local ProfileUtils = require("scripts/utilities/profile_utils")
local Promise = require("scripts/foundation/utilities/promise")
local ScriptCamera = require("scripts/foundation/utilities/script_camera")
local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")
local UICharacterProfilePackageLoader = require("scripts/managers/ui/ui_character_profile_package_loader")
local UIProfileSpawner = require("scripts/managers/ui/ui_profile_spawner")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")
local UISettings = require("scripts/settings/ui/ui_settings")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIWeaponSpawner = require("scripts/managers/ui/ui_weapon_spawner")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWorldSpawner = require("scripts/managers/ui/ui_world_spawner")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local ViewElementMenuPanel = require("scripts/ui/view_elements/view_element_menu_panel/view_element_menu_panel")
local ViewElementProfilePresets = require("scripts/ui/view_elements/view_element_profile_presets/view_element_profile_presets")
local Views = require("scripts/ui/views/views")
local ITEM_TYPES = UISettings.ITEM_TYPES
local ALLOWED_DUPLICATE_SLOTS = InventoryBackgroundViewSettings.allowed_duplicate_slots
local ALLOWED_EMPTY_SLOTS = InventoryBackgroundViewSettings.allowed_empty_slots
local IGNORED_SLOTS = InventoryBackgroundViewSettings.ignored_validation_slots


mod:hook_safe(CLASS.InventoryBackgroundView, "init", function (self, ...)
	self._invalid_randomizer_slots = {}
end)

--[[

mod:hook_safe(CLASS.InventoryBackgroundView, "_update_missing_warning_marker", function (self)
    if not mod.randomizer_data then return end

    local slots_invalid

    for _, slots in pairs(self._invalid_randomizer_slots) do
        slots_invalid = true
    end

    if slots_invalid then
        mod:echo("nuke the profile")
        local show_warning = true
        local show_modified = false

        local active_preset == ProfileUtils.get_active_profile_preset_id() == mod.randomizer_profile_ids[archetype_name]

        self._profile_presets_element:show_profile_preset_missing_items_warning(show_warning, show_modified, mod.randomizer_profile_ids[archetype_name])

        local active_preset == ProfileUtils.get_active_profile_preset_id() == mod.randomizer_profile_ids[archetype_name]

        mod:echo("fuh")

        if active_preset then
            mod:echo("yuh")
            self._profile_presets_element:set_current_profile_loadout_status(show_warning, show_modified)
        end
    end
end)

]]

mod:hook_safe(CLASS.InventoryBackgroundView,"event_on_profile_preset_changed", function (self, profile_preset, on_preset_deleted)
    if not mod.randomizer_data then return end

	local player = self._preview_player
	local profile = player:profile()
    local archetype_name = player:archetype_name()
	local active_talents_version = TalentLayoutParser.talents_version(profile)

    local is_randomizer_profile = profile_preset and profile_preset.is_randomizer_profile

    local inventory_updated = false

    --mod:echo("rando: " .. (is_randomizer_profile and "ya" or "no") .. " " .. (profile_preset and profile_preset.id or "no id") .. " : " .. (mod.randomizer_profile_ids[archetype_name] or "no id"))

    -- randomizer weapon/curio restrictions
	if profile_preset and profile_preset.loadout and is_randomizer_profile then
        mod:echo("randomizer_profile changed")

        for slot_name, gear_id in pairs(profile_preset.loadout) do
            if slot_name == "slot_primary" or slot_name == "slot_secondary" then
                local item = self:_get_inventory_item_by_id(gear_id)

                local randomizer_weapon_data = slot_name == "slot_primary" and mod.randomizer_data.weapons.melee.item or mod.randomizer_data.weapons.ranged.item

                local profile_item_template = item.__master_item.weapon_template
                local randomizer_item_template = randomizer_weapon_data.weapon_template
                
                local is_slot_randomizer_valid = profile_item_template == randomizer_item_template

                if not is_slot_randomizer_valid then
                    mod:echo("invalid for rando:" .. slot_name)
                    self._invalid_randomizer_slots[slot_name] = true
                end
            end
        end
    end

    if inventory_updated == true then
        self._profile_presets_element:sync_profiles_states()
    end

	--self:_update_missing_warning_marker()
    --self:_update_loadout_validation()
end)