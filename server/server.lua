local QBCore = exports['qb-core']:GetCoreObject()
local activeRides = {}
local blockedRehires = {}

local function getPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

local function getCitizenId(player)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end

local function blockRehire(player)
    local citizenId = getCitizenId(player)
    if citizenId then
        blockedRehires[citizenId] = true
    end
end

local function isRehireBlocked(player)
    local citizenId = getCitizenId(player)
    return citizenId and blockedRehires[citizenId] == true or false
end

local function isTaxiDriverOnDuty(player)
    return player
        and player.PlayerData
        and player.PlayerData.job
        and player.PlayerData.job.name == Config.Job.Name
        and player.PlayerData.job.onduty
end

local function clearRide(src)
    activeRides[src] = nil
end

local function ensureRatingTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS npc_taxi_ratings (
            citizenid VARCHAR(50) NOT NULL PRIMARY KEY,
            rating TINYINT UNSIGNED NOT NULL DEFAULT 1,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
end

local function savePlayerRating(player, rating)
    local citizenId = getCitizenId(player)
    if not citizenId then return end

    MySQL.insert.await(
        "INSERT INTO npc_taxi_ratings (citizenid, rating) VALUES (?, ?) ON DUPLICATE KEY UPDATE rating = VALUES(rating)",
        { citizenId, rating }
    )
end

local function deletePlayerRating(player)
    local citizenId = getCitizenId(player)
    if not citizenId then return end

    MySQL.query.await("DELETE FROM npc_taxi_ratings WHERE citizenid = ?", { citizenId })
end

local function loadPlayerRating(player)
    local citizenId = getCitizenId(player)
    if not citizenId then
        return Config.Rating.Start
    end

    local row = MySQL.single.await("SELECT rating FROM npc_taxi_ratings WHERE citizenid = ?", { citizenId })
    if row and row.rating then
        return math.max(Config.Rating.Min, math.min(Config.Rating.Max, tonumber(row.rating) or Config.Rating.Start))
    end

    savePlayerRating(player, Config.Rating.Start)
    return Config.Rating.Start
end

CreateThread(function()
    ensureRatingTable()
end)

RegisterNetEvent("npcTaxi:checkLicense", function(vehicle)
    local src = source
    local player = getPlayer(src)
    if not player then
        TriggerClientEvent("npcTaxi:licenseResult", src, false, vehicle)
        return
    end

    local metadata = player.PlayerData.metadata or {}
    local licenses = metadata["licences"] or metadata["licenses"] or {}
    local hasLicense = licenses[Config.Job.RequiredLicense] == true

    TriggerClientEvent("npcTaxi:licenseResult", src, hasLicense, vehicle)
end)

RegisterNetEvent("npcTaxi:startRide", function()
    local src = source
    local player = getPlayer(src)
    if not isTaxiDriverOnDuty(player) then
        clearRide(src)
        return
    end

    activeRides[src] = {
        startedAt = os.time()
    }
end)

RegisterNetEvent("npcTaxi:cancelRide", function()
    clearRide(source)
end)

RegisterNetEvent("npcTaxi:requestRating", function()
    local src = source
    local player = getPlayer(src)
    if not player or not player.PlayerData.job or player.PlayerData.job.name ~= Config.Job.Name then
        TriggerClientEvent("npcTaxi:setRating", src, Config.Rating.Start)
        return
    end

    local rating = loadPlayerRating(player)
    TriggerClientEvent("npcTaxi:setRating", src, rating)
end)

RegisterNetEvent("npcTaxi:updateRating", function(rating)
    local src = source
    local player = getPlayer(src)
    if not player or not player.PlayerData.job or player.PlayerData.job.name ~= Config.Job.Name then
        return
    end

    local normalizedRating = math.max(Config.Rating.Min, math.min(Config.Rating.Max, tonumber(rating) or Config.Rating.Start))
    savePlayerRating(player, normalizedRating)
end)

RegisterNetEvent("npcTaxi:completeRide", function(amount)
    local src = source
    local player = getPlayer(src)
    local ride = activeRides[src]

    if not isTaxiDriverOnDuty(player) or not ride then
        clearRide(src)
        TriggerClientEvent("npcTaxi:ridePaymentFailed", src)
        return
    end

    local rideSeconds = os.time() - ride.startedAt
    if rideSeconds < Config.Payout.MinRideSeconds then
        clearRide(src)
        TriggerClientEvent("npcTaxi:ridePaymentFailed", src)
        return
    end

    if type(amount) ~= "number" then
        clearRide(src)
        TriggerClientEvent("npcTaxi:ridePaymentFailed", src)
        return
    end

    local fare = math.floor(amount)
    fare = math.max(Config.Taximeter.MinFare, fare)
    fare = math.min(Config.Taximeter.MaxFare, fare)

    local tip = 0
    if math.random(1, 100) <= Config.Tips.ChancePercent then
        tip = math.random(Config.Tips.MinAmount, Config.Tips.MaxAmount)
    end

    local total = fare + tip
    player.Functions.AddMoney(Config.Payout.Account, total)
    clearRide(src)

    TriggerClientEvent("npcTaxi:ridePaid", src, fare, tip)
end)

-- NPC Calls the Police (RP Feature)
RegisterNetEvent("taxi:callPolice", function(coords)
    TriggerClientEvent("police:client:policeAlert", -1, coords)
end)
-- WHEN A PLAYER LEAVES THE SERVER, THEY ARE AUTOMATICALLY SET TO offDuty
AddEventHandler('playerDropped', function()
    local src = source
    local player = getPlayer(src)
    clearRide(src)
    if player and player.PlayerData.job.name == Config.Job.Name and Config.Job.ResetJobOnDisconnect then
        player.Functions.SetJobDuty(false)
    end
end)
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local player = getPlayer(src)
    clearRide(src)
    if player and player.PlayerData.job.name == Config.Job.Name then
        if Config.Job.ResetJobOnDisconnect then
            player.Functions.SetJobDuty(false)
        end

        local rating = loadPlayerRating(player)
        TriggerClientEvent("npcTaxi:setRating", src, rating)
    end
end)
------------------------------------------------------
--ACCEPT/CANCEL A TAXI JOB
------------------------------------------------------
RegisterNetEvent("npcTaxi:setJob", function()
    local src = source
    local player = getPlayer(src)
    if player then
        if isRehireBlocked(player) then
            TriggerClientEvent("npcTaxi:jobApplicationResult", src, false)
            return
        end

        player.Functions.SetJob(Config.Job.Name, Config.Job.Grade or 0)
        savePlayerRating(player, Config.Rating.Start)
        TriggerClientEvent("npcTaxi:setRating", src, Config.Rating.Start)
        TriggerClientEvent("npcTaxi:jobApplicationResult", src, true)
    end
end)
RegisterNetEvent("npcTaxi:removeJob", function()
    local src = source
    local player = getPlayer(src)
    clearRide(src)
    if player then
        blockRehire(player)
        deletePlayerRating(player)
        TriggerClientEvent("npcTaxi:setRating", src, Config.Rating.Start)
        player.Functions.SetJob("unemployed", 0)
    end
end)

RegisterNetEvent("npcTaxi:terminateEmployment", function()
    local src = source
    local player = getPlayer(src)
    clearRide(src)
    if player then
        blockRehire(player)
        deletePlayerRating(player)
        TriggerClientEvent("npcTaxi:setRating", src, Config.Rating.Start)
        player.Functions.SetJob("unemployed", 0)
        player.Functions.SetJobDuty(false)
    end
end)
