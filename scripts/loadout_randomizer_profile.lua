local mod = get_mod("loadout_randomizer")

local InventoryBackgroundViewSettings = require("scripts/ui/views/inventory_background_view/inventory_background_view_settings")
local Items = require("scripts/utilities/items")
local ItemSlotSettings = require("scripts/settings/item/item_slot_settings")
local Promise = require("scripts/foundation/utilities/promise")
local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")
local ALLOWED_DUPLICATE_SLOTS = InventoryBackgroundViewSettings.allowed_duplicate_slots
local ALLOWED_EMPTY_SLOTS = InventoryBackgroundViewSettings.allowed_empty_slots
local IGNORED_SLOTS = InventoryBackgroundViewSettings.ignored_validation_slots

local LoadoutRandomizerInventory    = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_inventory")
local LoadoutRandomizerProfileUtils = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")

LoadoutRandomizerProfile = {}

local _valid_slot_for_archetype = function(slot_name, archetype_name)
	if not ItemSlotSettings[slot_name] then
		return false
	end

	if IGNORED_SLOTS[slot_name] then
		return false
	end

	if not ItemSlotSettings[slot_name].equipped_in_inventory then
		return false
	end

	if not ItemSlotSettings[slot_name].archetype_restrictions then
		return true
	end

	return not not table.find(ItemSlotSettings[slot_name].archetype_restrictions, archetype_name)
end

local _get_inventory_item_by_id = function(gear_id, inventory_items)
	if not gear_id then
		return
	end

	for _, item in pairs(inventory_items) do
		if item.gear_id == gear_id then
			return item
		end
	end
end

local _equip_items = function(profile_preset, profile, inventory_items)

	local profile_loadout = profile.loadout
	local equip_items_by_slot = {}
	local equip_local_items_by_slot = {}
	local unequip_slots = {}
	local equip_items = false

	for slot_name, slot_data in pairs(ItemSlotSettings) do
		if _valid_slot_for_archetype(slot_name, profile.archetype.name) then
            local gear_id = profile_preset.loadout[slot_name]
			local item = _get_inventory_item_by_id(gear_id, inventory_items)

            if item then
                if item.always_owned then
                    equip_local_items_by_slot[slot_name] = item
                else
                    equip_items_by_slot[slot_name] = item
                end

                profile_loadout[slot_name] = item
                equip_items = true
            else
                unequip_slots[slot_name] = true
            end
		end
	end

	local promises = {}

	if equip_items and not table.is_empty(equip_items_by_slot) then
		promises[#promises + 1] = Items.equip_slot_items(equip_items_by_slot)
	end

	if equip_items and not table.is_empty(equip_local_items_by_slot) then
		promises[#promises + 1] = Items.equip_slot_master_items(equip_local_items_by_slot)
	end

	if equip_items and not table.is_empty(unequip_slots) then
		promises[#promises + 1] = Items.unequip_slots(unequip_slots)
	end

	if #promises > 0 then
		return Promise.all(unpack(promises))
	end
end

local _equip_talents = function(player, profile_preset, profile)
	local talent_info, specialization_talent_info
    local archetype = profile.archetype
    local talent_tree_path = archetype.talent_layout_file_path
    local special_talent_tree_path = archetype.specialization_talent_layout_file_path

    local talent_tree = talent_tree_path and require(talent_tree_path)
    local special_talent_tree = special_talent_tree_path and require(special_talent_tree_path)

    if talent_tree then
        talent_info = {
            layout = talent_tree,
            node_tiers = TalentLayoutParser.filter_layout_talents(profile, "talent_layout_file_path", profile_preset.talents),
        }
    end

    if special_talent_tree then
        specialization_talent_info = {
            layout = special_talent_tree,
            node_tiers = TalentLayoutParser.filter_layout_talents(profile, "specialization_talent_layout_file_path", profile_preset.talents),
        }
    end

	if talent_info or specialization_talent_info then
		Managers.data_service.talents:set_talents_v2(player, talent_info, specialization_talent_info)
	end
end

local _apply_loadout_to_current_profile = function(profile_preset, profile, inventory_items)
    local player = Managers.player:local_player_safe(1)
    local synchronizer_host = Managers.profile_synchronization:synchronizer_host()

    local current_profile = player:profile()

    local current_cid = current_profile.character_id
    local new_cid = profile.character_id

    if current_cid == new_cid then
        _equip_items(profile_preset, profile, inventory_items)
		_equip_talents(player, profile_preset, profile)
        ProfileUtils.save_active_profile_preset_id(profile_preset)
        Managers.event:trigger("event_on_profile_preset_changed", profile_preset)
    end
end

LoadoutRandomizerProfile.apply_randomizer_loadout_to_profile_preset = function(data)

    --mod:echo("applying profile")

    local profile = data.profile
    local character_id = profile.character_id
    local profile_preset = LoadoutRandomizerProfileUtils.get_randomizer_profile(character_id)

    Managers.data_service.gear:fetch_inventory(character_id):next(function (inventory_items)
        LoadoutRandomizerInventory.apply_loadout(data, profile_preset, character_id, inventory_items)
        LoadoutRandomizerProfileUtils.save_randomizer_profile(profile_preset, character_id)
        _apply_loadout_to_current_profile(profile_preset, profile, inventory_items)
    end)
end

return LoadoutRandomizerProfile