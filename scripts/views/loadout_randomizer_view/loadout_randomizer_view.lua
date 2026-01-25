local mod = get_mod("loadout_randomizer")

local ScriptWorld = require("scripts/foundation/utilities/script_world")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local MasterItems = require("scripts/backend/master_items")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local UIScenegraph = require("scripts/managers/ui/ui_scenegraph")
local UIWidget = require("scripts/managers/ui/ui_widget")

local LoadoutRandomizerGenerator = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_generator")

local LoadoutRandomizerViewSettings = mod:io_dofile("loadout_randomizer/scripts/views/loadout_randomizer_view/loadout_randomizer_view_settings")
local LoadoutRandomizerViewDefinitions = mod:io_dofile("loadout_randomizer/scripts/views/loadout_randomizer_view/loadout_randomizer_view_defs")

LoadoutRandomizerView = class("LoadoutRandomizerView", "BaseView")

local packages = {
	"packages/ui/views/talent_builder_view/zealot",
	"packages/ui/views/mastery_view/mastery_view",
}

LoadoutRandomizerView.init = function(self, settings)
	--for _, package in pairs(packages) do

	--end
	LoadoutRandomizerView.super.init(self, LoadoutRandomizerViewDefinitions, settings, nil, nil)
end

LoadoutRandomizerView._setup_background_world = function (self, level_name)
	if self._world_spawner then
		self._world_spawner:destroy()

		self._world_spawner = nil
	end

	self:_register_event("event_register_character_camera")
	self:_register_event("event_register_character_spawn_point")

	local world_name = "ui_class_selection_world"
	local world_layer = 3
	local world_timer_name = "ui"
	self._world_spawner = UIWorldSpawner:new(world_name, world_layer, world_timer_name, self.view_name)

	self._world_spawner:spawn_level(level_name)

	--self._world_spawner:set_camera_position(Vector3(100, 100, 100))

	--gbl_world = self._world_spawner
end

LoadoutRandomizerView.event_register_character_camera = function (self, camera_unit)
	self:_unregister_event("event_register_character_camera")

	local viewport_name = "ui_class_selection_viewport"
	local viewport_type = "default"
	local viewport_layer = 1
	local shading_environment = "content/shading_environments/ui/class_selection"

	self._world_spawner:create_viewport(camera_unit, viewport_name, viewport_type, viewport_layer, shading_environment)

	--self._fade_animation_id = self:_start_animation("fade_in", nil, self._render_settings)
end

LoadoutRandomizerView.event_register_character_spawn_point = function (self, spawn_point_unit)
	self:_unregister_event("event_register_character_spawn_point")

	self:_start_animation("on_world_fade_in", nil, nil, nil, nil, 0)
	self._spawn_point_unit = spawn_point_unit
end

LoadoutRandomizerView._setup_widgets = function(self)
	self:_setup_input_legend()
	self:_setup_loadout_widgets()

	self:_start_animation("on_enter", self._widgets, self)
end

LoadoutRandomizerView.on_enter = function(self)
	LoadoutRandomizerView.super.on_enter(self)
	self:_start_animation("on_init", self._widgets, self)

	if not mod.all_profiles_data then
		Managers.data_service.profiles:fetch_all_profiles():next(function (profile_data)
			mod.all_profiles_data = profile_data
			self:_setup_widgets()
		end):catch(function (error)
			--mod:echo("error for some reason")
		end)  
	else
		self:_setup_widgets()
	end
end

LoadoutRandomizerView._setup_input_legend = function(self)
	self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)
	local legend_inputs = self._definitions.legend_inputs

	for i = 1, #legend_inputs do
		local legend_input = legend_inputs[i]
		local on_pressed_callback = legend_input.on_pressed_callback
			and callback(self, legend_input.on_pressed_callback)

		self._input_legend_element:add_entry(
			legend_input.display_name,
			legend_input.input_action,
			legend_input.visibility_function,
			on_pressed_callback,
			legend_input.alignment
		)
	end
end

