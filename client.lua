local isJailed = false
local jailTime = 0
local jailReason = ""
local jailTimer = 0
local jailBlip = nil
local jailLocation = vector3(4391.08, -4623.84, 134.42)
local releaseLocation = vector3(-1792.08, 4069.86, 145.70)
local displayText = true
local antiEscapeActive = false


function DrawTextOnScreen(text, x, y, scale, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Функция анти-побега
function StartAntiEscape()
    antiEscapeActive = true
    Citizen.CreateThread(function()
        while antiEscapeActive do
            Citizen.Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            if #(playerCoords - jailLocation) > 50.0 then
                SetEntityCoords(PlayerPedId(), jailLocation)
                SetEntityVelocity(PlayerPedId(), 0.0, 0.0, 0.0)
                TriggerEvent('chat:addMessage', { 
                    color = {255, 0, 0},
                    args = { '^1ДЕМОРГАН', '^1Не пытайтесь сбежать!' } 
                })
            end
            
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
                Citizen.Wait(100)
                DeleteVehicle(vehicle)
            end
        end
    end)
end

-- Обработчик заключения
RegisterNetEvent('ajail:jailPlayer')
AddEventHandler('ajail:jailPlayer', function(time, reason)
    if isJailed then return end
    
    isJailed = true
    jailTime = time * 60
    jailReason = reason
    jailTimer = jailTime
    displayText = true
    

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        DeleteVehicle(vehicle)
        TriggerEvent('chat:addMessage', { 
            color = {255, 0, 0},
            args = { '^1ДЕМОРГАН', '^1Транспортные средства уничтожены!' } 
        })
    end
    

    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Citizen.Wait(10)
    end
    
    SetEntityCoords(PlayerPedId(), jailLocation)
    SetEntityHeading(PlayerPedId(), 72.78)
    FreezeEntityPosition(PlayerPedId(), true)
    
    DoScreenFadeIn(1000)
    Citizen.Wait(1000)
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Метка на карте
    if jailBlip then RemoveBlip(jailBlip) end
    jailBlip = AddBlipForCoord(jailLocation)
    SetBlipSprite(jailBlip, 188)
    SetBlipColour(jailBlip, 1)
    SetBlipScale(jailBlip, 1.0)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Деморган")
    EndTextCommandSetBlipName(jailBlip)
    

    StartAntiEscape()
    
    -- Таймер заключения
    Citizen.CreateThread(function()
        while isJailed and jailTimer > 0 do
            Citizen.Wait(1000)
            jailTimer = jailTimer - 1
        end
        
        if jailTimer <= 0 then
            TriggerEvent('ajail:unjailPlayer', false)
        end
    end)
    

    Citizen.CreateThread(function()
        while isJailed and displayText do
            Citizen.Wait(0)
            local minutes = math.floor(jailTimer / 60)
            local seconds = jailTimer % 60
            DrawTextOnScreen(string.format("~r~ДЕМОРГАН | Причина: %s | Осталось: %d:%02d", jailReason, minutes, seconds), 0.5, 0.05, 0.7, 255, 0, 0, 255)
        end
    end)
end)


RegisterNetEvent('ajail:unjailPlayer')
AddEventHandler('ajail:unjailPlayer', function(byAdmin)
    if not isJailed then return end
    
    isJailed = false
    displayText = false
    jailTime = 0
    jailReason = ""
    antiEscapeActive = false
    
    if jailBlip then
        RemoveBlip(jailBlip)
        jailBlip = nil
    end
    
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Citizen.Wait(10)
    end
    
    SetEntityCoords(PlayerPedId(), releaseLocation)
    SetEntityHeading(PlayerPedId(), 332.02)
    FreezeEntityPosition(PlayerPedId(), true)
    
    DoScreenFadeIn(1000)
    Citizen.Wait(1000)
    FreezeEntityPosition(PlayerPedId(), false)
    
    if byAdmin then
        TriggerEvent('chat:addMessage', { 
            color = {0, 255, 0},
            args = { 'ДЕМОРГАН', 'Вы были освобождены администратором!' } 
        })
    else
        TriggerEvent('chat:addMessage', { 
            color = {0, 255, 0},
            args = { 'ДЕМОРГАН', 'Вы отбыли свой срок и были освобождены!' } 
        })
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        if NetworkIsPlayerActive(PlayerId()) and IsPlayerPlaying(PlayerId()) then
            TriggerServerEvent('ajail:playerLoaded')
            break
        end
    end
end)

-- Блокировка действий
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isJailed then
            DisableControlAction(0, 24, true) -- Атака
            DisableControlAction(0, 25, true) -- Прицеливание
            DisableControlAction(0, 37, true) -- Тачка
            DisableControlAction(0, 45, true) -- Выход из машины
            DisableControlAction(0, 140, true) -- Легкая атака
            DisableControlAction(0, 141, true) -- Тяжелая атака
            DisableControlAction(0, 142, true) -- Альтернативная атака
            DisableControlAction(0, 257, true) -- Атака
            DisableControlAction(0, 263, true) -- Удар
            DisableControlAction(0, 264, true) -- Удар
            DisablePlayerFiring(PlayerPedId(), true)
            
            -- Блокировка F1 и ESC
            DisableControlAction(0, 288, true) -- F1
            DisableControlAction(0, 322, true) -- ESC
            
            -- Удаление оружия
            RemoveAllPedWeapons(PlayerPedId(), true)
        end
    end
end)