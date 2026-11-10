local mod = get_mod("milk_cat_balance")

local function spoof_weapon_balance_detection()
    local dutchspice = get_mod("DutchSpice")

    if not dutchspice or not dutchspice.on_all_mods_loaded then
        mod:echo("Dutch Spice Disabled")
        return
    end

    if not debug or not debug.getupvalue then
        mod:echo("debug.getupvalue unavailable")
        return
    end

    if not setfenv or not getfenv then
        mod:echo("setfenv/getfenv unavailable")
        return
    end

    -- find dutch check_for_buffs function
    local check_for_buffs

    for i = 1, 50 do
        local name, value = debug.getupvalue(
            dutchspice.on_all_mods_loaded, i
        )

        if not name then
            break
        end

        if name == "check_for_buffs" then
            check_for_buffs = value
            break
        end
    end

    if not check_for_buffs then
        mod:echo("Could not find check_for_buffs")
        return
    end

    -- temporarily spoof get_mod
    local old_env = getfenv(check_for_buffs)
    local fake_env = setmetatable({}, {
        __index = old_env
    })

    fake_env.get_mod = function(name)
        if name == "Weapon Balance" then
            return true
        end

        return old_env.get_mod(name)
    end

    setfenv(check_for_buffs, fake_env)
    check_for_buffs()
    setfenv(check_for_buffs, old_env)

    mod:echo("Attempted CBR Spoof")
end

mod.on_all_mods_loaded = function()
    spoof_weapon_balance_detection()
end