LoadoutRandomizerView._add_widget = function(self, widget_name, widget_definition, widget_scenegraph_definition)

	local scenegraph_definition = self._definitions.scenegraph_definition

	for def_id, def in pairs(self._ui_scenegraph) do
		if scenegraph_definition[def_id] then
			if def.position then
				scenegraph_definition[def_id].position = def.position
			end
			if def.size then
				scenegraph_definition[def_id].size = def.size
			end
		end
	end

	scenegraph_definition[widget_name] = widget_scenegraph_definition

	local scenegraph = UIScenegraph.init_scenegraph(scenegraph_definition, self._render_scale)
	self._ui_scenegraph = scenegraph

	local widget = self:_create_widget(widget_name, widget_definition)
	table.insert(self._widgets, widget)

	return widget
end

LoadoutRandomizerView._remove_widget = function(self, widget)
	UIWidget.destroy(ui_renderer, widget)
end

LoadoutRandomizerView._setup_talent_widgets = function(self, talents)
	local node_types = LoadoutRandomizerViewSettings.settings_by_node_type

	if self._node_widgets then
		for _, widget in pairs(self._node_widgets) do
			self:_remove_widget(widget)
		end
		self._node_widgets = nil
	end

	local widgets = {}

	local ordered_talents = table.clone(talents)

	table.sort(ordered_talents, function(a, b)
		return a.sort_order < b.sort_order
	end)

	for talent_id, talent in ipairs(ordered_talents) do
		local talent_category_id = talent.type
		if mod:get("sett_talent_".. talent_category_id .."_enabled_id") then
			local node_type = node_types[talent_category_id] or node_types.default

			local widget_name = "talent_".. talent_category_id .."_node_" .. talent_id
			local node_widget_definition = UIWidget.create_definition(node_type.node_definition, widget_name)
			local node_scenegraph_definition = node_type.node_scenegraph_definition
			local widget = self:_add_widget(widget_name, node_widget_definition, node_scenegraph_definition)

			widget.content.talent = talent
			widget.alpha_multiplier = 0

			table.insert(widgets, widget)
		end
	end

	self:_force_update_scenegraph()

	self._node_widgets = widgets

	for i, widget in ipairs(self._node_widgets) do
		local widget_name = widget.name

		local step = 1000 / (#self._node_widgets + 1)

		self:_set_scenegraph_position(widget_name, -500 + step * i)
	end
end

local start_over = false

LoadoutRandomizerView._setup_loadout_widgets = function(self)
	local archetype_widget = self._widgets_by_name.randomize_archetype_text
	local ranged_widget = self._widgets_by_name.randomize_weapon_ranged_icon
	local melee_widget = self._widgets_by_name.randomize_weapon_melee_icon
	local talent_bg_widget = self._widgets_by_name.layout_background
	local randomize_button = self._widgets_by_name.randomize_button
	local top_divider = self._widgets_by_name.weapon_divider
	local bottom_divider = self._widgets_by_name.talent_divider

	local item_widgets = {
		ranged_widget,
		melee_widget,
	}

	local cb_on_item_roll = function()
		randomize_button.content.hotspot.disabled = true

		local local_player_id = 1
		local player = Managers.player:local_player(local_player_id)
		local archetype_name = player:archetype_name()

		local data = LoadoutRandomizerGenerator.generate_random_loadout()

		local i = 0.6
		local iter = 0.6

		local cb_on_reset = function()

			archetype_widget.content.archetype 	= data.archetype

			if ranged_widget.content.icon_load_id then
				Managers.ui:unload_item_icon(ranged_widget.content.icon_load_id)
			end
			ranged_widget.content.item = data.weapons.ranged.item

			if melee_widget.content.icon_load_id then
				Managers.ui:unload_item_icon(melee_widget.content.icon_load_id)
			end
			melee_widget.content.item = data.weapons.melee.item
			
			talent_bg_widget.content.archetype 	= data.archetype

			self:_setup_talent_widgets(data.talents)

			local cb_on_reroll_finish = function()
				randomize_button.content.hotspot.disabled = false
			end

			if not start_over then
				self:_start_animation("on_start_bg", nil, nil, nil, nil, i)
				start_over = true
			end

			i = i + 1

			self:_start_animation("on_archetype_roll", nil, {widget = archetype_widget}, nil, nil, i)

			i = i + 2

			local params = {
				widgets = {
					top_divider,
				},
				fade_to = 1,
			}

			self:_start_animation("fade_to", nil, params, nil, nil, i)

			for _, widget in pairs(item_widgets) do
				self:_start_animation("on_item_roll", nil, {widget = widget}, nil, nil, i)
				i = i + iter
			end

			local params = {
				widgets = {
					bottom_divider,
				},
				fade_to = 1,
			}

			self:_start_animation("fade_to", nil, params, nil, nil, i)

			for _, widget in pairs(self._node_widgets) do
				self:_start_animation("on_talent_roll", nil, {widget = widget}, nil, nil, i)
				i = i + iter
			end

			i = i + 1
			self:_start_animation("on_archetype_bg_roll", nil, {widget = talent_bg_widget}, callback(cb_on_reroll_finish), nil, i)
		end

		if start_over then
			for _, widget in pairs(item_widgets) do
				self:_start_animation("on_item_reset", nil, {widget = widget}, nil, nil, 0)
			end

			for _, widget in pairs(self._node_widgets) do
				self:_start_animation("on_talent_reset", nil, {widget = widget}, nil, nil, 0)
			end
		end

		self:_start_animation("on_archetype_reset", nil, {widget = archetype_widget}, callback(cb_on_reset), nil, 0)
		self:_start_animation("on_archetype_bg_reset", nil, {widget = talent_bg_widget}, nil, nil, 0)

		local params = {
			widgets = {
				top_divider,
				bottom_divider,
			},
			fade_to = 0,
		}

		self:_start_animation("fade_to", nil, params)
		self:_start_animation("on_world_fade_out", nil, nil, callback(function() 
			self:_setup_background_world("content/levels/ui/class_selection/class_selection_".. data.archetype.name .."/class_selection_" .. data.archetype.name) 
		end), nil, 0)
	end

	randomize_button.content.hotspot.pressed_callback = callback(cb_on_item_roll)
end

LoadoutRandomizerView._on_back_pressed = function(self)
	Managers.ui:close_view(self.view_name)
end

LoadoutRandomizerView._destroy_renderer = function(self)
	if self._offscreen_renderer then
		self._offscreen_renderer = nil
	end

	local world_data = self._offscreen_world

	if world_data then
		Managers.ui:destroy_renderer(world_data.renderer_name)
		ScriptWorld.destroy_viewport(world_data.world, world_data.viewport_name)
		Managers.ui:destroy_world(world_data.world)

		world_data = nil
	end
end

LoadoutRandomizerView.update = function(self, dt, t, input_service)
	return LoadoutRandomizerView.super.update(self, dt, t, input_service)
end

LoadoutRandomizerView.draw = function(self, dt, t, input_service, layer)
	LoadoutRandomizerView.super.draw(self, dt, t, input_service, layer)
end

LoadoutRandomizerView._draw_widgets = function(self, dt, t, input_service, ui_renderer, render_settings)
	LoadoutRandomizerView.super._draw_widgets(self, dt, t, input_service, ui_renderer, render_settings)
end

LoadoutRandomizerView.on_exit = function(self)
	local ranged_widget = self._widgets_by_name.randomize_weapon_ranged_icon
	local melee_widget = self._widgets_by_name.randomize_weapon_melee_icon

	if ranged_widget.content.icon_load_id then
		Managers.ui:unload_item_icon(ranged_widget.content.icon_load_id)
	end

	if melee_widget.content.icon_load_id then
		Managers.ui:unload_item_icon(melee_widget.content.icon_load_id)
	end

	LoadoutRandomizerView.super.on_exit(self)

	if self._world_spawner then
		self._world_spawner:destroy()

		self._world_spawner = nil
	end

	self:_destroy_renderer()
end

return LoadoutRandomizerView