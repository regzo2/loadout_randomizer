local mod = get_mod("loadout_randomizer")

local LoadoutRandomizerGenerator = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_generator")

local generate_randomization_dataset = function(iterations, class)

    iterations = tonumber(iterations) or 100
    class = tostring(class)

    local stats = {
        counts = {},
        runs = 0,
    }

    local function update_count(category, item)
        stats.counts[category] = stats.counts[category] or {}
        stats.counts[category][item] = (stats.counts[category][item] or 0) + 1
    end

    for i=0, iterations do
        local data = LoadoutRandomizerGenerator.generate_random_loadout(class)

    end

    --[[
    mod:echo("- Randomization Test Results (" .. class .. ") -")
    for category, items in pairs(stats.counts) do
        mod:echo("Category: " .. category)
        for name, count in pairs(items) do
            local percent = (count / iterations) * 100
            mod:echo(string.format("  - %s: %d (%.2f%%)", name, count, percent))
        end
    end
    ]]

end

mod.tests_debug = function()
    mod:command("rl_run_tests", "Run Tests. rl_run_tests [iter] [class]", generate_randomization_dataset)
    if mod:get("sett_debug_enabled_id") then
        mod:command_enable("rl_run_tests")
    else
        mod:command_disable("rl_run_tests")
    end
end