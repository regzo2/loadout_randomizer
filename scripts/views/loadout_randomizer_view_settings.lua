local mod = get_mod("loadout_randomizer")

local LoadoutRandomizerViewDefinitions = mod:io_dofile("loadout_randomizer/scripts/views/loadout_randomizer_view_defs")
local widget_definitions = LoadoutRandomizerViewDefinitions.node_widget_definitions

local default_node_scene_definition = {
    parent = "randomize_talents",
    horizontal_alignment = "center",
    vertical_alignment = "center",
    --scale = "fit",
    size = {200, 150},
    position = { 0, 0, 1 }
}

local settings_by_node_type = {
    default = {
        node_scenegraph_definition = default_node_scene_definition,
        --node_definition = node_widget_definitions.
    },
    aura = {
        node_definition = widget_definitions.node_aura_icon,
        node_scenegraph_definition = default_node_scene_definition,
    },
    tactical = {
        node_definition = widget_definitions.node_blitz_icon,
        node_scenegraph_definition = default_node_scene_definition,
    },
    ability = {
        node_definition = widget_definitions.node_ability_icon,
        node_scenegraph_definition = default_node_scene_definition,
    },
    keystone = {
        node_definition = widget_definitions.node_keystone_icon,
        node_scenegraph_definition = default_node_scene_definition,
    },
}

return {
    settings_by_node_type = settings_by_node_type,
}