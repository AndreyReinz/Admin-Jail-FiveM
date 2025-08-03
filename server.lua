local admins = {
    steam = {"110000139dc0b25"},
    discord = {"515202972867624961", "1066558504195862629"}
}

local jailedPlayers = {}
local playerJailTimers = {}
local jailLocation = vector3(4391.08, -4623.84, 134.42)
local releaseLocation = vector3(-1792.08, 4069.86, 145.70)


function isAdmin(player)
    local identifiers = GetPlayerIdentifiers(player)
    
    for _, id in ipairs(identifiers) do
        if string.find(id, "steam:") then
            local steamId = string.sub(id, 7)
            for _, adminSteam in ipairs(admins.steam) do
                if steamId == adminSteam then return true end
            end
        end
        
        if string.find(id, "discord:") then
            local discordId = string.sub(id, 9)
            for _, adminDiscord in ipairs(admins.discord) do
                if discordId == adminDiscord then return true end
            end
        end
    end
    
    return false
end

function GetAllPlayerIdentifiers(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local result = {}
    
    for _, id in ipairs(identifiers) do
        if string.find(id, "discord:") then table.insert(result, id)
        elseif string.find(id, "license:") then table.insert(result, id)
        elseif string.find(id, "license2:") then table.insert(result, id)
        elseif string.find(id, "live:") then table.insert(result, id)
        elseif string.find(id, "steam:") then table.insert(result, id)
        elseif string.find(id, "xbl:") then table.insert(result, id)
        end
    end
    
    return result
end


RegisterCommand('ajail', function(source, args, rawCommand)
    if source == 0 then
        print("Эта команда может быть использована только игроком")
        return
    end
    
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'У вас нет прав для использования этой команды' } })
        return
    end
    
    if #args < 3 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Использование', '/ajail [ID] [Время в минутах] [Причина]' } })
        return
    end
    
    local targetId = tonumber(args[1])
    local time = tonumber(args[2])
    local reason = table.concat(args, " ", 3)
    
    if not targetId or not time then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'Неверные параметры' } })
        return
    end
    
    local targetPlayer = GetPlayerPed(targetId)
    if not targetPlayer then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'Игрок не найден' } })
        return
    end
    
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(source)
    
    if not targetName or not adminName then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'Не удалось получить информацию об игроке' } })
        return
    end
    
    local identifiers = GetAllPlayerIdentifiers(targetId)
    local endTime = os.time() + (time * 60)
    
    jailedPlayers[targetId] = {
        identifiers = identifiers,
        endTime = endTime,
        reason = reason,
        jailedBy = adminName,
        playerName = targetName,
        originalTime = time * 60
    }
    
    playerJailTimers[targetId] = endTime
    SaveJailedPlayers()
    TriggerClientEvent('ajail:jailPlayer', targetId, time, reason)
    
    TriggerClientEvent('chat:addMessage', -1, {
        color = {255, 0, 0},
        args = {
            "^3[МОСКВА]",
            "^8Администратор ^7"..adminName.." ^8посадил в Деморган игрока ^8"..targetName.." ^8на ^8"..time.." минут^8. Причина: ^8"..reason
        },
        multiline = true
    })
end)

-- Команда для освобождения
RegisterCommand('unjail', function(source, args, rawCommand)
    if source == 0 then
        print("Эта команда может быть использована только игроком")
        return
    end
    
    if not isAdmin(source) then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'У вас нет прав для использования этой команды' } })
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Использование', '/unjail [ID]' } })
        return
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'Неверный ID игрока' } })
        return
    end
    
    -- Проверяем по идентификаторам на случай если ID изменился
    local found = false
    local playerIdentifiers = GetAllPlayerIdentifiers(targetId)
    
    for playerId, data in pairs(jailedPlayers) do
        for _, jailedId in ipairs(data.identifiers) do
            for _, currentId in ipairs(playerIdentifiers) do
                if jailedId == currentId then
                    targetId = playerId -- Обновляем targetId на актуальный
                    found = true
                    break
                end
            end
            if found then break end
        end
        if found then break end
    end
    
    if not jailedPlayers[targetId] then
        TriggerClientEvent('chat:addMessage', source, { args = { '^1Ошибка', 'Этот игрок не в Деморгане' } })
        return
    end
    
    local playerName = jailedPlayers[targetId].playerName
    jailedPlayers[targetId] = nil
    playerJailTimers[targetId] = nil
    SaveJailedPlayers()
    
    TriggerClientEvent('ajail:unjailPlayer', targetId, true)
    
    TriggerClientEvent('chat:addMessage', source, { 
        args = { '^2Успех', 'Игрок '..playerName..' освобожден из Деморгана' } 
    })
