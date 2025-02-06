local FW = {}
if Config.Framework == 'ESX' then
    ESX = exports["es_extended"]:getSharedObject()
    FW.GetPlayerFromId = function(id)
        return ESX.GetPlayerFromId(id)
    end
    FW.GetIdentifier = function(xPlayer)
        return xPlayer.identifier
    end
    FW.RemoveMoney = function(xPlayer, amount)
        xPlayer.removeMoney(amount)
    end
elseif Config.Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
    FW.GetPlayerFromId = function(id)
        return QBCore.Functions.GetPlayer(id)
    end
    FW.GetIdentifier = function(xPlayer)
        return xPlayer.PlayerData.citizenid
    end
    FW.RemoveMoney = function(xPlayer, amount)
        xPlayer.Functions.RemoveMoney('cash', amount, 'Impound')
    end
end

if Config.Framework == 'ESX' then
    ESX.RegisterServerCallback('rafson_garage:getPlayerVehicles', function(source, cb)
        local x = FW.GetPlayerFromId(source)
        if not x then cb({}) return end
        MySQL.Async.fetchAll('SELECT plate, vehicle, vin, stored, favorite FROM owned_vehicles WHERE owner = @owner', {
            ['@owner'] = FW.GetIdentifier(x)
        }, function(res)
            local vehicles = {}
            for _, r in ipairs(res) do
                local p = json.decode(r.vehicle) or {}
                local bodyHealth = p.bodyHealth and math.floor(p.bodyHealth / 10) or 100
                local engineHealth = p.engineHealth and math.floor(p.engineHealth / 10) or 100
                local fuelLevel = p.fuelLevel and math.floor(p.fuelLevel) or 100
                table.insert(vehicles, {
                    plate = r.plate,
                    vin = r.vin or 'N/A',
                    vehicleProps = p,
                    model = p.model or "unknown",
                    bodyHealth = bodyHealth,
                    engineHealth = engineHealth,
                    fuelLevel = fuelLevel,
                    stored = r.stored,
                    favorite = r.favorite or 0
                })
            end
            cb(vehicles)
        end)
    end)

    ESX.RegisterServerCallback('rafson_garage:setFavorite', function(source, cb, plate, fav)
        local x = FW.GetPlayerFromId(source)
        if not x then cb(false) return end
        MySQL.Async.execute('UPDATE owned_vehicles SET favorite = @fav WHERE owner = @owner AND plate = @plate', {
            ['@fav'] = fav,
            ['@owner'] = FW.GetIdentifier(x),
            ['@plate'] = plate
        }, function(rows)
            cb(rows > 0)
        end)
    end)

    ESX.RegisterServerCallback('rafson_garage:getImpoundedVehicles', function(source, cb)
        local x = FW.GetPlayerFromId(source)
        if not x then cb({}) return end
        local query = ''
        if Config.ImpoundCheckMode then
            query = 'SELECT plate, vehicle, vin, stored, favorite FROM owned_vehicles WHERE owner = @owner AND stored != 2'
        else
            query = 'SELECT plate, vehicle, vin, stored, favorite FROM owned_vehicles WHERE owner = @owner AND stored = 2'
        end
        MySQL.Async.fetchAll(query, { ['@owner'] = FW.GetIdentifier(x) }, function(res)
            local vehicles = {}
            for _, r in ipairs(res) do
                local p = json.decode(r.vehicle) or {}
                local bodyHealth = p.bodyHealth and math.floor(p.bodyHealth / 10) or 100
                local engineHealth = p.engineHealth and math.floor(p.engineHealth / 10) or 100
                local fuelLevel = p.fuelLevel and math.floor(p.fuelLevel) or 100
                table.insert(vehicles, {
                    plate = r.plate,
                    vin = r.vin or 'N/A',
                    vehicleProps = p,
                    model = p.model or "unknown",
                    bodyHealth = bodyHealth,
                    engineHealth = engineHealth,
                    fuelLevel = fuelLevel,
                    stored = r.stored,
                    favorite = r.favorite or 0
                })
            end
            cb(vehicles)
        end)
    end)

    ESX.RegisterServerCallback('rafson_garage:spawnVehicle', function(source, cb, plate, garage)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then
            cb({ success = false, reason = 'player_not_found' })
            return
        end
        MySQL.Async.fetchAll('SELECT owner, vehicle FROM owned_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        }, function(data)
            if not data or #data == 0 then
                cb({ success = false, reason = 'not_found' })
                return
            end
            local row = data[1]
            if row.owner ~= xPlayer.identifier then
                cb({ success = false, reason = 'not_owner' })
                return
            end
            local vehicleData = json.decode(row.vehicle)
            if not vehicleData then
                cb({ success = false, reason = 'invalid_json' })
                return
            end
            local fuel = vehicleData.fuelLevel or 100
            MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0 WHERE plate = @plate', {
                ['@plate'] = plate
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    cb({ success = true, vehicleProps = vehicleData, fuel = fuel })
                else
                    cb({ success = false, reason = 'update_failed' })
                end
            end)
        end)
    end)

    ESX.RegisterServerCallback('rafson_garage:storeVehicle', function(source, cb, plate, garage, fuelLevel, vehicleProps)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then
            cb({ success = false })
            return
        end
        
        MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        }, function(result)
            if not result or #result == 0 then
                cb({ success = false })
                return
            end
            
            local row = result[1]
            if row.owner ~= xPlayer.identifier then
                cb({ success = false })
                return
            end
            
            local newProps = {}
            if fuelLevel then
                newProps.fuelLevel = fuelLevel
            end
            if vehicleProps then
                newProps = vehicleProps
            end
            
            local newJson = json.encode(newProps)
            
            MySQL.Async.execute('UPDATE owned_vehicles SET stored = 1, vehicle = @veh WHERE plate = @plate', {
                ['@veh'] = newJson,
                ['@plate'] = plate
            }, function(rowsChanged)
                if rowsChanged > 0 then
                    cb({ success = true })
                else
                    cb({ success = false })
                end
            end)
        end)
    end)
    

    ESX.RegisterServerCallback('rafson_garage:retrieveImpoundedVehicle', function(source, cb, plate, garage)
        local x = FW.GetPlayerFromId(source)
        local impoundFee = 250
        if not x then cb({ success = false }) return end
        if x.getMoney() >= impoundFee then
            MySQL.Async.fetchAll('SELECT vehicle FROM owned_vehicles WHERE plate = @pl AND owner = @o', {
                ['@pl'] = plate,
                ['@o'] = FW.GetIdentifier(x)
            }, function(data)
                if data and #data > 0 then
                    local vehicleData = json.decode(data[1].vehicle)
                    local fuel = vehicleData.fuelLevel or 100
                    MySQL.Async.execute('UPDATE owned_vehicles SET stored = 0 WHERE plate = @pl', { ['@pl'] = plate }, function(rows)
                        if rows > 0 then
                            x.removeMoney(impoundFee)
                            cb({ success = true, vehicleProps = vehicleData, fuel = fuel })
                        else
                            cb({ success = false })
                        end
                    end)
                else
                    cb({ success = false })
                end
            end)
        else
            cb({ success = false, reason = 'nomoney' })
        end
    end)
