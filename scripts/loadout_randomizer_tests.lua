local mod = get_mod("loadout_randomizer")

local LoadoutRandomizerGenerator = mod:io_dofile("loadout_randomizer/scripts/loadout_randomizer_generator")

local generate_weapon_randomization_dataset = function()

    local datas = {}

    gbl_d = datas

    for i=0, 1000 do
        local data = LoadoutRandomizerGenerator.generate_random_loadout(
            {
                "ability",
                "aura",
                "keystone",
                "tactical", --blitz
            },
            "zealot"
        )

        for weapon_id, weapon in pairs(data.weapons) do
            if datas[weapon_id] == nil then
                datas[weapon_id] = {}
            end
            datas[weapon_id][weapon.item.weapon_template] = (datas[weapon_id][weapon.item.weapon_template] or 0) + 1
        end
        --[[
        for category_id, category in data.talents do
            if datas[category_id] == nil then
                datas[category_id] = {}
            end
            for talent_id, talent in pairs(category) do
                datas[category_id][]
            end
        end
        ]]
    end

end

local generate_lonewolf_randomization_dataset = function()

    local datas = {}
    datas.blitz = {}
    datas.keystones = {}
    datas.aura = {}
    datas.talent_conflicts = 0

    gbl_d = datas

    for i=0, 1000 do
        local data = LoadoutRandomizerGenerator.generate_random_loadout(
            {
                "ability",
                "aura",
                "keystone",
                "tactical", --blitz
            },
            "adamant"
        )

        local keystones = data.talents.keystone or nil
        local blitz = data.talents.tactical or nil
        local aura = data.talents.aura or nil

        if keystones and blitz then
            if keystones["adamant_disable_companion"] then
                mod:echo("lonewolf!!")
                if blitz["adamant_whistle"] then
                    mod:echo("wtf lonewolf!!")
                    datas.talent_conflicts = datas.talent_conflicts + 1
                end
                if aura["adamant_companion_coherency"] then
                    mod:echo("wtf lonewolf!!")
                    datas.talent_conflicts = datas.talent_conflicts + 1
                end
            end
            for id, keystone in pairs(keystones) do
                datas.keystones[id] = keystone
            end
            for id, keystone in pairs(aura) do
                datas.aura[id] = keystone
            end
        end
    end

end

mod.generate_randomization_dataset = generate_lonewolf_randomization_dataset