end)

-- Проверка при подключении
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    deferrals.defer()
    local player = source
    local identifiers = GetAllPlayerIdentifiers(player)
    local currentTime = os.time()
    
    Citizen.Wait(2000) -- Даем больше времени на загрузку идентификаторов
    
    for playerId, data in pairs(jailedPlayers) do
        for _, jailedId in ipairs(data.identifiers) do
            for _, currentId in ipairs(identifiers) do
                if jailedId == currentId then
                    if data.endTime > currentTime then
                        local remainingTime = math.floor((data.endTime - currentTime) / 60)
                        deferrals.update(("Вы будете отправлены в Деморган. Осталось: %d мин. Причина: %s"):format(remainingTime, data.reason))
                        
                        -- Обновляем запись для нового playerId
                        jailedPlayers[player] = {
                            identifiers = identifiers,
                            endTime = data.endTime,
                            reason = data.reason,
                            jailedBy = data.jailedBy,
                            playerName = name,
                            originalTime = data.originalTime
                        }
                        playerJailTimers[player] = data.endTime
                        
                        -- Удаляем старую запись если ID изменился
                        if playerId ~= player then
                            jailedPlayers[playerId] = nil
                            playerJailTimers[playerId] = nil
                        end
                        
                        SaveJailedPlayers()
                        Citizen.Wait(3000)
                    else
                        -- Если срок истек - удаляем запись
                        jailedPlayers[playerId] = nil
                        playerJailTimers[playerId] = nil
                        SaveJailedPlayers()
                    end
                    break
                end
            end
        end
    end
    
    deferrals.done()
end)

-- Проверка после загрузки игрока
RegisterNetEvent('ajail:playerLoaded')
AddEventHandler('ajail:playerLoaded', function()
    local src = source
    local identifiers = GetAllPlayerIdentifiers(src)
    local currentTime = os.time()
    
    for playerId, data in pairs(jailedPlayers) do
        for _, jailedId in ipairs(data.identifiers) do
            for _, currentId in ipairs(identifiers) do
                if jailedId == currentId and data.endTime > currentTime then
                    local timeLeft = math.max(1, math.floor((data.endTime - currentTime) / 60))
                    TriggerClientEvent('ajail:jailPlayer', src, timeLeft, data.reason)
                    return
                end
            end
        end
    end
end)

-- Проверка времени заключения
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Проверка каждую минуту
        local currentTime = os.time()
        local toRemove = {}
        
        for playerId, endTime in pairs(playerJailTimers) do
            if endTime <= currentTime then
                if GetPlayerPed(playerId) then
                    TriggerClientEvent('ajail:unjailPlayer', playerId, false)
                end
                table.insert(toRemove, playerId)
            end
        end
        
        for _, playerId in ipairs(toRemove) do
            jailedPlayers[playerId] = nil
            playerJailTimers[playerId] = nil
        end
        
        if #toRemove > 0 then
            SaveJailedPlayers()
        end
    end
end)

function SaveJailedPlayers()
    SaveResourceFile(GetCurrentResourceName(), "jailed_players.json", json.encode(jailedPlayers), -1)
end

-- Загрузка данных
Citizen.CreateThread(function()
    Citizen.Wait(5000)
    local data = LoadResourceFile(GetCurrentResourceName(), "jailed_players.json")
    if data then
        jailedPlayers = json.decode(data)
        local currentTime = os.time()
        local toRemove = {}
        
        for playerId, data in pairs(jailedPlayers) do
            if data.endTime <= currentTime then
                table.insert(toRemove, playerId)
            else
                playerJailTimers[playerId] = data.endTime
            end
        end
        
        for _, playerId in ipairs(toRemove) do
            jailedPlayers[playerId] = nil
        end
        
        if #toRemove > 0 then
            SaveJailedPlayers()
        end
    end
end)