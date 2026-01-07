local mod = get_mod("loadout_randomizer")

local ViewElementProfilePresetsSettings = require("scripts/ui/view_elements/view_element_profile_presets/view_element_profile_presets_settings")
local ProfileUtils = require("scripts/utilities/profile_utils")
local UISoundEvents = require("scripts/settings/ui/ui_sound_events")

local LoadoutRandomizerInventory = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_inventory")
local Definitions = mod:io_dofile("loadout_randomizer/scripts/view_elements/view_element_profile_presets/view_element_profile_presets_override_defs")

local randomizer_profile_widget

local on_randomize_profile_preset_pressed = function (self)
	local profile_buttons_widgets = self._profile_buttons_widgets

    local widget = randomizer_profile_widget
    local content = widget.content
    local hotspot = content.hotspot

    hotspot.is_selected = true

    local profile_preset_id = content.profile_preset_id

    if profile_preset_id ~= self._active_profile_preset_id then
        self._active_profile_preset_id = profile_preset_id
        ProfileUtils.save_active_profile_preset_id(profile_preset_id)
        local profile_preset = ProfileUtils.get_profile_preset(profile_preset_id)

        if profile_preset.is_randomizer_profile then
            -- nothing
        else
            profile_preset.is_randomizer_profile = true
        end
        
        Managers.save:queue_save()
        Managers.event:trigger("event_on_profile_preset_changed", profile_preset)
    end
end

mod:hook_safe(CLASS.ViewElementProfilePresets, "on_profile_preset_index_change", function(self, index, ignore_activation, on_preset_deleted, ignore_sound)
    if randomizer_profile_widget == nil then return end

    if index == 256 then
        on_randomize_profile_preset_pressed(self)
    end
end)

local create_randomizer_widget = function(self, profile_preset)
    local button_width = 44
	local button_spacing = 6
	local total_width = 0
    local randomizer_definitions = Definitions
    local profile_preset_button = randomizer_definitions.profile_preset_button
    local widget_name = "profile_button_randomized"

    local widget = self:_create_widget(widget_name, profile_preset_button)

    local offset = widget.offset

    offset[1] = -(#self._profile_buttons_widgets * button_width + (#self._profile_buttons_widgets - 1) * button_spacing) - 50

    local is_selected = profile_preset.is_randomizer_profile
    local content = widget.content
    local hotspot = content.hotspot

    if is_selected then
        self._active_profile_preset_id = profile_preset.id
        hotspot.is_selected = is_selected

	    for _, p_widget in pairs(self._profile_buttons_widgets) do
            p_widget.content.hotspot.is_selected = false
        end
    end

    self.on_randomize_profile_preset_pressed = on_randomize_profile_preset_pressed
    hotspot.pressed_callback = callback(self, "on_profile_preset_index_change", 256)

    content.profile_preset_id = profile_preset.id

    table.insert(self._profile_buttons_widgets, widget)

    randomizer_profile_widget = widget
end

mod:hook_safe(CLASS.ViewElementProfilePresets, "_setup_preset_buttons", function(self)
    local profile_buttons_widgets = self._profile_buttons_widgets

	if profile_buttons_widgets then
		for i = 1, #profile_buttons_widgets do
			local widget = profile_buttons_widgets[i]
			local name = widget.name

			self:_unregister_widget_name(name)
		end

		table.clear(profile_buttons_widgets)
	else
		profile_buttons_widgets = {}
	end

	local button_width = 44
	local button_spacing = 6
	local total_width = 0
	local optional_preset_icon_reference_keys = ViewElementProfilePresetsSettings.optional_preset_icon_reference_keys
	local optional_preset_icons_lookup = ViewElementProfilePresetsSettings.optional_preset_icons_lookup
	local definitions = self._definitions
	local profile_preset_button = definitions.profile_preset_button
	local active_profile_preset_id = ProfileUtils.get_active_profile_preset_id()
	local profile_presets_base = ProfileUtils.get_profile_presets()
    local profile_presets = {}

    local randomizer_profile = LoadoutRandomizerInventory.get_randomizer_profile()

    for index, preset in ipairs(profile_presets_base) do
        is_randomizer_profile = preset.is_randomizer_profile
        if is_randomizer_profile then
            --randomizer_profile = preset
        else
            table.insert(profile_presets, preset)
        end
    end

	local num_profile_presets = profile_presets and #profile_presets

	for i = num_profile_presets, 1, -1 do
		local profile_preset = profile_presets[i]
		local profile_preset_id = profile_preset and profile_preset.id
		local custom_icon_key = profile_preset and profile_preset.custom_icon_key
		local widget_name = "profile_button_" .. i
		local widget = self:_create_widget(widget_name, profile_preset_button)

		profile_buttons_widgets[i] = widget

		local offset = widget.offset

		offset[1] = -total_width

		local content = widget.content
		local hotspot = content.hotspot

		hotspot.pressed_callback = callback(self, "on_profile_preset_index_change", i)
		hotspot.right_pressed_callback = callback(self, "on_profile_preset_index_customize", i)

		local is_selected = profile_preset_id == active_profile_preset_id

		if is_selected then
			self._active_profile_preset_id = profile_preset_id
		end

		hotspot.is_selected = is_selected

		local default_icon_index = math.index_wrapper(i, #optional_preset_icon_reference_keys)
		local default_icon_key = optional_preset_icon_reference_keys[default_icon_index]
		local default_icon = optional_preset_icons_lookup[custom_icon_key or default_icon_key]

		content.icon = default_icon
		content.profile_preset_id = profile_preset_id
		total_width = total_width + button_width

		if i > 1 then
			total_width = total_width + button_spacing
		end
	end

	self._profile_buttons_widgets = profile_buttons_widgets

    if mod.randomizer_data then
        local local_player_id = 1
        local player = Managers.player:local_player(local_player_id)

        local archetype_name = player:archetype_name()

        if mod.randomizer_data.archetype.name == archetype_name then
            create_randomizer_widget(self, randomizer_profile)
        end
    end

	local panel_width = total_width + button_width + 45

	self:_set_scenegraph_size("profile_preset_button_panel", panel_width)
	self:_force_update_scenegraph()
	self:_sync_profile_buttons_items_status()
end)