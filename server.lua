
local carData = {}
local dataFilePath = "garage_data.json"

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    local file = LoadResourceFile(resourceName, dataFilePath)
    if file then
        carData = json.decode(file) or {}
    else
        carData = {}
        SaveResourceFile(resourceName, dataFilePath, json.encode(carData), -1)
    end
end)


local function SaveCarData()
    SaveResourceFile(GetCurrentResourceName(), dataFilePath, json.encode(carData), -1)
end


RegisterCommand('savecar', function(source)
    TriggerClientEvent('garage:clientSaveVehicle', source)
end, false)


RegisterNetEvent('garage:serverSaveVehicle')
AddEventHandler('garage:serverSaveVehicle', function(vehicleData)
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    if not playerId then return end

    carData[playerId] = carData[playerId] or {}
    

    for i, v in ipairs(carData[playerId]) do
        if v.plate == vehicleData.plate then
            carData[playerId][i] = vehicleData
            SaveCarData()
            TriggerClientEvent('chat:addMessage', src, {
                args = {'^2Гараж', 'Автомобиль '..vehicleData.name..' обновлен!'}
            })
            return
        end
    end


    table.insert(carData[playerId], vehicleData)
    SaveCarData()

    TriggerClientEvent('chat:addMessage', src, {
        args = {'^2Гараж', 'Автомобиль '..vehicleData.name..' сохранен!'}
    })
end)


RegisterNetEvent('garage:serverDeleteCar')
AddEventHandler('garage:serverDeleteCar', function(plate)
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    if not carData[playerId] then return end
    
    for i, v in ipairs(carData[playerId]) do
        if v.plate == plate then
            table.remove(carData[playerId], i)
            SaveCarData()
            TriggerClientEvent('chat:addMessage', src, {
                args = {'^2Гараж', 'Автомобиль '..v.name..' удален!'}
            })
            TriggerClientEvent('garage:clientShowCars', src, carData[playerId] or {})
            break
        end
    end
end)


RegisterNetEvent('garage:serverRequestCars')
AddEventHandler('garage:serverRequestCars', function()
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    TriggerClientEvent('garage:clientShowCars', src, carData[playerId] or {})
end)


RegisterNetEvent('garage:serverPrepareSpawnCar')
AddEventHandler('garage:serverPrepareSpawnCar', function(model, plate)
    local src = source
    local playerId = GetPlayerIdentifier(src, 0)
    if not carData[playerId] then return end
    

    for _, v in pairs(carData[playerId]) do
        if v.model == model and v.plate == plate then
            -- Отправляем данные для спавна
            TriggerClientEvent('garage:clientSpawnCar', src, model, plate, v.mods)
            return
        end
    end
end)