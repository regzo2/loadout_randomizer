local mod = get_mod("loadout_randomizer")

local Archetypes = require("scripts/settings/archetype/archetypes")
local UISettings = require("scripts/settings/ui/ui_settings")
local ITEM_TYPES = UISettings.ITEM_TYPES
local MasterItems = require("scripts/backend/master_items")
local LoadoutRandomizerGenerator    = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_generator")
local LoadoutRandomizerProfileUtils = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_profile_utils")

mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_tests")
mod:io_dofile("loadout_randomizer/scripts/views/inventory_background_view/inventory_background_view_override")
mod:io_dofile("loadout_randomizer/scripts/profileutils_overrides")
mod:io_dofile("loadout_randomizer/scripts/view_elements/view_element_profile_presets/view_element_profile_presets_override")

mod.randomizer_profiles = mod:get("data_randomizer_profiles") or {}

mod.on_setting_changed = function()
	mod.sett_weapon_display_format 	= mod:get("sett_weapon_display_format_id")
	mod.sett_display_weapon_chance 	= mod:get("sett_weapon_chance_id")
	mod.sett_randomize_weapons 		  = mod:get("sett_randomize_weapons_id")
end

mod.on_setting_changed()

local view_name = "loadout_randomizer"
local view_path = "loadout_randomizer/scripts/views/loadout_randomizer_view/loadout_randomizer_view"

mod:add_require_path(view_path)

mod:register_view({
  view_name = view_name,
  view_settings = {
    init_view_function = function(ingame_ui_context)
      return true
    end,
    state_bound = true,
    display_name = "loc_eye_color_sienna_desc",
    path = view_path,
    package = "packages/ui/views/talent_builder_view/talent_builder_view",
    class = "LoadoutRandomizerView",
    load_in_hub = true,
    game_world_blur = 1,
	--use_transition_ui = true,
	levels = {
		"content/levels/ui/class_selection/class_selection_adamant/class_selection_adamant",
		"content/levels/ui/class_selection/class_selection_broker/class_selection_broker",
		"content/levels/ui/class_selection/class_selection_ogryn/class_selection_ogryn",
		"content/levels/ui/class_selection/class_selection_psyker/class_selection_psyker",
		"content/levels/ui/class_selection/class_selection_veteran/class_selection_veteran",
		"content/levels/ui/class_selection/class_selection_zealot/class_selection_zealot",
	},
    enter_sound_events = {
      "wwise/events/ui/play_ui_enter_short"
    },
    exit_sound_events = {
      "wwise/events/ui/play_ui_back_short"
    },
    wwise_states = {}
  },
  view_transitions = {},
  view_options = {
    close_all = false,
    close_previous = false,
    close_transition_time = nil,
    transition_time = nil
  }
})

function mod.open_view()
  local ui_manager = Managers.ui

  if not ui_manager:has_active_view()
      and not ui_manager:chat_using_input()
      and not ui_manager:view_instance(view_name)
  then

    ui_manager:open_view(view_name)
  elseif ui_manager:view_instance(view_name) then
    ui_manager:close_view(view_name)
  end
end

--mod.on_key_generate_randomizer_data = display_random_loadout
mod:command("randomize_loadout", mod:localize("generate_loadout_cmd_description_id"), mod.open_view)
mod:command("rl", mod:localize("generate_loadout_cmd_description_id"), mod.open_view)

mod:command("rl_clean", mod:localize("generate_loadout_cmd_description_id"), LoadoutRandomizerProfileUtils.delete_randomizer_profile)