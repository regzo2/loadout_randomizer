
local mod = get_mod("loadout_randomizer")

local Archetypes = require("scripts/settings/archetype/archetypes")
local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")

local LoadoutRandomizerGenerator = {}

local map_talent_tree_to_data = function(archetype, randomizer_data)
	local all_talent_data = archetype.talents
	local talent_tree_path = string.format("scripts/ui/views/talent_builder_view/layouts/%s_tree", archetype.name)
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

	randomizer_data.talents = {}
	local talents = randomizer_data.talents

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
end

local get_archetype_patterns = function(archetype)
	local WeaponUnlockSettings = require("scripts/settings/weapon_unlock/weapon_unlock_settings")

	local unlocks = WeaponUnlockSettings[archetype.name]
	local patterns = {}
	for _, unlock in pairs(unlocks) do
		--gbl_ul = unlock
		for __, item in pairs(unlock) do
			local master_item = MasterItems.get_item(item)
			local pattern_id = master_item.parent_pattern
			local pattern = UISettings.weapon_patterns[pattern_id]

			local weapon_data = {}
			weapon_data.pattern = pattern
			weapon_data.item = master_item

			patterns[master_item.parent_pattern] = weapon_data
		end
	end
	return patterns
end

local get_item_data = function(archetype, randomizer_data)
	randomizer_data.weapons = {}
	randomizer_data.weapons.ranged = {}
	randomizer_data.weapons.melee = {}
	
	local ranged_table = randomizer_data.weapons.ranged
	local melee_table = randomizer_data.weapons.melee

	local patterns = get_archetype_patterns(archetype)
	local archetype_name = archetype.name
	local breed_name = archetype.breed

	for pattern_name, pattern in pairs(patterns) do
		if pattern.item.item_type == "WEAPON_MELEE" then
			melee_table[pattern_name] = pattern.pattern
		else
			ranged_table[pattern_name] = pattern.pattern
		end
	end	
end

local select_random_weapon = function(weighted_list)

	local count = 0

	for _, entry in pairs(weighted_list) do
		count = count + entry.weight
	end

	local weighted_count = math.random() * count
	local weighted_index = 0
	local index = 0

	local selected_weapon
	local selected_weapon_item

	while weighted_index < weighted_count do
		selected_weapon = weighted_list[index+1]
		index = (index + 1) % (#weighted_list)

		selected_weapon_item = MasterItems.get_item(selected_weapon.item)
		if selected_weapon_item then
			weighted_index = weighted_index + selected_weapon.weight
		end
	end

	return {item = selected_weapon_item, weight = selected_weapon.weight, totals = count}
end

local get_random_weighted_weapon = function(archetype, weapons_table)
	local weapons = {}

	for _, archetype_weapon in pairs(weapons_table) do
		for __, mark in pairs(archetype_weapon.marks) do
			mark.weight = mod:get("weapon_".. mark.name .. "_weight_id") or 1
			table.insert(weapons, mark)
		end
	end

	return select_random_weapon(weapons)
end

local function random_element(tbl, selected_talents)
    local keys = {}
    for key, value in pairs(tbl) do
		if selected_talents then
			if value.requirements and value.requirements.incompatible_talent then
				if selected_talents[value.requirements.incompatible_talent] then
					--mod:echo("redact key: " .. key)
					--nothing
				else
					--mod:echo("unredact key: " .. key)
					table.insert(keys, key)
				end
			else
				--mod:echo("e key: " .. key)
				table.insert(keys, key)
			end
		else
			table.insert(keys, key)
		end
    end

    local randomKey = math.random(#keys)
    return keys[randomKey]
end

local get_filtered_talent_set = function(archetype, talent_set)
	local talents = talent_set
	local talents_by_ex_group = {}

	for key, keystone in pairs(talents) do
		local group = keystone.requirements.exclusive_group
		if keystone.requirements.exclusive_group then
			if talents_by_ex_group[group] == nil then
				talents_by_ex_group[group] = {}
			end
			if keystone.requirements.incompatible_talent then
				local incompat_key = keystone.requirements.incompatible_talent
				local excluded_talent = talents[incompat_key]
				talents_by_ex_group[group][incompat_key] = excluded_talent
			end
			talents_by_ex_group[group][key] = keystone
		end
	end

	return talents_by_ex_group
end

local get_random_talents_from_sets = function(keystone_sets, selected_talents, roll_stoneless)
	local talents = {}
	local chance_for_keystoneless = mod:get("sett_keystoneless_chance_id")
	for key, set in pairs(keystone_sets) do

		local r_key = random_element(set, selected_talents)
		local talent = set[r_key]

		if roll_stoneless then
			talent.unrolled = math.random() <= chance_for_keystoneless
		end

		talents[r_key] = talent

		if selected_talents then
			selected_talents[r_key] = talents[r_key]
		end
	end
	--mod:dump(talents, "" , 10)
	return talents
end

local localize_talents = function(talents)
	local talents_str = ""
	local index = 1
	for key, keystone in pairs(talents) do
		if not keystone.display_name then
			talents_str = talents_str .. "\n Keystone " .. index .. ":	 " .. "No Keystone!"
		else
			talents_str = talents_str .. "\n Keystone " .. index .. ":	 " .. Localize(keystone.display_name)
		end
		index = index + 1
	end
	return talents_str
end

local get_random_talent_from_set = function(talents, selected_talents)
	return talents[random_element(talents, selected_talents)]
end

LoadoutRandomizerGenerator.generate_random_loadout = function(talents_mask, archetype_name)

    local data = {}
    data.class = {}
    local class_data = data.class

	for name, archetype in pairs(Archetypes) do
		class_data[name] = {}

		get_item_data(archetype, class_data[name])
		map_talent_tree_to_data(archetype, class_data[name])
	end

	data.archetype = archetype_name and Archetypes[archetype_name] or Archetypes[random_element(Archetypes)]
	local arch_id = data.archetype.name

	data.weapons = {}

	data.weapons.ranged = get_random_weighted_weapon(data.archetype, class_data[arch_id].weapons.ranged)
	data.weapons.melee = get_random_weighted_weapon(data.archetype, class_data[arch_id].weapons.melee)

	local selected_talents = {}

	if talents_mask then
		data.talents = {}
		for _, talent_type_id in pairs(talents_mask) do
			local roll_stoneless = talent_type_id == "keystone"
			local filtered_set = get_filtered_talent_set(data.archetype, class_data[arch_id].talents[talent_type_id])
			data.talents[talent_type_id] = get_random_talents_from_sets(filtered_set, selected_talents, roll_stoneless)
		end
	end

    return data
end

return LoadoutRandomizerGenerator