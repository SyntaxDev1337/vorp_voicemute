local VORPcore = exports.vorp_core:GetCore()


local mutedInServer = {}


local function hasPermission(source)
    local user = VORPcore.getUser(source)
    if not user then return false end
    local group = user.getGroup
    return group == "admin" or group == "superadmin" or group == "moderator"
        or IsPlayerAceAllowed(source, Config.MutePermission)
end

local function notifyPlayer(source, msg)
    TriggerClientEvent("chat:addMessage", source, {
        color = {255, 255, 255},
        multiline = true,
        args = {"System", msg}
    })
end

local function getIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if string.find(id, "steam:") then
            return id
        end
    end
    return nil
end


local function applyVoiceMuteGlobal(targetId, muted)
    if muted then
        mutedInServer[targetId] = true
    else
        mutedInServer[targetId] = nil
    end

    TriggerClientEvent("vorp_pma_mute:setMuteForPlayer", -1, targetId, muted)
end

AddEventHandler("playerDropped", function()
    mutedInServer[source] = nil
end)



AddEventHandler("vorp:SelectedCharacter", function(source, charid)
    local src = source
    Citizen.SetTimeout(3000, function()
        if not GetPlayerName(src) then return end

        local identifier = getIdentifier(src)
        if not identifier then return end

        local result = exports.oxmysql:executeSync(
            "SELECT is_muted FROM users WHERE identifier = ?",
            { identifier }
        )
        if result and result[1] and result[1].is_muted == 1 then
            applyVoiceMuteGlobal(src, true)
            TriggerClientEvent("vorp_pma_mute:notify", src, true)

        end
    end)
end)

AddEventHandler("playerJoining", function()
    local src = source
    Citizen.SetTimeout(5000, function()
        if not GetPlayerName(src) then return end
        for mutedId, _ in pairs(mutedInServer) do
            if GetPlayerName(mutedId) then
                TriggerClientEvent("vorp_pma_mute:setMuteForPlayer", src, mutedId, true)
            end
        end
    end)
end)



RegisterCommand("vcmute", function(source, args, rawCommand)
    if source == 0 then return end

    if not hasPermission(source) then
        notifyPlayer(source, Config.Messages.noPermission)
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        notifyPlayer(source, Config.Messages.notFound)
        return
    end

    local identifier = getIdentifier(targetId)
    if not identifier then
        notifyPlayer(source, Config.Messages.notFound)
        return
    end

    local existing = exports.oxmysql:executeSync(
        "SELECT is_muted FROM users WHERE identifier = ?",
        { identifier }
    )
    if existing and existing[1] and existing[1].is_muted == 1 then
        notifyPlayer(source, Config.Messages.alreadyMuted)
        return
    end

    exports.oxmysql:executeSync(
        "UPDATE users SET is_muted = 1 WHERE identifier = ?",
        { identifier }
    )

    applyVoiceMuteGlobal(targetId, true)
    TriggerClientEvent("vorp_pma_mute:notify", targetId, true)

    local targetName = GetPlayerName(targetId)
    local adminName  = GetPlayerName(source)
    local adminId    = getIdentifier(source)

    notifyPlayer(source, string.format(Config.Messages.mutedAdmin, targetName, identifier))
    print(string.format("[vorp_pma_mute] Admin %s  muted  %s (%s)", adminName, targetName, identifier))

end, false)



RegisterCommand("vcunmute", function(source, args, rawCommand)
    if source == 0 then return end

    if not hasPermission(source) then
        notifyPlayer(source, Config.Messages.noPermission)
        return
    end

    local targetId = tonumber(args[1])
    if not targetId or not GetPlayerName(targetId) then
        notifyPlayer(source, Config.Messages.notFound)
        return
    end

    local identifier = getIdentifier(targetId)
    if not identifier then
        notifyPlayer(source, Config.Messages.notFound)
        return
    end

    local existing = exports.oxmysql:executeSync(
        "SELECT is_muted FROM users WHERE identifier = ?",
        { identifier }
    )
    if not existing or not existing[1] or existing[1].is_muted == 0 then
        notifyPlayer(source, Config.Messages.notMuted)
        return
    end

    exports.oxmysql:executeSync(
        "UPDATE users SET is_muted = 0 WHERE identifier = ?",
        { identifier }
    )

    applyVoiceMuteGlobal(targetId, false)
    TriggerClientEvent("vorp_pma_mute:notify", targetId, false)

    local targetName = GetPlayerName(targetId)
    local adminName  = GetPlayerName(source)
    local adminId    = getIdentifier(source)

    notifyPlayer(source, string.format(Config.Messages.unmutedAdmin, targetName, identifier))
    print(string.format("[vorp_pma_mute] Admin %s  unmuted  %s (%s)", adminName, targetName, identifier))

end, false)
