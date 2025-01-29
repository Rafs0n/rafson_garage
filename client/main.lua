local FW = {}

function GetClosestGarage()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestGarage = nil
    local closestDistance = Config.HideVehicleDistance

    for garageName, garageData in pairs(Config.Garages) do
        local garageCoords
        
        if garageData.target and garageData.target.custompedposition then
            garageCoords = vector3(garageData.target.pedposition.x, garageData.target.pedposition.y, garageData.target.pedposition.z)
        else
            garageCoords = garageData.blips.blippoint
        end

        local distance = #(playerCoords - garageCoords)

        if distance < closestDistance then
            closestGarage = garageName
            closestDistance = distance
        end
    end

    if closestGarage and closestDistance <= Config.HideVehicleDistance then
        return closestGarage
    end

    return nil
end



exports('GetClosestGarage', GetClosestGarage)




RegisterNetEvent('rafson_garage:openGarage')
AddEventHandler('rafson_garage:openGarage', function()
    local closestGarage = GetClosestGarage()
    if closestGarage then
        openGarage(closestGarage)
    end
end)

CreateThread(function()
    if Config.Framework == 'ESX' then
        FW.Object = exports["es_extended"]:getSharedObject()
        FW.TriggerServerCallback = function(name, cb, ...)
            FW.Object.TriggerServerCallback(name, cb, ...)
        end
        FW.GetVehicles = function()
            return FW.Object.Game.GetVehicles()
        end
        FW.GetVehiclesInArea = function(coords, radius)
            return FW.Object.Game.GetVehiclesInArea(coords, radius)
        end
        FW.SetVehicleProperties = function(vehicle, props)
            FW.Object.Game.SetVehicleProperties(vehicle, props)
        end
        FW.SpawnVehicle = function(model, coords, heading, cb)
            FW.Object.Game.SpawnVehicle(model, coords, heading, cb)
        end
        FW.GetPlate = function(vehicle)
            local props = FW.Object.Game.GetVehicleProperties(vehicle)
            return props and props.plate or ""
        end
        FW.GetVehicleModelName = function(model)
            return GetDisplayNameFromVehicleModel(model)
        end
    elseif Config.Framework == 'QB' then
        FW.Object = exports['qb-core']:GetCoreObject()
        FW.TriggerServerCallback = function(name, cb, ...)
            FW.Object.Functions.TriggerCallback(name, cb, ...)
        end
        FW.GetVehicles = function()
            return GetGamePool('CVehicle')
        end
        FW.GetVehiclesInArea = function(coords, radius)
            local all = GetGamePool('CVehicle')
            local near = {}
            for _, v in ipairs(all) do
                if #(GetEntityCoords(v) - coords) <= radius then
                    table.insert(near, v)
                end
            end
            return near
        end
        FW.SetVehicleProperties = function(vehicle, props)
            FW.Object.Functions.SetVehicleProperties(vehicle, props)
        end
        FW.SpawnVehicle = function(model, plate, coords, heading, cb)
            local m = type(model) == 'string' and joaat(model) or model
            RequestModel(m)
            while not HasModelLoaded(m) do Wait(0) end
            local veh = CreateVehicle(m, coords.x, coords.y, coords.z, heading, true, false)
            local netId = NetworkGetNetworkIdFromEntity(veh)
            SetNetworkIdCanMigrate(netId, true)
            SetEntityAsMissionEntity(veh, true, true)
            SetVehicleOnGroundProperly(veh)
            SetVehicleNumberPlateText(veh, plate)
            if cb then cb(veh) end
        end
        FW.GetPlate = function(vehicle)
            return GetVehicleNumberPlateText(vehicle) or ""
        end
        FW.GetVehicleModelName = function(model)
            return model
        end
    end
end)



function _U(key)
    local l = Config.Locale or 'en'
    return (Locales[l] and Locales[l][key]) or key
end

