
local mod = get_mod("loadout_randomizer")

local TalentLayoutParser = require("scripts/ui/views/talent_builder_view/utilities/talent_layout_parser")
local TalentBuilderViewSettings = require("scripts/ui/views/talent_builder_view/talent_builder_view_settings")
local talent_category_settings = TalentBuilderViewSettings.settings_by_node_type

local LoadoutRandomizerProfileTalents = {}

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

-- Randomly selects a path through the talent tree hitting specific anchor nodes
local select_random_talents_anchored = function(
    talent_tree,
    anchor_nodes
)

    if not mod:get("sett_talent_tree_select_fill_nodes_id") then return anchor_nodes end

    local root_node = get_root_node(talent_tree)
    assert(root_node.type == "start", "Expected the root node to appear first in talent tree nodelist.")

    local tree_adj = create_talent_tree_adjacency(talent_tree)

    return select_random_talent_path_complete(
        tree_adj,
        root_node.widget_name,
        anchor_nodes
    )
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

local reconstruct_path = function(parent_map, sink)
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

local select_random_talent_path = function(talent_tree_adjacency, src, sink, points_remaining)
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
                local shuffled_children = {table.unpack(children)}
                shuffle_table(shuffled_children)

                for _, child in ipairs(shuffled_children) do
                    if not visited[child] then
                        visited[child] = true -- MARK VISITED IMMEDIATELY
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

local TOTAL_POINT_CAP = 30

local select_random_talent_path_complete = function(talent_tree_adjacency, root_node_id, anchor_node_order)
    local current_source = root_node_id
    local full_path = {}
    local seen_nodes = {}

    local points_spent = 0

    seen_nodes[root_node_id] = true

    for _, anchor_node_id in ipairs(anchor_node_order) do
        local budget = TOTAL_POINT_CAP - points_spent

        local segment = select_random_talent_path(talent_tree_adjacency, current_source, anchor_node_id, budget)
        
        for i = 2, #segment do
            local node_id = segment[i]
            if not seen_nodes[node_id] then
                table.insert(full_path, node_id)
                seen_nodes[node_id] = true
                points_spent = points_spent + 1
            end
        end

        if #segment > 0 then
            current_source = anchor_node_id
        end
    end

    if #full_path == 0 then
        return anchor_node_order
    end

    return full_path
end


local get_talent_tree = function(archetype)
	local all_talent_data = archetype.talents
	local talent_tree_path = string.format("scripts/ui/views/talent_builder_view/layouts/%s_tree", archetype.name)
	local exists = Application.can_get_resource("lua", talent_tree_path)
	local tree = require(talent_tree_path)

	if not exists or not tree then return end

    return tree
end

local get_talent_node_ids = function(talent_categories)
    if talent_categories == nil then return end

    local talents_by_y = {}
    local anchor_nodes = {}

    for _, talent_category in pairs(talent_categories) do
        for _, talent in pairs(talent_category) do
            table.insert(talents_by_y, talent)
        end
    end

    table.sort(talents_by_y, function(a, b)
        return a.node_depth < b.node_depth
    end)

    for _, talent in ipairs(talents_by_y) do
        table.insert(anchor_nodes, talent.node_id)
    end

    return anchor_nodes
end

LoadoutRandomizerProfileTalents.apply_talents_loadout = function(randomizer_data, profile_preset, character_id)

    if not mod:get("sett_talent_tree_select_enabled_id") then return end

    local randomizer_talents = randomizer_data.talents
    local profile = randomizer_data.profile
    local talent_tree = get_talent_tree(randomizer_data.archetype)
    local anchor_nodes = get_talent_node_ids(randomizer_talents, anchor_nodes)
    local selected_talent_nodes = select_random_talents_anchored(talent_tree, anchor_nodes)

    local talents = {}

    for key, selected_talent in ipairs(selected_talent_nodes) do
        talents[selected_talent] = 1
    end

    local active_talent_version = TalentLayoutParser.talents_version(profile)

    LoadoutRandomizerProfileUtils.save_talent_nodes(profile_preset, talents, active_talent_version)
end

return LoadoutRandomizerProfileTalents