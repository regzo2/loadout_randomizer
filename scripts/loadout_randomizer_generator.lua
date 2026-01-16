
local mod = get_mod("loadout_randomizer")

local Archetypes = require("scripts/settings/archetype/archetypes")
local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")
local LoadoutRandomizerProfile = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile")
local talent_category_settings = TalentBuilderViewSettings.settings_by_node_type

local LoadoutRandomizerGenerator = {}

--------------------------------------------------------
------------------------ UTILS -------------------------
--------------------------------------------------------

local function get_node_depth_graph(node_map, target_widget_name)

    if not node_map.start_node then return -1 end

    local queue = {{node = node_map.start_node, depth = 1}}
    local visited = {}

    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        if current.node.widget_name == target_widget_name then
            return current.depth
        end

        if not visited[current.node.widget_name] then
            visited[current.node.widget_name] = true
            for _, child_name in ipairs(current.node.children or {}) do
                if node_map.nodes[child_name] then
                    table.insert(queue, {node = node_map.nodes[child_name], depth = current.depth + 1})
                end
            end
        end
    end
    return -1
end

local function random_element(tbl)
    local keys = {}
    for key, value in pairs(tbl) do
		table.insert(keys, key)
    end

    local randomKey = math.random(#keys)
    return keys[randomKey]
end

---------------------------------------------------------
----------------- WEAPON RANDOMIZATION ------------------
---------------------------------------------------------

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
	local items = {}
		  items.weapons = {}
		  items.weapons.ranged = {}
		  items.weapons.melee = {}
	
	local ranged_table = items.weapons.ranged
	local melee_table = items.weapons.melee

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

	return items
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

-------------------------------------------------------
---------------- TALENT RANDOMIZATION -----------------
-------------------------------------------------------

local get_talent_tree = function(archetype, talent_tree_key)
	local talent_tree_path = archetype[talent_tree_key]
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

	return tree
end

local map_talent_tree_to_categories = function(archetype, tree)
	local all_talent_data = archetype.talents

	if not tree then return end

	local node_map = {}
		  node_map.nodes = {}
		  node_map.start_node = nil

    for _, node in ipairs(tree.nodes) do
        node_map.nodes[node.widget_name] = node
        if node.type == "start" then 
			node_map.start_node = node 
		end
    end

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
			talents[node.type][node.talent].node_id = node.widget_name
			talents[node.type][node.talent].type = node.type
			talents[node.type][node.talent].sort_order = talent_category_settings[node.type].sort_order
			talents[node.type][node.talent].node_depth = get_node_depth_graph(node_map, node.widget_name)
		end
	end

	return talents
end

local random_talent_from_set = function(talent_set)
	local weighted_count = 0

	local weighted_talent_set = {}

	for talent_id, talent in pairs(talent_set) do
		local talent_weight = mod:get("talent_" .. talent_id .. "_weight_id") or 1
		talent.weight = talent_weight
		talent.key = talent_id
		weighted_count = weighted_count + talent_weight
		table.insert(weighted_talent_set, talent)
	end

	local weighted_target = math.random() * weighted_count
	local weighted_index = 0
	local index = 0

	local selected_talent

	while weighted_index < weighted_target do
		selected_talent = weighted_talent_set[index+1]
		index = (index + 1) % (#weighted_talent_set)

		if selected_talent then
			weighted_index = weighted_index + selected_talent.weight
		end
	end

	return selected_talent.key
end

local get_filtered_talent_set = function(archetype, talent_set)
    local talents_by_ex_group = {}
    if not talent_set then return talents_by_ex_group end

    local index = 1
    for key, talent_node in pairs(talent_set) do
        local group = talent_node.requirements and talent_node.requirements.exclusive_group 
                      or ("unique_" .. key .. "_" .. index)
        index = index + 1

        if not talents_by_ex_group[group] then
            talents_by_ex_group[group] = {}
        end
        
        talents_by_ex_group[group][key] = talent_node
    end

    return talents_by_ex_group
end

local random_talent_from_set = function(talent_set)
    local weighted_talent_set = {}
    local weighted_count = 0

    for talent_id, talent in pairs(talent_set) do
        local talent_weight = mod:get("talent_" .. talent_id .. "_weight_id") or 1
        if talent_weight > 0 then
            weighted_count = weighted_count + talent_weight
            table.insert(weighted_talent_set, {id = talent_id, weight = talent_weight})
        end
    end

    if weighted_count <= 0 then return nil end

    local target = math.random() * weighted_count
    local current = 0
    for _, entry in ipairs(weighted_talent_set) do
        current = current + entry.weight
        if target <= current then
            return entry.id
        end
    end
    return weighted_talent_set[#weighted_talent_set].id
end

local create_talent_conflict_map = function(all_arch_talents)
	local conflict_map = {}
	for cat_name, category_set in pairs(all_arch_talents) do
        for t_id, t_node in pairs(category_set) do
            local enemy_id = t_node.requirements and t_node.requirements.incompatible_talent
            if enemy_id then
                conflict_map[t_id] = enemy_id
                conflict_map[enemy_id] = t_id
            end
        end
    end
	return conflict_map
end

local get_anchor_talents = function(all_arch_talents, data, conflict_map)
	local conflict_map = create_talent_conflict_map(all_arch_talents)
    local anchor_talent_types = {"ability", "tactical", "aura", "keystone"}

	local anchor_talents = {}
	local forbidden_ids = {}

	for _, talent_type in ipairs(anchor_talent_types) do
		local category_data = all_arch_talents[talent_type]
		if category_data then
			local filtered_groups = get_filtered_talent_set(data.archetype, category_data)

			for group_id, group_set in pairs(filtered_groups) do
				local rollable_candidates = {}
				local forced_winner = nil
				
				for t_id, t_node in pairs(group_set) do
					if not forbidden_ids[t_id] then
						local enemy_id = conflict_map[t_id]
						
						if enemy_id and not forbidden_ids[enemy_id] then
							local weight_a = mod:get("talent_" .. t_id .. "_weight_id") or 1
							local weight_b = mod:get("talent_" .. enemy_id .. "_weight_id") or 1
							
							if math.random() * (weight_a + weight_b) < weight_a then
								rollable_candidates[t_id] = t_node
								forbidden_ids[enemy_id] = true
								forced_winner = t_id
							else
								forbidden_ids[t_id] = true
							end
						else
							rollable_candidates[t_id] = t_node
						end
					end
				end

				local selected_key = nil
				if forced_winner and rollable_candidates[forced_winner] then
					selected_key = forced_winner
				else
					selected_key = random_talent_from_set(rollable_candidates)
				end

				if selected_key then
					table.insert(anchor_talents, group_set[selected_key])
					
					local enemy = conflict_map[selected_key]
					if enemy then
						forbidden_ids[enemy] = true
					end
				end
			end
		end
	end

	return anchor_talents
end

------------------------------------------------------
---------------- TALENT TREE BUILDER -----------------
------------------------------------------------------

local get_root_node = function(talent_tree)

    if talent_tree.nodes[1].type == "start" then
        return talent_tree.nodes[1]
    end

    for _, node in pairs(talent_tree.nodes) do
        if node.type == "start" then 
            return node
        end
    end

    return nil
end

local create_talent_tree_conflict_map = function(talent_tree)
	local tree_conflict_map = {}
	for _, t_node in pairs(talent_tree.nodes) do
		local t_id = t_node.widget_name
		local enemy_id = t_node.requirements and t_node.requirements.incompatible_talent
		if enemy_id then
			tree_conflict_map[t_id] = enemy_id
			tree_conflict_map[enemy_id] = t_id
		end
	end
	return tree_conflict_map
end

local create_talent_tree_adjacency = function(talent_tree)
    local adjacency = {}
    for _, node in ipairs(talent_tree.nodes) do
        local children_copy = {}
        for i, child_id in ipairs(node.children) do
            children_copy[i] = child_id
        end
        adjacency[node.widget_name] = children_copy
    end
    return adjacency
end

local reconstruct_path = function(
	parent_map, 
	sink
)
    local path = {}
    local curr = sink
    while curr do
        table.insert(path, 1, curr)
        curr = parent_map[curr]
    end
    return path
end

local shuffle_table = function(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local MAX_BFS_ITERATIONS = 100

local select_anchor_talent_path_bfs_segment = function(
	talent_tree_adjacency, 
	src, 
	sink, 
	tree_conflict_map,
	widget_lookup,
	points_remaining
)
    if src == sink then return {src} end
    if points_remaining <= 0 then return {} end

    local queue = { {id = src, dist = 1} }
    local visited = { [src] = true }
    local parent_map = {}
    
    local head = 1
    local iterations = 0

    while head <= #queue do
        iterations = iterations + 1
        
        if iterations > MAX_BFS_ITERATIONS then 
            mod:echo("BFS Aborted: Could not reach " .. sink .. " from " .. src)
            return {} 
        end

        local curr_data = queue[head]
        local curr = curr_data.id
        local dist = curr_data.dist
        head = head + 1

        if dist <= points_remaining then
            local children = talent_tree_adjacency[curr]
            if children then
                local shuffled_children = {unpack(children)}
                shuffle_table(shuffled_children)

                for _, child in ipairs(shuffled_children) do
                    if not visited[child] then
						local enemy = tree_conflict_map[child]

						if enemy and not visited[enemy] and widget_lookup[enemy] then
							visited[enemy] = true
						end

						if widget_lookup[child] then
                        	visited[child] = true -- MARK VISITED IMMEDIATELY
						end
                        parent_map[child] = curr
                        
                        if child == sink then
                            return reconstruct_path(parent_map, sink)
                        end
                        
                        table.insert(queue, {id = child, dist = dist + 1})
                    end
                end
            end
        end
    end

    return {} 
end

local select_anchor_talent_path_bfs = function(
	talent_tree,
	talent_tree_adjacency, 
	anchor_node_order, 
	start_node_id, 
	seen_nodes, 
	tree_conflict_map,
	widget_lookup,
	points_spent
)
	local path = {}
	local current_source = start_node_id
	local total_point_cap = talent_tree.talent_points

	seen_nodes[start_node_id] = true

	for _, anchor_node_id in ipairs(anchor_node_order) do
        local budget = total_point_cap - points_spent

        local segment = select_anchor_talent_path_bfs_segment(talent_tree_adjacency, current_source, anchor_node_id, tree_conflict_map, widget_lookup, budget)
        
        for i = 2, #segment do
            local node_id = segment[i]
			local enemy = tree_conflict_map[node_id]

			if enemy and not seen_nodes[enemy] then
				seen_nodes[enemy] = true
			end

            if not seen_nodes[node_id] and widget_lookup[node_id] then
                table.insert(path, node_id)
                seen_nodes[node_id] = true
                points_spent = points_spent + widget_lookup[node_id].cost or 1
            end
        end

        if #segment > 0 then
            current_source = anchor_node_id
        end
    end
	return path, points_spent
end

local get_random_weighted_child_node = function(children, widget_lookup)
    local total_weight = 0
    
    for key, node_id in ipairs(children) do
        local widget = widget_lookup[node_id]
        local node_type = widget and widget.type or ""
        local weight = mod:get("sett_talent_" .. node_type .. "_weight_id") or 1
        total_weight = total_weight + weight
    end

    local target = math.random() * total_weight
    local current_sum = 0

    -- Second pass: Find the selected node
    for node_key, node_id in ipairs(children) do
        local widget = widget_lookup[node_id]
        local node_type = widget and widget.type or ""
        local weight = mod:get("sett_talent_" .. node_type .. "_weight_id") or 1
        
        current_sum = current_sum + weight
        if current_sum >= target then
            return node_id, node_key
        end
    end

    return nil
end

local mark_exclusive_branch_as_seen = function(base_child, seen_nodes, widget_lookup)
	local base_child_widget = widget_lookup[base_child]
	local exclusive_group = base_child_widget.requirements and base_child_widget.requirements.exclusive_group
	local parents = base_child_widget.parents

	if exclusive_group then
		for _, parent in ipairs(parents) do
			if not seen_nodes[parent] then
				seen_nodes[parent] = true
			end

			local parent_children = widget_lookup[parent] and widget_lookup[parent].children
			if not parent_children then return end
			for _, child in ipairs(parent_children) do
				if not seen_nodes[child] then
					seen_nodes[child] = true
				end
			end
		end
	end
end

local select_random_walk_talents_on_path = function(
	path,
	talent_tree,
	talent_tree_adjacency, 
	anchor_node_order, 
	start_node_id, 
	seen_nodes, 
	tree_conflict_map,
	widget_lookup,
	points_spent
)
	local locked_by_exclusive_group = {}
	local total_point_cap = talent_tree.talent_points
	local full_path = table.clone(path)

	local valid_children = function(parent_node)
		local children = talent_tree_adjacency[parent_node]
		local valid = {}
		for _, child in ipairs(children) do
			if not seen_nodes[child] then
				table.insert(valid, child)
			end
		end
		return valid
	end

	table.insert(full_path, start_node_id)

	while points_spent < total_point_cap do
		local parent_node, parent_key = get_random_weighted_child_node(full_path, widget_lookup)

		local valid_children = valid_children(parent_node)

		if valid_children then
			local random_child = get_random_weighted_child_node(valid_children, widget_lookup)
			if random_child then
				local widget = widget_lookup[random_child]
				if widget then
					local widget_type = widget.type or ""
					local restricted_types = widget_type == "keystone" 
											or widget_type == "ability" 
											or widget_type == "tactical" 
											or widget_type == "aura"
					local exclusive_group = widget.requirements and widget.requirements.exclusive_group
					local is_group_invalid = exclusive_group and locked_by_exclusive_group[random_child] and (locked_by_exclusive_group[random_child] ~= exclusive_group) or false

					if not seen_nodes[random_child] and not restricted_types and not is_group_invalid then
						
						local cost = widget_lookup[random_child].cost or 1
						local new_points_spent = points_spent + cost
						seen_nodes[random_child] = true
						if new_points_spent <= total_point_cap then
							table.insert(full_path, random_child)
							table.insert(path, random_child)
							points_spent = new_points_spent

							mark_exclusive_branch_as_seen(random_child, seen_nodes, widget_lookup)

							local enemy = tree_conflict_map[random_child]

							if enemy and not seen_nodes[enemy] then
								seen_nodes[enemy] = true
							end
						else
							-- we have reached the maximum we can spend
							break
						end
					end
				end
			end
		end
	end

	return path, points_spent
end

local create_talent_tree_path_complete = function(
	talent_tree,
	talent_tree_adjacency, 
	root_node_id, 
	anchor_node_order,
	widget_lookup,
	tree_conflict_map,
	points_spent
)
    local seen_nodes = {}

	local path, points_spent = select_anchor_talent_path_bfs(
		talent_tree,
		talent_tree_adjacency,
		anchor_node_order, 
		root_node_id, 
		seen_nodes, 
		tree_conflict_map,
		widget_lookup,
		points_spent
	)

	path = select_random_walk_talents_on_path(
		path,
		talent_tree,
		talent_tree_adjacency,
		anchor_node_order, 
		root_node_id, 
		seen_nodes, 
		tree_conflict_map,
		widget_lookup,
		points_spent
	)

    return path
end

local get_anchor_nodes_from_talents = function(talents)
	table.sort(talents, function(a, b)
        return a.node_depth < b.node_depth
    end)

	local anchor_nodes = {}

	for _, talent in ipairs(talents) do
		table.insert(anchor_nodes, talent.node_id)
	end

	return anchor_nodes
end

local get_widget_lookup_from_tree = function(talent_tree)
	local widget_lookup = {}

	for _, node in pairs(talent_tree.nodes) do
		if node.widget_name then
			widget_lookup[node.widget_name] = node
		end
	end

	return widget_lookup
end

local select_random_talents_anchored = function(
    talent_tree,
    anchor_nodes,
	points_spent
)

    local root_node = get_root_node(talent_tree)
    assert(root_node.type == "start", "Expected the root node to appear first in talent tree nodelist.")

	local tree_adj = create_talent_tree_adjacency(talent_tree)
	local widget_lookup = get_widget_lookup_from_tree(talent_tree)
	local tree_conflict_map = create_talent_tree_conflict_map(talent_tree)

    return create_talent_tree_path_complete(
		talent_tree,
        tree_adj,
        root_node.widget_name,
        anchor_nodes,
		widget_lookup,
		tree_conflict_map,
		points_spent
    )
end

local build_talent_tree_selection = function(anchor_talents, data, talent_tree, points_spent)

    local anchor_nodes = get_anchor_nodes_from_talents(anchor_talents)
    local selected_talent_nodes = select_random_talents_anchored(talent_tree, anchor_nodes, points_spent)

	return selected_talent_nodes
end

--------------------------------------------------------
----------------------- PROFILE ------------------------
--------------------------------------------------------

local get_best_matching_profile = function(archetype_name)
	local profiles = mod.all_profiles_data and mod.all_profiles_data.profiles

	if not profiles then 
		return nil 
	end

	local best_matching_profile

	for _, profile in pairs(profiles) do
		--mod:dump(profile, "prof", 1)
		if profile.archetype.name == archetype_name then
			best_matching_profile = profile
		end
	end

	return best_matching_profile
end

local get_talent_data = function(data, talent_tree_key)
	local archetype = data.archetype
	local talent_tree_path = archetype[talent_tree_key]


	if not talent_tree_path then 
		return 
	end

	local talent_tree = get_talent_tree(data.archetype, talent_tree_key)
	local all_arch_talents = map_talent_tree_to_categories(archetype, talent_tree)
	local anchor_talents = get_anchor_talents(all_arch_talents, data)

	local randomize_points = mod:get("sett_".. talent_tree_key .. "_cost_randomization_id")
	local points_spent = randomize_points and math.random(0, talent_tree.talent_points) or 0
	
	local selected_talent_tree = build_talent_tree_selection(anchor_talents, data, talent_tree, points_spent)

	return anchor_talents, selected_talent_tree
end


LoadoutRandomizerGenerator.generate_random_loadout = function(archetype_name)   
    local data = { class = {}, talents = {}, weapons = {} }

	data.archetype = archetype_name and Archetypes[archetype_name] or Archetypes[random_element(Archetypes)]
	local arch_id = data.archetype.name
	data.profile = get_best_matching_profile(arch_id)
	local all_arch_items = get_item_data(data.archetype)

	local anchor_talents, selected_talent_tree 					= get_talent_data(data, "talent_layout_file_path")
	local special_anchor_talents, special_selected_talent_tree 	= get_talent_data(data, "specialization_talent_layout_file_path")
	 
	data.talents = anchor_talents
	data.selected_talent_tree = selected_talent_tree
	data.special_selected_talent_tree = special_selected_talent_tree

	data.weapons.ranged = get_random_weighted_weapon(data.archetype, all_arch_items.weapons.ranged)
	data.weapons.melee = get_random_weighted_weapon(data.archetype, all_arch_items.weapons.melee)

	if data.profile then
    	LoadoutRandomizerProfile.apply_randomizer_loadout_to_profile_preset(data)
	end

	mod.randomizer_data = data
    
    return data
end

return LoadoutRandomizerGenerator