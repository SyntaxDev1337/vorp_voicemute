

RegisterNetEvent("vorp_pma_mute:setMuteForPlayer")
AddEventHandler("vorp_pma_mute:setMuteForPlayer", function(targetServerId, muted)
    local isMuted = exports["pma-voice"]:isPlayerMuted(targetServerId)
    if muted and not isMuted then
        exports["pma-voice"]:toggleMutePlayer(targetServerId)
    elseif not muted and isMuted then
        exports["pma-voice"]:toggleMutePlayer(targetServerId)
    end
end)


RegisterNetEvent("vorp_pma_mute:notify")
AddEventHandler("vorp_pma_mute:notify", function(muted)
    if muted then
        TriggerEvent("chat:addMessage", {
            color = {255, 255, 255},
            multiline = true,
            args = {"Sistema", "~r~Ai fost mute de catre un admin."}
        })
    else
        TriggerEvent("chat:addMessage", {
            color = {255, 255, 255},
            multiline = true,
            args = {"Sistema", "~g~Ai fost unmute."}
        })
    end
end)
