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

local LoadoutRandomizerInventory = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_inventory")


mod:hook_safe(CLASS.InventoryBackgroundView, "init", function (self, ...)
	self._invalid_randomizer_slots = {}
end)

local event_switch_mark_complete = function(self, item)
    self:_update_loadout_validation()
end

mod:hook_safe(CLASS.InventoryBackgroundView, "on_enter", function (self)
    self.event_switch_mark_complete = event_switch_mark_complete
	self:_register_event("event_switch_mark_complete", "event_switch_mark_complete")
end)

local _validate_loadout_modified = function (self, loadout, profile_preset, read_only)
	local invalid_slots = {}
	local modified_slots = {}
	local duplicated_slots = {}
	local only_show_slot_as_invalid = {}

	if not self._is_own_player or self._is_readonly then
		return invalid_slots, modified_slots, duplicated_slots
	end

	for slot_name, slot_data in pairs(ItemSlotSettings) do
		if not self:_valid_slot_for_archetype(slot_name) then
			-- Nothing
		else
			local item_data = loadout[slot_name]
			local gear_id = type(item_data) == "table" and item_data.gear_id
			local item = gear_id and self:_get_inventory_item_by_id(gear_id) or self:_get_inventory_item_by_id(item_data)
			local fallback_item = MasterItems.find_fallback_item(slot_name)

			if not item and (type(item_data) ~= "table" or not item_data.always_owned) then
				invalid_slots[slot_name] = true
			elseif item and not item.always_owned and fallback_item and item.name == fallback_item.name then
				invalid_slots[slot_name] = true
			else
				for checked_slot_name, checked_load_data in pairs(loadout) do
					local checked_gear_id = type(checked_load_data) == "table" and checked_load_data.gear_id or type(checked_load_data) == "string" and checked_load_data
					local item_gear_id = type(item_data) == "table" and item_data.gear_id or type(item_data) == "string" and item_data

					if checked_gear_id == item_gear_id and checked_slot_name ~= slot_name and not invalid_slots[slot_name] and (not ALLOWED_DUPLICATE_SLOTS[checked_slot_name] or not ALLOWED_DUPLICATE_SLOTS[slot_name]) then
						duplicated_slots[checked_slot_name] = true

						goto label_1_0
					end
				end

				local player = self._preview_player
				local profile = player:profile()
                
				local item_or_nil = type(item_data) == "table" and self:_get_inventory_item_by_id(gear_id) or self:_get_inventory_item_by_id(item_data)

				if item_or_nil then
					local compatible_profile = Items.is_item_compatible_with_profile(item_or_nil, profile)

					if not compatible_profile then
						only_show_slot_as_invalid[slot_name] = true
						invalid_slots[slot_name] = true
					end

                    if mod.randomizer_data then
                        local randomizer_profile = LoadoutRandomizerInventory.get_randomizer_profile()
                        local randomizer_weapon = slot_name == "slot_primary" and mod.randomizer_data.weapons.melee.item or mod.randomizer_data.weapons.ranged.item

                        if profile_preset.id == randomizer_profile.id and (slot_name == "slot_primary" or slot_name == "slot_secondary") then
                            local is_slot_randomizer_valid = item.__master_item.weapon_template == randomizer_weapon.weapon_template

                            if not is_slot_randomizer_valid then
                                only_show_slot_as_invalid[slot_name] = true
						        invalid_slots[slot_name] = true
                            end
                        end
                    end
				end
			end
		end

		::label_1_0::
	end

	for removed_slot_name, _ in pairs(invalid_slots) do
		if not only_show_slot_as_invalid[removed_slot_name] then
			local starting_item = self._starting_profile_equipped_items and self._starting_profile_equipped_items[removed_slot_name]
			local valid_stored_item = self._valid_profile_equipped_items and self._valid_profile_equipped_items[removed_slot_name]

			starting_item = starting_item and self:_get_inventory_item_by_id(starting_item.gear_id)
			valid_stored_item = valid_stored_item and self:_get_inventory_item_by_id(valid_stored_item.gear_id)

			local fallback_item = MasterItems.find_fallback_item(removed_slot_name)
			local starting_item_valid = starting_item and (starting_item.always_owned or fallback_item and fallback_item.name ~= starting_item.name)
			local valid_stored_item_valid = valid_stored_item and (valid_stored_item.always_owned or fallback_item and fallback_item.name ~= valid_stored_item.name)

			if not read_only then
				if starting_item_valid then
					self:_equip_slot_item(removed_slot_name, starting_item, true)
				elseif valid_stored_item_valid then
					self:_equip_slot_item(removed_slot_name, valid_stored_item, true)
				end
			end

			if starting_item_valid or valid_stored_item_valid then
				invalid_slots[removed_slot_name] = nil
				modified_slots[removed_slot_name] = true
			elseif fallback_item then
				if not read_only then
					self:_equip_slot_item(removed_slot_name, fallback_item, true)
				end

				if fallback_item.always_owned then
					invalid_slots[removed_slot_name] = nil
					modified_slots[removed_slot_name] = true
				end
			else
				if ALLOWED_EMPTY_SLOTS[removed_slot_name] then
					invalid_slots[removed_slot_name] = nil
					modified_slots[removed_slot_name] = nil
				end

				if not read_only then
					self:_equip_slot_item(removed_slot_name, nil, true)
				end
			end
		end
	end

	if not read_only then
		self._invalid_slots = invalid_slots
		self._modified_slots = modified_slots
		self._duplicated_slots = duplicated_slots
	end

	return invalid_slots, modified_slots, duplicated_slots