elseif Config.Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
    QBCore.Functions.CreateCallback('rafson_garage:getPlayerVehicles', function(source, cb)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            cb({})
            return
        end
        local citizenid = Player.PlayerData.citizenid
        MySQL.Async.fetchAll('SELECT plate, mods, state, favorite, vehicle, vin, fuel, engine, body FROM player_vehicles WHERE citizenid = @citizenid', {
            ['@citizenid'] = citizenid
        }, function(res)
            local vehicles = {}
            for _, row in ipairs(res) do
                local p = json.decode(row.mods) or {}
                table.insert(vehicles, {
                    plate = row.plate,
                    vin = row.vin or 'N/A',
                    vehicleProps = p,
                    model = row.vehicle or "unknown",
                    bodyHealth = row.body and math.floor(row.body / 10) or 100,
                    engineHealth = row.engine and math.floor(row.engine / 10) or 100,
                    fuelLevel = row.fuel and math.floor(row.fuel) or 100,
                    stored = row.state,
                    favorite = row.favorite or 0
                })
            end
            cb(vehicles)
        end)
    end)

    QBCore.Functions.CreateCallback('rafson_garage:setFavorite', function(source, cb, plate, fav)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            cb(false)
            return
        end
        local citizenid = Player.PlayerData.citizenid
        MySQL.Async.execute('UPDATE player_vehicles SET favorite = @fav WHERE citizenid = @cid AND plate = @plate', {
            ['@fav'] = fav,
            ['@cid'] = citizenid,
            ['@plate'] = plate
        }, function(rows)
            cb(rows > 0)
        end)
    end)

    QBCore.Functions.CreateCallback('rafson_garage:getImpoundedVehicles', function(source, cb)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            cb({})
            return
        end
        local citizenid = Player.PlayerData.citizenid
        if Config.ImpoundCheckMode then
            MySQL.Async.fetchAll('SELECT plate, mods, state, favorite, vehicle, vin, fuel, engine, body FROM player_vehicles WHERE citizenid = @cid AND state != 2', {
                ['@cid'] = citizenid
            }, function(res)
                local vehicles = {}
                for _, row in ipairs(res) do
                    local p = json.decode(row.mods) or {}
                    table.insert(vehicles, {
                        plate = row.plate,
                        vin = row.vin or 'N/A',
                        vehicleProps = p,
                        model = row.vehicle or "unknown",
                        bodyHealth = row.body and math.floor(row.body / 10) or 100,
                        engineHealth = row.engine and math.floor(row.engine / 10) or 100,
                        fuelLevel = row.fuel and math.floor(row.fuel) or 100,
                        stored = row.state,
                        impounded = (row.state == 2),
                        favorite = row.favorite or 0
                    })
                end
                cb(vehicles)
            end)
        else
            MySQL.Async.fetchAll('SELECT plate, mods, state, favorite, vehicle, vin, fuel, engine, body FROM player_vehicles WHERE citizenid = @cid AND state = 2', {
                ['@cid'] = citizenid
            }, function(res)
                local vehicles = {}
                for _, row in ipairs(res) do
                    local p = json.decode(row.mods) or {}
                    table.insert(vehicles, {
                        plate = row.plate,
                        vin = row.vin or 'N/A',
                        vehicleProps = p,
                        model = row.vehicle or "unknown",
                        bodyHealth = row.body and math.floor(row.body / 10) or 100,
                        engineHealth = row.engine and math.floor(row.engine / 10) or 100,
                        fuelLevel = row.fuel and math.floor(row.fuel) or 100,
                        stored = row.state,
                        impounded = (row.state == 2),
                        favorite = row.favorite or 0
                    })
                end
                cb(vehicles)
            end)
        end
    end)

    QBCore.Functions.CreateCallback('rafson_garage:storeVehicle', function(source, cb, plate, garage, fuelLevel, vehicleProps)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            cb({ success = false })
            return
        end
        local citizenid = Player.PlayerData.citizenid
        MySQL.Async.fetchScalar('SELECT citizenid FROM player_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        }, function(dbCitizenid)
            if dbCitizenid and dbCitizenid == citizenid then
                MySQL.Async.fetchAll('SELECT mods FROM player_vehicles WHERE plate = @plate', {
                    ['@plate'] = plate
                }, function(res)
                    if res and #res > 0 then
                        local oldData = json.decode(res[1].mods) or {}
                        if vehicleProps and vehicleProps.damageData then
                            oldData.damageData = vehicleProps.damageData
                        end
    
                        if fuelLevel then
                            oldData.fuelLevel = fuelLevel
                        end
    
                        local newMods = json.encode(oldData)

                        MySQL.Async.execute('UPDATE player_vehicles SET state = 1, fuel = @fuel, mods = @mods WHERE plate = @plate', {
                            ['@plate'] = plate,
                            ['@fuel'] = fuelLevel,
                            ['@mods'] = newMods
                        })
    
                        if vehicleProps and vehicleProps.engineHealth then
                            MySQL.Async.execute('UPDATE player_vehicles SET engine = @engineHealth WHERE plate = @plate', {
                                ['@plate'] = plate,
                                ['@engineHealth'] = vehicleProps.engineHealth
                            })
                        end
    
                        if vehicleProps and vehicleProps.bodyHealth then
                            MySQL.Async.execute('UPDATE player_vehicles SET body = @bodyHealth WHERE plate = @plate', {
                                ['@plate'] = plate,
                                ['@bodyHealth'] = vehicleProps.bodyHealth
                            })
                        end
    
                        cb({ success = true })
                    else
                        cb({ success = false })
                    end
                end)
            else
                cb({ success = false })
            end
        end)
    end)
    
    

    QBCore.Functions.CreateCallback('rafson_garage:spawnVehicle', function(source, cb, plate, garage)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            cb({ success = false })
            return
        end
        local citizenid = Player.PlayerData.citizenid
        MySQL.Async.fetchAll('SELECT mods, plate, vehicle, fuel FROM player_vehicles WHERE plate = @plate AND citizenid = @cid', {
            ['@plate'] = plate,
            ['@cid'] = citizenid
        }, function(result)
            if result and #result > 0 then
                local vehicleData = result[1]
                local props = json.decode(vehicleData.mods)
                if props then
                    MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = @plate', {
                        ['@plate'] = plate
                    }, function(rows)
                        if rows > 0 then
                            cb({ success = true, vehicleData = {
                                vehicleProps = props,
                                plate = vehicleData.plate,
                                model = vehicleData.vehicle,
                                fuel = vehicleData.fuel
                            }})
                        else
                            cb({ success = false })
                        end
                    end)
                else
                    cb({ success = false })
                end
            else
                cb({ success = false })
            end
        end)
    end)

    QBCore.Functions.CreateCallback('rafson_garage:retrieveImpoundedVehicle', function(source, cb, plate, garage)
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then
            cb({ success = false })
            return
        end
        local impoundFee = 250
        local cash = Player.PlayerData.money['cash'] or 0
        if cash >= impoundFee then
            MySQL.Async.fetchAll('SELECT mods, plate, vehicle, fuel FROM player_vehicles WHERE plate = @plate AND citizenid = @cid', {
                ['@plate'] = plate,
                ['@cid'] = Player.PlayerData.citizenid
            }, function(result)
                if result and #result > 0 then
                    local vehicleData = result[1]
                    local props = json.decode(vehicleData.mods)
                    if props then
                        MySQL.Async.execute('UPDATE player_vehicles SET state = 0 WHERE plate = @plate', {
                            ['@plate'] = plate
                        }, function(rows)
                            if rows > 0 then
                                Player.Functions.RemoveMoney('cash', impoundFee, 'Impound Fee')
                                cb({ success = true, vehicleData = {
                                    vehicleProps = props,
                                    plate = vehicleData.plate,
                                    model = vehicleData.vehicle,
                                    fuel = vehicleData.fuel
                                }})
                            else
                                cb({ success = false })
                            end
                        end)
                    else
                        cb({ success = false })
                    end
                else
                    cb({ success = false })
                end
            end)
        else
            cb({ success = false, reason = 'nomoney' })
        end
    end)
end


