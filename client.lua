

local isGarageOpen = false
local spawnedVehicles = {} -- Таблица для отслеживания созданных автомобилей

function ToggleGarage(state)
    isGarageOpen = state or not isGarageOpen
    SetNuiFocus(isGarageOpen, isGarageOpen)
    SendNUIMessage({
        action = "toggleGarage",
        show = isGarageOpen
    })
end

RegisterCommand('cargar', function()
    if isGarageOpen then
        ToggleGarage(false)
    else
        TriggerServerEvent('garage:serverRequestCars')
    end
end, false)

local function IsPlayerVehicle(vehicle)
    return GetPedInVehicleSeat(vehicle, -1) == PlayerPedId()
end

local function DeleteSpawnedVehicles()
    for plate, vehicle in pairs(spawnedVehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
        spawnedVehicles[plate] = nil
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteSpawnedVehicles()
    end
end)

RegisterNetEvent('garage:clientSaveVehicle')
AddEventHandler('garage:clientSaveVehicle', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        TriggerEvent('chat:addMessage', {
            args = {'^1Гараж', 'Вы должны быть в автомобиле!'}
        })
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if not IsPlayerVehicle(vehicle) then
        TriggerEvent('chat:addMessage', {
            args = {'^1Гараж', 'Вы должны быть владельцем транспортного средства!'}
        })
        return
    end

    SetVehicleModKit(vehicle, 0)
    local model = GetEntityModel(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if vehicleName == "NULL" then
        vehicleName = "Автомобиль "..plate
    end

    local mods = {
        colors = {
            primary = {GetVehicleCustomPrimaryColour(vehicle)} or {},
            secondary = {GetVehicleCustomSecondaryColour(vehicle)} or {},
            pearlescent = {GetVehicleColours(vehicle)},
            wheel = {GetVehicleExtraColours(vehicle)}
        },
        neon = {
            enabled = {
                IsVehicleNeonLightEnabled(vehicle, 0),
                IsVehicleNeonLightEnabled(vehicle, 1),
                IsVehicleNeonLightEnabled(vehicle, 2),
                IsVehicleNeonLightEnabled(vehicle, 3)
            },
            color = {GetVehicleNeonLightsColour(vehicle)}
        },
        extras = {},
        mods = {},
        windows = {},
        tyres = {},
        dirt = GetVehicleDirtLevel(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        tankHealth = GetVehiclePetrolTankHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        wheelType = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        tyreSmokeColor = {GetVehicleTyreSmokeColor(vehicle)},
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle)
    }

    for i=0, 20 do
        if DoesExtraExist(vehicle, i) then
            mods.extras[i] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end
    for i=0, 49 do
        mods.mods[i] = GetVehicleMod(vehicle, i)
    end

    mods.mods[18] = GetVehicleMod(vehicle, 18) -- Turbo
    mods.mods[22] = GetVehicleMod(vehicle, 22) -- Xenon
    mods.mods[23] = GetVehicleMod(vehicle, 23) -- Front wheels
    mods.mods[24] = GetVehicleMod(vehicle, 24) -- Rear wheels

    for i=0, 7 do
        mods.windows[i] = IsVehicleWindowIntact(vehicle, i)
    end
    for i=0, 5 do
        mods.tyres[i] = IsVehicleTyreBurst(vehicle, i, false)
    end

    local vehicleData = {
        model = model,
        name = vehicleName,
        plate = plate,
        class = GetVehicleClass(vehicle),
        driveType = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront") > 0.6 and "fwd"
                    or GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront") < 0.4 and "rwd" or "awd",
        power = math.floor(GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce") * 100),
        acceleration = math.floor(GetVehicleModelAcceleration(model) * 100) / 100,
        mods = mods
    }

    TriggerServerEvent('garage:serverSaveVehicle', vehicleData)
end)

RegisterNetEvent('garage:clientShowCars')
AddEventHandler('garage:clientShowCars', function(cars)
    SendNUIMessage({
        action = "updateCars",
        cars = cars
    })
    ToggleGarage(true)
end)

RegisterNetEvent('garage:clientSpawnCar')
AddEventHandler('garage:clientSpawnCar', function(model, plate, mods)
    if spawnedVehicles[plate] and DoesEntityExist(spawnedVehicles[plate]) then
        TriggerEvent('chat:addMessage', {
            args = {'^1Гараж', 'Этот автомобиль уже создан!'}
        })
        return
    end

    local count = 0
    for _, v in pairs(spawnedVehicles) do
        if DoesEntityExist(v) then count = count + 1 end
    end
    if count >= 3 then
        TriggerEvent('chat:addMessage', {
            args = {'^1Гараж', 'Вы уже создали максимум 3 автомобиля!'}
        })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleModKit(vehicle, 0)
    SetVehicleNumberPlateText(vehicle, plate)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleOnGroundProperly(vehicle)

    if mods then
        SetVehicleCustomPrimaryColour(vehicle, table.unpack(mods.colors.primary))
        SetVehicleCustomSecondaryColour(vehicle, table.unpack(mods.colors.secondary))
        SetVehicleColours(vehicle, table.unpack(mods.colors.pearlescent))
        SetVehicleExtraColours(vehicle, table.unpack(mods.colors.wheel))
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, mods.neon.enabled[i+1])
        end
        SetVehicleNeonLightsColour(vehicle, table.unpack(mods.neon.color))
        for extra, enabled in pairs(mods.extras) do
            SetVehicleExtra(vehicle, extra, enabled and 0 or 1)
        end
        for modType, modIndex in pairs(mods.mods) do
            SetVehicleMod(vehicle, tonumber(modType), modIndex, false)
        end


        if mods.mods[18] and mods.mods[18] ~= -1 then
            ToggleVehicleMod(vehicle, 18, true)
        end
        if mods.mods[22] and mods.mods[22] ~= -1 then
            ToggleVehicleMod(vehicle, 22, true)
        end

        for window, intact in pairs(mods.windows) do
            if not intact then
                SmashVehicleWindow(vehicle, window)
            end
        end
        for tyre, burst in pairs(mods.tyres) do
            if burst then
                SetVehicleTyreBurst(vehicle, tyre, true, 1000.0)
            end
        end
        SetVehicleDirtLevel(vehicle, mods.dirt or 0.0)
        SetVehicleEngineHealth(vehicle, mods.engineHealth or 1000.0)
        SetVehicleBodyHealth(vehicle, mods.bodyHealth or 1000.0)
        SetVehiclePetrolTankHealth(vehicle, mods.tankHealth or 1000.0)
        SetVehicleFuelLevel(vehicle, mods.fuelLevel or 100.0)
        SetVehicleWheelType(vehicle, mods.wheelType or 0)
        SetVehicleWindowTint(vehicle, mods.windowTint or 0)
        SetVehicleTyreSmokeColor(vehicle, table.unpack(mods.tyreSmokeColor))
        SetVehicleNumberPlateTextIndex(vehicle, mods.plateIndex or 0)
        SetVehicleXenonLightsColor(vehicle, mods.xenonColor or 0)
    end

    spawnedVehicles[plate] = vehicle
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(model)
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10000)
        for plate, vehicle in pairs(spawnedVehicles) do
            if DoesEntityExist(vehicle) then
                if GetEntityHealth(vehicle) <= 0 or GetVehicleEngineHealth(vehicle) <= 0 then
                    DeleteEntity(vehicle)
                    spawnedVehicles[plate] = nil
                end
            else
                spawnedVehicles[plate] = nil
            end
        end
    end
end)

RegisterNUICallback('closeGarage', function(_, cb)
    ToggleGarage(false)
    cb({})
end)

RegisterNUICallback('spawnCar', function(data, cb)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        TriggerEvent('chat:addMessage', {
            args = {'^1Гараж', 'Сначала выйдите из текущего автомобиля!'}
        })
        cb({})
        return
    end

    if not data.model or not data.plate then
        print("^1[Гараж-Клиент] Ошибка: неверные данные для спавна")
        cb({})
        return
    end

    TriggerServerEvent('garage:serverPrepareSpawnCar', tonumber(data.model), data.plate)
    ToggleGarage(false)
    cb({})
end)

RegisterNUICallback('deleteCar', function(data, cb)
    TriggerServerEvent('garage:serverDeleteCar', data.plate)
    cb({})
end)