end

mod:hook_safe(CLASS.InventoryBackgroundView, "_update_missing_warning_marker", function (self)
	local presets = ProfileUtils.get_profile_presets()
	local active_profile_preset_id = ProfileUtils.get_active_profile_preset_id()

	if not presets or #presets == 0 or not active_profile_preset_id then
		local loadout = self._current_profile_equipped_items
		local invalid_slots, modified_slots, duplicated_slots = self:_validate_loadout(loadout, true)

		self._invalid_slots = table.merge(table.merge({}, invalid_slots), duplicated_slots)
		self._modified_slots = modified_slots

		local player = self._preview_player
		local profile = player:profile()

		self._invalid_talents = self._current_profile_equipped_talents and not TalentLayoutParser.is_talent_selection_valid(profile, "talent_layout_file_path", self._current_profile_equipped_talents) or false

		if self._profile_presets_element then
			local show_warning = not table.is_empty(self._invalid_slots) or not table.is_empty(self._duplicated_slots) or self._invalid_talents
			local show_modified = not table.is_empty(self._modified_slots) or self._modified_talents

			self._profile_presets_element:set_current_profile_loadout_status(show_warning, show_modified)
		end
	end

	if presets then
		local player = self._preview_player
		local profile = player:profile()
		local active_talent_version = TalentLayoutParser.talents_version(profile)

		for i = 1, #presets do
			local preset = presets[i]
			local loadout = preset and preset.loadout

			if loadout then
				local active_preset = preset.id == active_profile_preset_id
				local is_read_only = not active_preset
				local invalid_slots, modified_slots, duplicated_slots = _validate_loadout_modified(self, loadout, preset, is_read_only)
				local show_warning = not table.is_empty(invalid_slots) or not table.is_empty(duplicated_slots)
				local show_modified = not table.is_empty(modified_slots)
				local invalid_talents = false
				local modified_talents = false
				local preset_talents_version = preset.talents_version

				if not preset_talents_version or not TalentLayoutParser.is_same_version(active_talent_version, preset_talents_version) then
					show_modified = true
					modified_talents = true
				end

				if not TalentLayoutParser.is_talent_selection_valid(profile, "talent_layout_file_path", preset.talents) then
					invalid_talents = true
					show_warning = true
				end

				self._profile_presets_element:show_profile_preset_missing_items_warning(show_warning, show_modified, preset.id)

				if active_preset then
					self._invalid_slots = table.merge(table.merge({}, invalid_slots), duplicated_slots)
					self._modified_slots = modified_slots
					self._invalid_talents = invalid_talents
					self._modified_talents = modified_talents

					self._profile_presets_element:set_current_profile_loadout_status(show_warning, show_modified)
				end
			end
		end
	end
end)

mod:hook_safe(CLASS.InventoryBackgroundView, "event_switch_mark", function (self, gear_id, mark_id, item)
	local active_profile_preset_id = ProfileUtils.get_active_profile_preset_id()
    local randomizer_profile = LoadoutRandomizerInventory.get_randomizer_profile()

    if active_profile_preset_id == randomizer_profile.id then
        self:_update_missing_warning_marker()
    end
end)