CreateThread(function()
    while not FW.Object do
        Wait(50)
    end

    for k, g in pairs(Config.Garages) do
        if g.blips.showBlip then
            local b = AddBlipForCoord(g.blips.blippoint)
            SetBlipSprite(b, g.blips.blipsprite)
            SetBlipDisplay(b, 4)
            SetBlipScale(b, g.blips.blipscale)
            SetBlipColour(b, g.blips.blipcolour)
            SetBlipAsShortRange(b, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(g.blips.label)
            EndTextCommandSetBlipName(b)
        end

        if Config.UsePedInteraction then
            RequestModel(g.target.PedModel)
            while not HasModelLoaded(g.target.PedModel) do
                Wait(50)
            end

            local pedPos = g.target.custompedposition and g.target.pedposition
                or vector4(g.blips.blippoint.x, g.blips.blippoint.y, g.blips.blippoint.z, 90.0)

            local ped = CreatePed(4, g.target.PedModel, pedPos.x, pedPos.y, pedPos.z - 1.0, pedPos.w, false, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatMovement(ped, 0)
            SetPedCombatRange(ped, 0)
            if Config.Target == 'ox' then
                exports.ox_target:addLocalEntity(ped, {
                    {
                        name = 'open_garage_'..k,
                        label = g.target.label or 'Otwórz garaż',
                        icon = g.target.icon or 'fas fa-warehouse',
                        distance = g.target.distance or 2.5,
                        onSelect = function()
                            openGarage(k)
                        end
                    }
                })
            elseif Config.Target == 'qb' then
                exports['qb-target']:AddTargetEntity(ped, {
                    options = {
                        {
                            type = "client",
                            icon = g.target.icon or 'fas fa-warehouse',
                            label = g.target.label or 'Otwórz garaż',
                            action = function()
                                openGarage(k)
                            end
                        },
                    },
                    distance = g.target.distance or 2.5
                })
            end
        end
    end
end)

RegisterNetEvent('rafson_garage:client:openGarage', function(data)
    local garage = Getclosestgara
end)


function IsVehicleWithPlateOnMap(plate)
    local all = FW.GetVehicles()
    for _, veh in ipairs(all) do
        if FW.GetPlate(veh) == plate then
            return true
        end
    end
    return false
end

function GetClosestVehicleWithPlate(plate, radius)
    local coords = GetEntityCoords(PlayerPedId())
    local near = FW.GetVehiclesInArea(coords, radius)
    for _, veh in ipairs(near) do
        if FW.GetPlate(veh) == plate then
            return veh
        end
    end
    return 0
end

function FindFreeParkingSpot(points)
    if not points then return nil end
    for _, p in ipairs(points) do
        if not IsAnyVehicleNearPoint(p.x, p.y, p.z, 2.0) then
            return { x = p.x, y = p.y, z = p.z, w = p.w }
        end
    end
    return nil
end

function GetVehicleModelName(model)
    local fullName = GetLabelText(GetDisplayNameFromVehicleModel(model) or _U('unknown'))
    local nameParts = {}
    for word in fullName:gmatch("%S+") do
        table.insert(nameParts, word)
    end

    if #nameParts > 1 then
        return nameParts[#nameParts - 1] .. " " .. nameParts[#nameParts]
    else
        return nameParts[1] or _U('unknown')
    end
end


function openGarage(name)
    if not name then return end

    if name == "depot" then
        FW.TriggerServerCallback('rafson_garage:getImpoundedVehicles', function(vehicles)
            local out = {}
            for _, veh in ipairs(vehicles) do
                local props = veh.vehicleProps
                local reallyImpounded = true

                if Config.ImpoundCheckMode and veh.stored == 0 then
                    if IsVehicleWithPlateOnMap(veh.plate) then
                        reallyImpounded = false
                    end
                elseif veh.stored ~= 0 then
                    reallyImpounded = false
                end


                if reallyImpounded then
                    table.insert(out, {
                        plate        = veh.plate,
                        vin          = veh.vin or _U('none'),
                        name         = GetVehicleModelName(veh.model),
                        model        = FW.GetVehicleModelName(veh.model),
                        bodyHealth   = veh.bodyHealth,
                        engineHealth = veh.engineHealth,
                        fuelLevel    = veh.fuelLevel,
                        stored       = false,
                        impounded    = true,
                        status       = "impounded",
                        favorite     = veh.favorite or 0
                    })
                end
            end

            if #out == 0 then
                Config.Notify(_U('no_vehicle')) 
                return
            end

            SetNuiFocus(true, true)
            SendNUIMessage({
                action   = 'openGarage',
                type     = 'impound',
                garage   = name,
                locales  = Locales[Config.Locale],
                showVin  = Config.ShowVIN,
                vehicles = out
            })
        end)

    else
        FW.TriggerServerCallback('rafson_garage:getPlayerVehicles', function(vehicles)
            local out = {}
            for _, veh in ipairs(vehicles) do
                local st = 'out'
                if veh.stored == 1 then
                    st = 'stored'
                elseif veh.stored == 2 then
                    st = 'impounded'
                end

                if Config.ImpoundCheckMode and st == 'out' then
                    if not IsVehicleWithPlateOnMap(veh.plate) then
                        st = 'impounded'
                    end
                end
                table.insert(out, {
                    plate        = veh.plate,
                    vin          = veh.vin or _U('none'),
                    name         = GetVehicleModelName(veh.model),
                    model        = FW.GetVehicleModelName(veh.model),
                    bodyHealth   = veh.bodyHealth,
                    engineHealth = veh.engineHealth,
                    fuelLevel    = veh.fuelLevel,
                    stored       = (st == "stored"),
                    impounded    = (st == "impounded"),
                    status       = st,
                    favorite     = veh.favorite or 0
                })
            end

            if #out == 0 then
                Config.Notify(_U('no_vehicle')) 
                return
            end

            SetNuiFocus(true, true)
            SendNUIMessage({
                action   = 'openGarage',
                type     = 'garage',
                garage   = name,
                locales  = Locales[Config.Locale],
                showVin  = Config.ShowVIN,
                vehicles = out
            })
        end)
    end
end





RegisterNUICallback('closeGarage', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeGarage' })
end)

RegisterNUICallback('withdrawVehicle', function(data, cb)
    if not Config.AllowVehicleSpawnInVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
        Config.Notify(_U('already_in_vehicle'))
        cb({ success = false })
        return
    end

    if Config.Framework == 'ESX' then
        FW.TriggerServerCallback('rafson_garage:spawnVehicle', function(resp)
            if resp and resp.success then
                local spot = FindFreeParkingSpot(Config.Garages[data.garage].spawnPoint)
                if spot then
                    FW.SpawnVehicle(resp.vehicleProps.model, vector3(spot.x, spot.y, spot.z), spot.w, function(vehicle)
                        if DoesEntityExist(vehicle) then
                            Config.SetVehicleFuel(vehicle, resp.fuel)
                            FW.SetVehicleProperties(vehicle, resp.vehicleProps)
                            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                            GivePlayerVehicleKeys(resp.vehicleProps.plate)
                            Config.Notify(_U('vehicle_taken_out'))
                            cb({ success = true })
                        else
                            Config.Notify(_U('spawn_failed'))
                            cb({ success = false })
                        end
                    end)
                else
                    Config.Notify(_U('no_parking_spots'))
                    cb({ success = false })
                end
            else
                Config.Notify(_U('failed_take_out'))
                cb({ success = false })
            end
        end, data.plate, data.garage)
    else
        FW.TriggerServerCallback('rafson_garage:spawnVehicle', function(resp)
            if resp and resp.success then
                local spot = FindFreeParkingSpot(Config.Garages[data.garage].spawnPoint)
                if spot then
                    if resp.vehicleData then
                        FW.SpawnVehicle(resp.vehicleData.model, resp.vehicleData.plate, vector3(spot.x, spot.y, spot.z), spot.w, function(vehicle)
                            if DoesEntityExist(vehicle) then
                                FW.SetVehicleProperties(vehicle, resp.vehicleData.vehicleProps)
                                Config.SetVehicleFuel(vehicle, resp.fuel)
                                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                                GivePlayerVehicleKeys(resp.vehicleData.plate)
                                Config.Notify(_U('vehicle_taken_out'))
                                cb({ success = true })
                            else
                                Config.Notify(_U('spawn_failed'))
                                cb({ success = false })
                            end
                        end)
                    else
                        Config.Notify(_U('invalid_vehicle_data'))
                        cb({ success = false })
                    end
                else
                    Config.Notify(_U('no_parking_spots'))
                    cb({ success = false })
                end
            else
                Config.Notify(_U('failed_take_out'))
                cb({ success = false })
            end
        end, data.plate, data.garage)
    end
end)



RegisterNUICallback('storeVehicle', function(data, cb)
    local g = Config.Garages[data.garage]
    if not g then
        Config.Notify(_U('garage_config_error'))
        cb({ success = false })
        return
    end
    local storeCoords = g.target and g.target.custompedposition
        and vector3(g.target.pedposition.x, g.target.pedposition.y, g.target.pedposition.z)
        or g.blips.blippoint

    if not storeCoords then
        Config.Notify(_U('garage_no_coords'))
        cb({ success = false })
        return
    end

    local found = GetClosestVehicleWithPlate(data.plate, 30.0)
    if found == 0 then
        Config.Notify(_U('vehicle_not_found'))
        cb({ success = false })
        return
    end

    local dist = #(GetEntityCoords(found) - storeCoords)
    if dist > Config.HideVehicleDistance then
        Config.Notify(_U('vehicle_too_far'))
        cb({ success = false })
        return
    end

    local fuelLevel = Config.GetVehicleFuel(found)
    
    FW.TriggerServerCallback('rafson_garage:storeVehicle', function(resp)
        if resp.success then
            Config.Notify(_U('vehicle_stored'))
            DeleteVehicle(found)
            RemovePlayerVehicleKeys(data.plate)
        else
            Config.Notify(_U('failed_store'))
        end

        cb(resp)
    end, data.plate, data.garage, fuelLevel)
end)


RegisterNUICallback('retrieveImpoundedVehicle', function(data, cb)
    if not Config.AllowVehicleSpawnInVehicle and IsPedInAnyVehicle(PlayerPedId(), false) then
        Config.Notify(_U('already_in_vehicle'))
        cb({ success = false })
        return
    end

    if Config.Framework == 'ESX' then
        FW.TriggerServerCallback('rafson_garage:retrieveImpoundedVehicle', function(resp)
            if resp and resp.success then
                local spot = FindFreeParkingSpot(Config.Garages[data.garage].spawnPoint)
                if spot then
                    FW.SpawnVehicle(resp.vehicleProps.model, vector3(spot.x, spot.y, spot.z), spot.w, function(vehicle)
                        if DoesEntityExist(vehicle) then
                            Config.SetVehicleFuel(vehicle, resp.fuel)
                            FW.SetVehicleProperties(vehicle, resp.vehicleProps)
                            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                            GivePlayerVehicleKeys(resp.vehicleProps.plate)
                            Config.Notify(_U('vehicle_from_imp'))
                            cb({ success = true })
                        else
                            Config.Notify(_U('spawn_failed'))
                            cb({ success = false })
                        end
                    end)
                else
                    Config.Notify(_U('no_spots_imp'))
                    cb({ success = false })
                end
            else
                if resp and resp.reason == 'nomoney' then
                    Config.Notify(_U('not_enough_money'))
                else
                    Config.Notify(_U('failed_impound'))
                end
                cb({ success = false })
            end
        end, data.plate, data.garage)
    else
        FW.TriggerServerCallback('rafson_garage:retrieveImpoundedVehicle', function(resp)
            if resp and resp.success then
                local spot = FindFreeParkingSpot(Config.Garages[data.garage].spawnPoint)
                if spot then
                    if resp.vehicleData then
                        FW.SpawnVehicle(resp.vehicleData.model, resp.vehicleData.plate, vector3(spot.x, spot.y, spot.z), spot.w, function(vehicle)
                            if DoesEntityExist(vehicle) then
                                Config.SetVehicleFuel(vehicle, resp.fuel)
                                FW.SetVehicleProperties(vehicle, resp.vehicleData.vehicleProps)
                                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                                GivePlayerVehicleKeys(resp.vehicleData.plate)
                                Config.Notify(_U('vehicle_from_imp'))
                                cb({ success = true })
                            else
                                Config.Notify(_U('spawn_failed'))
                                cb({ success = false })
                            end
                        end)
                    else
                        Config.Notify(_U('invalid_vehicle_data'))
                        cb({ success = false })
                    end
                else
                    Config.Notify(_U('no_spots_imp'))
                    cb({ success = false })
                end
            else
                if resp and resp.reason == 'nomoney' then
                    Config.Notify(_U('not_enough_money'))
                else
                    Config.Notify(_U('failed_impound'))
                end
                cb({ success = false })
            end
        end, data.plate, data.garage)        
    end
end)


RegisterNUICallback('setFavorite', function(data, cb)
    FW.TriggerServerCallback('rafson_garage:setFavorite', function(ok)
        cb({ success = ok })
    end, data.plate, data.favorite)
end)
