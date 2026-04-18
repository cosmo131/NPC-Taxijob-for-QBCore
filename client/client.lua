local QBCore = exports['qb-core']:GetCoreObject()

local taxiVeh = nil
local activeJob = false
local jobBlip = nil
local customerPed = nil
local customerPeds = {}
local spawningVehicle = false
local jobAccepted = false
local pendingPickup = nil
local pendingPassengerCount = 1
local jobTimeout = nil
local wrongWayTime = 0
local jobAcceptTime = nil
local pickupTimer = nil
local pickupWarning = false
local pickupWarningTime = Config.Timers.PickupWarning
local maxPickupTime = Config.Timers.PickupCancel
local maxRideTime = Config.Timers.RideTimeout
local licenseCheckPending = false
local acceptJobRequested = false
local originalDistance = 0
local debugBlips = {}
local debugLocationsEnabled = false
local employmentTerminated = false
local terminationVehicle = nil
local terminationMonitorActive = false
local cleanRideStreak = 0
local idleComplaintCount = 0
local AddRating
local RemoveRating
local StartTerminationSequence
--  GO AUTO OFF DUTY AFTER AFK
local missedJobs = 0
local maxMissedJobs = Config.JobLimits.MaxMissedJobs
-- RATING
local driverRating = Config.Rating.Start
local minRating = Config.Rating.Min
local maxRating = Config.Rating.Max
-- TAXAMETER
local meterActive = false
local distance = 0
local lastPos = nil
local currentFare = 0
local npcPassenger = false
local idleTimer = 0

--------------------------------------------------
-- RAING FUNKTION
--------------------------------------------------
local function PersistRating()
    TriggerServerEvent("npcTaxi:updateRating", driverRating)
end

local function UpdateRatingUI()
    SendNUIMessage({
        action = "updateRating",
        rating = driverRating
    })
end

local function GetDispatchChance()
    return math.max(0, math.min(1, driverRating / 100))
end

local function ResetCleanRideStreak()
    cleanRideStreak = 0
end

local function RegisterCleanRide()
    cleanRideStreak = cleanRideStreak + 1
    if cleanRideStreak >= Config.Rating.Bonus.CleanRideCount then
        cleanRideStreak = 0
        AddRating(Config.Rating.Bonus.CleanRidePoints)
        NotifyTaxi(_U("cleanRideBonus", Config.Rating.Bonus.CleanRidePoints))
    end
end

StartTerminationSequence = function()
    if employmentTerminated then
        return
    end

    employmentTerminated = true
    TriggerServerEvent("npcTaxi:terminateEmployment")
    NotifyTaxi(_U("firedBadRating"))

    if activeJob then
        CancelTaxiJob()
    else
        ResetTaxiJob()
        StopTaximeter()
    end

    if taxiVeh and DoesEntityExist(taxiVeh) then
        terminationVehicle = taxiVeh
        SetVehicleEngineOn(terminationVehicle, false, true, true)
        SetVehicleUndriveable(terminationVehicle, true)
        SetVehicleHandbrake(terminationVehicle, true)
        FreezeEntityPosition(terminationVehicle, true)
        NotifyTaxi(_U("leaveVehicleNow"))

        if not terminationMonitorActive then
            terminationMonitorActive = true
            CreateThread(function()
                local deadline = GetGameTimer() + Config.Termination.VehicleDespawnDelay
                while terminationVehicle and DoesEntityExist(terminationVehicle) do
                    Wait(1000)
                    local ped = PlayerPedId()
                    if GetGameTimer() >= deadline then
                        if IsPedInVehicle(ped, terminationVehicle, false) then
                            DeleteVehicle(terminationVehicle)
                            NotifyTaxi(_U("vehicleCollected"))
                            taxiVeh = nil
                        end
                        break
                    end
                end

                terminationVehicle = nil
                terminationMonitorActive = false
            end)
        end
    end
end

AddRating = function(amount)
    driverRating = math.min(maxRating, driverRating + amount)
    UpdateRatingUI()
    PersistRating()
end
RemoveRating = function(amount)
    driverRating = math.max(minRating, driverRating - amount)
    UpdateRatingUI()
    PersistRating()
    ResetCleanRideStreak()
    -- ⚠️ WARNING IF YOUR CREDIT SCORE IS LOW
    if driverRating <= Config.Rating.WarningThreshold then
        TaxiNotify(_U("badRating"))
    end
    if driverRating <= Config.Termination.Threshold then
        StartTerminationSequence()
    end
end
local function ResetRating()
    driverRating = Config.Rating.Start
    UpdateRatingUI()
    PersistRating()
end

local function GetActiveCustomerPeds()
    local activePeds = {}
    for _, ped in ipairs(customerPeds) do
        if ped and DoesEntityExist(ped) then
            activePeds[#activePeds + 1] = ped
        end
    end
    customerPeds = activePeds
    customerPed = customerPeds[1] or nil
    return activePeds
end

local function GetPassengerCountForRide()
    local passengers = GetActiveCustomerPeds()
    return math.max(1, #passengers)
end

local function ClearCustomerPeds(shouldDelete)
    local passengers = GetActiveCustomerPeds()
    for _, ped in ipairs(passengers) do
        if shouldDelete and DoesEntityExist(ped) then
            DeletePed(ped)
        end
    end

    customerPeds = {}
    customerPed = nil
end
--------------------------------------------------
--  SEATING ARRANGEMENT TEST
--------------------------------------------------
function HasAnyPassenger(vehicle)
    if not vehicle or vehicle == 0 then return false end
        -- Seat 0 = Driver → IGNORE
        -- Seat 1 = Passenger
        -- Seat 2 & 3 = at the back
        for i = 1, GetVehicleMaxNumberOfPassengers(vehicle) do
        local ped = GetPedInVehicleSeat(vehicle, i)
        if ped ~= 0 then
            return true
        end
    end
    return false
end
--------------------------------------------------
-- TAXI NOTIFY
--------------------------------------------------
function TaxiNotify(msg)
    SendNUIMessage({
        type = "show",
        text = msg
    })
end

local function NotifyTaxi(msg)
    TaxiNotify(msg)
end

RegisterNetEvent("taxi:notify", function(msg)
    TaxiNotify(msg)
end)

RegisterNetEvent("npcTaxi:setRating", function(rating)
    driverRating = math.max(minRating, math.min(maxRating, tonumber(rating) or Config.Rating.Start))
    UpdateRatingUI()
end)

RegisterNetEvent("npcTaxi:setShiftStats", function(todayMoney, rides)
    SendNUIMessage({
        action = "setShiftStats",
        today = math.max(0, tonumber(todayMoney) or 0),
        rides = math.max(0, tonumber(rides) or 0)
    })
end)

RegisterNetEvent("npcTaxi:jobApplicationResult", function(success)
    if success then
        acceptJobRequested = false
        employmentTerminated = false
        terminationVehicle = nil
        cleanRideStreak = 0
        TriggerServerEvent("npcTaxi:requestShiftStats")
        TaxiNotify(_U("welcomeToTaxicompany"))
        PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
        return
    end

    TaxiNotify(_U("rehiredAfterRestart"))
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
end)

RegisterCommand(Config.Keys.AcceptJobCommand, function()
    acceptJobRequested = true
end, false)

RegisterKeyMapping(Config.Keys.AcceptJobCommand, "Accept NPC taxi order", "keyboard", Config.Keys.AcceptJobMapper)

RegisterNetEvent("npcTaxi:ridePaid", function(price, tip)
    SendNUIMessage({
        action = "rideFinished",
        amount = price
    })
    NotifyTaxi(_U("customerPaidTrip", price))

    if tip and tip > 0 then
        SetTimeout(Config.Tips.DelayMs, function()
            NotifyTaxi(_U("customerGiveTips", tip))
            AddRating(Config.Rating.Add.Tip)
        end)
    end
end)

RegisterNetEvent("npcTaxi:ridePaymentFailed", function()
    NotifyTaxi(_U("ridePaymentRejected"))
end)

local function RemoveDebugBlips()
    for _, blip in ipairs(debugBlips) do
        if blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    debugBlips = {}
    debugLocationsEnabled = false
end

local function AddDebugBlip(coords, sprite, color, text)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, TaxiLocations.Debug.BlipScale or 0.75)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    debugBlips[#debugBlips + 1] = blip
end

local function ShowDebugLocations()
    RemoveDebugBlips()
    debugLocationsEnabled = true

    if TaxiLocations.Debug.ShowDispatcher then
        AddDebugBlip(Config.Dispatcher.Coords, 198, 5, "Taxi Dispatcher")
    end

    if TaxiLocations.Debug.ShowVehicleSpawns then
        for index, spawn in ipairs(Config.Vehicles.SpawnPoints) do
            AddDebugBlip(spawn, 225, 5, ("Taxi Vehicle Spawn %s"):format(index))
        end
    end

    if TaxiLocations.Debug.ShowPickups then
        for index, pickup in ipairs(TaxiLocations.Pickups) do
            AddDebugBlip(pickup, 280, 46, ("Taxi Pickup %s"):format(index))
        end
    end

    if TaxiLocations.Debug.ShowDestinations then
        for index, destination in ipairs(TaxiLocations.Destinations) do
            AddDebugBlip(destination.coords, 280, 2, destination.name or destination.text or ("Taxi Destination %s"):format(index))
        end
    end
end

CreateThread(function()
    Wait(2000)
    UpdateRatingUI()
    TriggerServerEvent("npcTaxi:requestRating")
    TriggerServerEvent("npcTaxi:requestShiftStats")
    if TaxiLocations.Debug and TaxiLocations.Debug.Enabled then
        ShowDebugLocations()
    else
        RemoveDebugBlips()
    end
end)
-------------------------------------------------
-- TAXAMETER
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped)
            if veh == taxiVeh then
                -- View the taximeter
                SendNUIMessage({
                    action = "showMeter"
                })
            else
                SendNUIMessage({
                    action = "hideMeter"
                })
            end
        else
            SendNUIMessage({
                action = "hideMeter"
            })
        end
    end
end)
-- Start
function StartTaximeter()
    meterActive = true
    distance = 0
    currentFare = Config.Taximeter.BaseFare
    lastPos = GetEntityCoords(PlayerPedId())
    -- 🟢 LED ON
    SendNUIMessage({
        action = "meterState",
        state = true
    })
end
-- Stop
function StopTaximeter()
    meterActive = false
    -- 🔴 LED OFF
    SendNUIMessage({
        action = "meterState",
        state = false
    })
end
-- Reset
function ResetTaximeter()
    distance = 0
    currentFare = Config.Taximeter.BaseFare
    lastPos = GetEntityCoords(PlayerPedId())
    -- UI Reset
    SendNUIMessage({
        action = "resetMeter"
    })
end
-- Calculate route
CreateThread(function()
    while true do
        Wait(meterActive and 1000 or 2000)
        if meterActive then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            if lastPos then
                local dist = #(pos - lastPos)
                distance = distance + dist
            end
            lastPos = pos
            local km = distance / 1000
            currentFare = math.min(Config.Taximeter.MaxFare, Config.Taximeter.BaseFare + (km * Config.Taximeter.PricePerKM))
            SendNUIMessage({
                action = "updateMeter",
                fare = math.floor(currentFare),
                distance = km                
            })
        end
    end
end)
-- Identify a Taxi
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and veh == taxiVeh then
            if HasAnyPassenger(veh) then
                if not meterActive then
                    StartTaximeter()
                end
            else
                if meterActive then
                    StopTaximeter()
                end
            end
        else
            if meterActive then
                StopTaximeter()
            end
        end
    end
end)
-------------------------------------------------
-- SPAWN CHECK
-------------------------------------------------
local function IsSpawnPointClear(coords, radius)
    local vehicles = GetGamePool('CVehicle')
    for _,veh in pairs(vehicles) do
        local vehCoords = GetEntityCoords(veh)
        if #(coords - vehCoords) < radius then
            return false
        end
    end
    return true
end
-------------------------------------------------
-- DISPATCHER NPC + BLIP
-------------------------------------------------
CreateThread(function()
    local model = Config.Dispatcher.Model
    local coords = Config.Dispatcher.Coords
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    -- QB TARGET
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                label = _U("headerText"),
                icon = "fas fa-taxi",
                action = function()
                    OpenTaxiMenu()
                end
            }
        },
        distance = 2.0
    })
    -- BLIP
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 198)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_U("headerText"))
    EndTextCommandSetBlipName(blip)
end)
-------------------------------------------------
-- DISPATCHER MENU
-------------------------------------------------
function OpenTaxiMenu()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local menu = {}
    -- ❌ The player does NOT have a taxi job
    if PlayerData.job.name ~= Config.Job.Name then
        menu = {
            {
                header = _U("headerText"),
                isMenuHeader = true
            },
            {
                header = _U("singUpJob"),
                txt = _U("singUpJpbText"),
                params = {
                    event = "npcTaxi:applyJob"
                }
            }
        }
    else
    -- ✅ Player is a taxi driver
    local dutyStatus = _U("dutyStatusOff")
    if PlayerData.job.onduty then
        dutyStatus = _U("dutyStatusOn")
    end
    menu = {
            {
                header = _U("headerText"),
                isMenuHeader = true
            },
            {
                header = _U("dutyStatusIs") .. dutyStatus,
                params = {
                    event = "npcTaxi:dutyToggle"
                }
            },
            {
                header = _U("vehParkingOut"),
                params = {
                    event = "npcTaxi:spawnVehicle",
                    args = Config.Vehicles.List[1]
                }
            },
            {
                header = _U("vehParkingIn"),
                params = {
                    event = "npcTaxi:storeVehicle"
                }
            },
            {
                header = _U("quitJob"),
                params = {
                    event = "npcTaxi:quitJob"
                }
            }
        }
    end
    exports['qb-menu']:openMenu(menu)
end
-------------------------------------------------
-- DUTY SYSTEM
-------------------------------------------------
RegisterNetEvent("npcTaxi:dutyToggle", function()
    TriggerServerEvent("QBCore:ToggleDuty")
end)
-------------------------------------------------
-- SPAWN TAXI
-------------------------------------------------
RegisterNetEvent("npcTaxi:spawnVehicle", function(vehicle)
    local PlayerData = QBCore.Functions.GetPlayerData()

    -- ❌ No taxi job
    if not PlayerData.job or PlayerData.job.name ~= Config.Job.Name then
        NotifyTaxi(_U("youNotTaxiDriver"))
        return
    end
    -- ❌ Off duty
    if not PlayerData.job.onduty then
        NotifyTaxi(_U("youNotDuty"))
        return
    end
    if licenseCheckPending then
        return
    end

    licenseCheckPending = true
    TriggerServerEvent("npcTaxi:checkLicense", vehicle)
end)

RegisterNetEvent("npcTaxi:licenseResult", function(hasLicense, vehicle)
    licenseCheckPending = false

    if not hasLicense then
        NotifyTaxi(_U("youNeedDriverLicense"))
        return
    end
    if spawningVehicle then
        NotifyTaxi(_U("vehicleAlreadyOutParking"))
        return
    end
    if taxiVeh and DoesEntityExist(taxiVeh) then
        NotifyTaxi(_U("youHaveVehicle"))
        return
    end

    spawningVehicle = true
    for _,spawn in pairs(Config.Vehicles.SpawnPoints) do
        if IsSpawnPointClear(spawn.xyz, 3.0) then
            QBCore.Functions.SpawnVehicle(vehicle, function(veh)
                taxiVeh = veh
                local plate = "TAXI"..math.random(100,999)
                SetVehicleNumberPlateText(veh, plate)
                SetEntityHeading(veh, spawn.w)
                SetVehicleEngineOn(veh, false, false)
                NotifyTaxi(_U("vehicleMovedoutHereCarkeys"))
                TriggerEvent("vehiclekeys:client:SetOwner", plate)
                spawningVehicle = false
            end, spawn, true)
            return
        end
    end

    spawningVehicle = false
    NotifyTaxi(_U("noSpawnAvailable"))
end)
-------------------------------------------------
-- PARKING THE VEHICLE
-------------------------------------------------
RegisterNetEvent("npcTaxi:storeVehicle", function()
    if taxiVeh and DoesEntityExist(taxiVeh) and employmentTerminated and terminationVehicle == taxiVeh then
        NotifyTaxi(_U("youCannotParkVehicle"))
        return
    end
    if activeJob then
        NotifyTaxi(_U("youCannotParkVehicle"))
        return
    end
    if not taxiVeh or not DoesEntityExist(taxiVeh) then
        NotifyTaxi(_U("noVehicleAvailable"))
        return
    end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    for _,veh in pairs(vehicles) do
        if #(coords - GetEntityCoords(veh)) < Config.Vehicles.StoreRadius then
            if veh == taxiVeh then
                DeleteVehicle(veh)
                taxiVeh = nil
                ResetTaximeter()
                StopTaximeter()
                NotifyTaxi(_U("vehicleParked"))
                return
            end
        end
    end
    NotifyTaxi(_U("notaxisAvailableNearby"))
end)
-------------------------------------------------
-- DISPATCH SYSTEM
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(math.random(Config.Dispatch.CooldownMin, Config.Dispatch.CooldownMax))
        -- 🎯 The rating determines whether the order is placed
        local chance = math.random()
        if chance > GetDispatchChance() then
            -- Bad driver → no job
            goto continue
        end
        local ped = PlayerPedId()
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name == Config.Job.Name and PlayerData.job.onduty and not activeJob and not jobAccepted then
            local pickup = TaxiLocations.Pickups[math.random(#TaxiLocations.Pickups)]
            local passengerCount = 1
            if (Config.Passengers.MaxCount or 1) > 1 and math.random(1, 100) <= (Config.Passengers.DoublePassengerChance or 0) then
                passengerCount = math.min(Config.Passengers.MaxCount or 1, 2)
            end
            local dist = #(GetEntityCoords(ped) - pickup.xyz)
            PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", true)
            NotifyTaxi(_U("newOrder", math.floor(dist)) .. " " .._U("pressKey", Config.Keys.AcceptJobLabel))
            local accepted = false
            local endTime = GetGameTimer() + Config.Dispatch.AcceptTimeout
            acceptJobRequested = false
        while GetGameTimer() < endTime do
            Wait(0)
            if acceptJobRequested or IsControlJustPressed(0, Config.Keys.AcceptJobControl) then
                accepted = true
                acceptJobRequested = false
                break
        end
        end
            if accepted then
                jobAccepted = true
                pendingPickup = pickup
                pendingPassengerCount = passengerCount
                jobAcceptTime = GetGameTimer()
                jobTimeout = GetGameTimer() + maxRideTime
                NotifyTaxi(_U("jobAccepted"))
                AddRating(Config.Rating.Add.AcceptJob)
            else
                acceptJobRequested = false
                missedJobs = missedJobs + 1
                NotifyTaxi(_U("missedOrder", missedJobs, maxMissedJobs))
                RemoveRating(Config.Rating.Remove.MissedJob)
                if missedJobs >= maxMissedJobs then
                TriggerServerEvent("QBCore:ToggleDuty")
                    Wait(Config.Dispatch.MissedJobNotifyDelay)
                NotifyTaxi(_U("automaticallyOffDuty"))
                missedJobs = 0 -- Reset
                end
            end
         end
         ::continue::
    end
end)
CreateThread(function()
    while true do
        Wait(2000)
        if jobAccepted and jobTimeout then
            if GetGameTimer() > jobTimeout then
                jobAccepted = false
                pendingPickup = nil
                pendingPassengerCount = 1
                jobTimeout = nil
                NotifyTaxi(_U("orderAutoCanceled"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                RemoveRating(Config.Rating.Remove.OrderAutoCanceled)
            end
        end
    end
end)
CreateThread(function()
    while true do
        Wait(1000)
        if jobAccepted and pendingPickup then
            local ped = PlayerPedId()
            if IsPedInVehicle(ped, taxiVeh, false) then
                StartTaxiJob(pendingPickup, pendingPassengerCount or 1)
                pendingPickup = nil
                pendingPassengerCount = 1
                jobAccepted = false
            end
        end
    end
end)
-------------------------------------------------
-- NPC IS GETTING IMPATIENT
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if npcPassenger and taxiVeh then
            if GetEntitySpeed(taxiVeh) < 1.0 then
                idleTimer = idleTimer + Config.NPC.IdleComplaintInterval
            else
                idleTimer = 0
                idleComplaintCount = 0
            end
            if idleTimer >= Config.NPC.IdleWarning and idleComplaintCount < Config.NPC.MaxIdleComplaints then
                NotifyTaxi(_U("notMove"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                RemoveRating(Config.Rating.Remove.IdleWarning)
                idleComplaintCount = idleComplaintCount + 1
            end
            if idleComplaintCount >= Config.NPC.MaxIdleComplaints or idleTimer >= Config.NPC.IdleLeave then
                NotifyTaxi(_U("customerOutofCar"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                idleTimer = 0
                idleComplaintCount = 0
                RemoveRating(Config.Rating.Remove.CustomerLeftVehicle)
                CancelTaxiJob()
            end
        else
            idleTimer = 0
            idleComplaintCount = 0
        end
    end
end)
-------------------------------------------------
-- JOB ACCEPT TIMEOUT
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if jobAccepted and jobAcceptTime then
            local elapsed = (GetGameTimer() - jobAcceptTime) / 1000
            -- 2 minutes to get into the taxi
            if elapsed > 120 then
                jobAccepted = false
                pendingPickup = nil
                pendingPassengerCount = 1
                jobAcceptTime = nil
                NotifyTaxi(_U("timeLimitExceeded"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                RemoveRating(Config.Rating.Remove.NoTaxiEntry)
            end
        end
    end
end)
-------------------------------------------------
-- ANTI FARM CHECK
-------------------------------------------------
local lastDistance = nil
local wrongWayTimer = 0
CreateThread(function()
    while true do
        Wait(5000)
    if activeJob and npcPassenger and destinationCoords then
        local ped = PlayerPedId()
        local currentDist = #(GetEntityCoords(ped) - destinationCoords)
    if lastDistance then
    if currentDist > lastDistance + Config.AntiFarm.WrongWayDistance then
        wrongWayTimer = wrongWayTimer + 5
        if wrongWayTimer == 10 then
            NotifyTaxi(_U("notRightWay"))
            PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
            RemoveRating(Config.Rating.Remove.WrongWay)
        end
        if wrongWayTimer >= Config.AntiFarm.MaxWrongTime then
            NotifyTaxi(_U("customerJumpsOut"))
            PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
            CancelTaxiJob()
            ResetTaximeter()
            RemoveRating(Config.Rating.Remove.WrongWayCancel)
            Wait(2000)
        end
    else
        wrongWayTimer = 0
    end
    end
        lastDistance = currentDist
        end
    end
    end)
-- NPC calls the police (RP Feature)
RegisterNetEvent("taxi:npcPanic", function()
    NotifyTaxi(_U("customerCallingPolice"))
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
    TriggerServerEvent("taxi:callPolice", GetEntityCoords(PlayerPedId()))
    RemoveRating(Config.Rating.Remove.PoliceCall)
end)
-------------------------------------------------
-- START JOB
-------------------------------------------------
function StartTaxiJob(coords, passengerCount)
    if activeJob then
        print("Job already active → blocked")
        return
    end
    jobAcceptTime = nil
    activeJob = true
    if jobBlip then
        RemoveBlip(jobBlip)
    end
    jobBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(jobBlip, 280)
    SetBlipColour(jobBlip, 5)
    SetBlipScale(jobBlip, 0.8)
    SetBlipRoute(jobBlip, true)
    SpawnCustomer(coords, passengerCount or 1)
    end
-------------------------------------------------
-- CUSTOMER SPAWN
-------------------------------------------------
function SpawnCustomer(coords)
    if not activeJob then return end
    if customerPed and DoesEntityExist(customerPed) then
    DeletePed(customerPed)
    customerPed = nil
    end
    pickupTimer = GetGameTimer()
    local model = CustomerModels[math.random(#CustomerModels)]
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local x,y,z,w = coords.x, coords.y, coords.z, coords.w or 0.0
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z, w)
    if found then
    z = groundZ + 1.0
    end
    customerPed = CreatePed(0, model, x, y, z, w, true, false)
    SetEntityHeading(customerPed, w)
    -- 🔴 HEDGING
    if not customerPed or customerPed == 0 then
    print("NPC Spawn FAILED")
    ResetTaxiJob()
    return
    end
    CreateThread(function()
    local waved = false -- 👈 new (checks if it has already been waved at)
    while activeJob and customerPed and DoesEntityExist(customerPed) do
        Wait(1000)
        local ped = PlayerPedId()
        local targetCoords = vector3(coords.x, coords.y, coords.z)
        local dist = #(GetEntityCoords(ped) - targetCoords)
        -- 👋 WAVING (previously at 30 m)
        if dist < 30.0 and not waved then
            waved = true
            RequestAnimDict("friends@frj@ig_1")
            while not HasAnimDictLoaded("friends@frj@ig_1") do Wait(0) end
            TaskPlayAnim(customerPed, "friends@frj@ig_1", "wave_a", 8.0, -8.0, -1, 49, 0, false, false, false)
        end
        -- 🚕 GET STARTED (your original code, with only minor adjustments)
        if dist < Config.NPC.ApproachRadius then
            ClearPedTasks(customerPed) -- Stop waving
            TaskGoToEntity(customerPed, taxiVeh, -1, 3.0, 1.0, 0, 0)
            Wait(2000)
            if not DoesEntityExist(customerPed) then
                ResetTaxiJob()
                return
            end
            TaskEnterVehicle(customerPed, taxiVeh, -1, 2, 1.0, 1, 0)
            local enterDeadline = GetGameTimer() + Config.NPC.EnterVehicleTimeout
            while not IsPedInVehicle(customerPed, taxiVeh, false) do
                if not DoesEntityExist(customerPed) or GetGameTimer() > enterDeadline then
                    RemoveRating(Config.Rating.Remove.NpcEnterFail)
                    CancelTaxiJob()
                    return
                end
                Wait(500)
            end
            npcPassenger = true
            TriggerServerEvent("npcTaxi:startRide")
            -- 🔊 Greetings
            CreateThread(function()
                Wait(1000) -- A short delay to let the NPC settle in

                if customerPed and DoesEntityExist(customerPed) then
                PlayPedAmbientSpeechNative(customerPed, "GENERIC_HI", "SPEECH_PARAMS_FORCE")
                end
            end)
            StartTaximeter()
            -- ⏱️ Start the timer (yours stays on!)
            SendNUIMessage({
                action = "startTimer"
            })
            pickupTimer = nil
            pickupWarning = false
            StartTaximeter()
            StartDestinations(coords.xyz)
            break
            end
        end
    end)
end
-- =========================================
-- NPC COMPLAINS WHEN TAKING DAMAGE
-- =========================================
function SpawnCustomer(coords, passengerCount)
    if not activeJob then return end

    ClearCustomerPeds(true)
    pickupTimer = GetGameTimer()

    local x, y, z, w = coords.x, coords.y, coords.z, coords.w or 0.0
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z, w)
    if found then
        z = groundZ + 1.0
    end

    local requestedPassengerCount = math.max(1, math.min(passengerCount or 1, Config.Passengers.MaxCount or 1))
    for index = 1, requestedPassengerCount do
        local model = CustomerModels[math.random(#CustomerModels)]
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        local spawnOffset = GetOffsetFromCoordAndHeadingInWorldCoords(x, y, z, w, 0.0, (index - 1) * 1.2, 0.0)
        local spawnedPed = CreatePed(0, model, spawnOffset.x, spawnOffset.y, spawnOffset.z, w, true, false)
        if not spawnedPed or spawnedPed == 0 then
            print("NPC Spawn FAILED")
            ClearCustomerPeds(true)
            ResetTaxiJob()
            return
        end

        SetEntityHeading(spawnedPed, w)
        customerPeds[#customerPeds + 1] = spawnedPed
        SetModelAsNoLongerNeeded(model)
    end

    customerPed = customerPeds[1]

    CreateThread(function()
        local waved = false
        while activeJob and #GetActiveCustomerPeds() > 0 do
            Wait(1000)
            local ped = PlayerPedId()
            local targetCoords = vector3(coords.x, coords.y, coords.z)
            local dist = #(GetEntityCoords(ped) - targetCoords)

            if dist < 30.0 and not waved then
                waved = true
                RequestAnimDict("friends@frj@ig_1")
                while not HasAnimDictLoaded("friends@frj@ig_1") do Wait(0) end
                for _, passengerPed in ipairs(GetActiveCustomerPeds()) do
                    TaskPlayAnim(passengerPed, "friends@frj@ig_1", "wave_a", 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end

            if dist < Config.NPC.ApproachRadius then
                local passengers = GetActiveCustomerPeds()
                if #passengers == 0 then
                    ResetTaxiJob()
                    return
                end

                for _, passengerPed in ipairs(passengers) do
                    ClearPedTasks(passengerPed)
                    TaskGoToEntity(passengerPed, taxiVeh, -1, 3.0, 1.0, 0, 0)
                end

                Wait(2000)
                passengers = GetActiveCustomerPeds()
                if #passengers == 0 then
                    ResetTaxiJob()
                    return
                end

                local configuredSeats = Config.Passengers.Seats or { 1, 2 }
                for index, passengerPed in ipairs(passengers) do
                    local seat = configuredSeats[index] or index
                    TaskEnterVehicle(passengerPed, taxiVeh, -1, seat, 1.0, 1, 0)
                end

                local enterDeadline = GetGameTimer() + Config.NPC.EnterVehicleTimeout
                while true do
                    local allBoarded = true
                    passengers = GetActiveCustomerPeds()

                    if #passengers == 0 then
                        allBoarded = false
                    end

                    for _, passengerPed in ipairs(passengers) do
                        if not IsPedInVehicle(passengerPed, taxiVeh, false) then
                            allBoarded = false
                            break
                        end
                    end

                    if allBoarded then
                        break
                    end

                    if GetGameTimer() > enterDeadline then
                        RemoveRating(Config.Rating.Remove.NpcEnterFail)
                        CancelTaxiJob()
                        return
                    end

                    Wait(500)
                end

                customerPed = customerPeds[1]
                npcPassenger = true
                TriggerServerEvent("npcTaxi:startRide", GetPassengerCountForRide())

                CreateThread(function()
                    Wait(1000)
                    if customerPed and DoesEntityExist(customerPed) then
                        PlayPedAmbientSpeechNative(customerPed, "GENERIC_HI", "SPEECH_PARAMS_FORCE")
                    end
                end)

                StartTaximeter()
                SendNUIMessage({
                    action = "startTimer"
                })
                pickupTimer = nil
                pickupWarning = false
                StartTaximeter()
                StartDestinations(coords.xyz)
                break
            end
        end
    end)
end

CreateThread(function()
    local lastEngine = 1000
    local lastBody = 1000
    local cooldown = 0
    while true do
        Wait(1000)
        if npcPassenger and taxiVeh and DoesEntityExist(taxiVeh) then
            local engine = GetVehicleEngineHealth(taxiVeh)
            local body = GetVehicleBodyHealth(taxiVeh)
            -- Damage detected (built-in tolerance)
            if (engine < lastEngine - 20 or body < lastBody - 20) and cooldown <= 0 then
                if customerPed and DoesEntityExist(customerPed) then
                    local complaints = {
                        "GENERIC_INSULT_HIGH",
                        "GENERIC_FRIGHTENED_HIGH",
                        "GENERIC_CURSE_HIGH",
                        "GENERIC_SHOCKED_HIGH"
                    }
                    PlayPedAmbientSpeechNative(
                        customerPed,
                        complaints[math.random(#complaints)],
                        "SPEECH_PARAMS_FORCE"
                    )
                end
                cooldown = 5 -- Pause for a few seconds to prevent spam
            end
            lastEngine = engine
            lastBody = body
            if cooldown > 0 then
                cooldown = cooldown - 1
            end
        else
            -- Reset if there is no customer
            lastEngine = 1000
            lastBody = 1000
            cooldown = 0
        end
    end
end)
-------------------------------------------------
-- NPC PICKUP TIMEOUT + WARNING
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if activeJob and not npcPassenger and pickupTimer then
            local elapsed = GetGameTimer() - pickupTimer
            -- Warning after 2 minutes
            if elapsed > pickupWarningTime and not pickupWarning then
                pickupWarning = true
                NotifyTaxi(_U("customerWhereTaxi"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
            end
            -- Cancel order after 3 minutes
            if elapsed > maxPickupTime then
                NotifyTaxi(_U("customerUsedDifferentTaxi"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                RemoveRating(Config.Rating.Remove.CustomerTookDifferentTaxi)
                if jobBlip then
                    RemoveBlip(jobBlip)
                    jobBlip = nil
                end
                ResetTaxiJob()
            end
        end
    end
end)
-------------------------------------------------
-- DESTINATION
-------------------------------------------------
function StartDestinations(pickupCoords)
    lastDistance = nil
    wrongWayTimer = 0
    if not pickupCoords then return end
        local dest
        local distance = 0
        local pickupVec = vector3(pickupCoords.x, pickupCoords.y, pickupCoords.z)
    repeat
        dest = TaxiLocations.Destinations[math.random(#TaxiLocations.Destinations)]
        distance = #(pickupVec - dest.coords)
    until distance >= 1000.0 and distance <= 5000.0
    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end
        destinationCoords = dest.coords
         destinationText = dest.text
        NotifyTaxi(_U("driveTo", dest.name))
        jobBlip = AddBlipForCoord(dest.coords.x, dest.coords.y, dest.coords.z)
        SetBlipRoute(jobBlip, true)
    CreateThread(function()
        while activeJob do
            Wait(1000)
            local ped = PlayerPedId()
    if #(GetEntityCoords(ped) - vector3(dest.coords.x, dest.coords.y, dest.coords.z)) < Config.Payout.CompletionRadius then
    NotifyTaxi(_U("customerStopHere"))
            Wait(5000)
    -- 🔊 Saying thank you
    if customerPed and DoesEntityExist(customerPed) then
         PlayPedAmbientSpeechNative(customerPed, "GENERIC_THANKS", "SPEECH_PARAMS_FORCE")
    end
    -- Calculate price
    local price = math.floor(currentFare)
    TriggerServerEvent("npcTaxi:completeRide", price)
    -- Remove GPS route
    if jobBlip then
    RemoveBlip(jobBlip)
    jobBlip = nil
    end
    npcPassenger = false
    -- ⏱️ Stop the timer
    SendNUIMessage({
    action = "stopTimer"
})
ResetTaximeter()
Wait(2000)
-- Let the NPC get out
-- 🔊 Saying goodbye
if customerPed and DoesEntityExist(customerPed) then
    PlayPedAmbientSpeechNative(customerPed, "GENERIC_BYE", "SPEECH_PARAMS_FORCE")
end
---
if customerPed and taxiVeh then
    TaskLeaveVehicle(customerPed, taxiVeh, 0)
end
Wait(1000)
-- Close the door if it is open
    if taxiVeh and DoesEntityExist(taxiVeh) then
    -- rear right door (NPC usually sits in the back)
    local doorIndex = 3
    if GetVehicleDoorAngleRatio(taxiVeh, doorIndex) > 0.1 then
        SetVehicleDoorShut(taxiVeh, doorIndex, false)
    end
end
    AddRating(Config.Rating.Add.FinishRide)
    RegisterCleanRide()
-- NPC takes a short walk
local walkAway = GetOffsetFromEntityInWorldCoords(customerPed, 6.0, 0.0, 0.0)
TaskGoStraightToCoord(customerPed, walkAway.x, walkAway.y, walkAway.z, 1.0, -1, 0.0, 0.0)
Wait(5000)
-- NPC stops and makes a phone call
TaskStartScenarioInPlace(customerPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
-- Optional: NPC stays put (does not run away)
FreezeEntityPosition(customerPed, true)
-- SAVE HERE (IMPORTANT!)
local pedToDelete = customerPed
-- RESET JOB NOW
ResetTaxiJob()
-- NPC despawn later
SetTimeout(45000, function()
    if pedToDelete and DoesEntityExist(pedToDelete) then
        DeletePed(pedToDelete)
    end
end)
break
end
end
end)
end
function StartDestinations(pickupCoords)
    lastDistance = nil
    wrongWayTimer = 0
    if not pickupCoords then return end

    local dest
    local distanceToDestination = 0
    local pickupVec = vector3(pickupCoords.x, pickupCoords.y, pickupCoords.z)

    repeat
        dest = TaxiLocations.Destinations[math.random(#TaxiLocations.Destinations)]
        distanceToDestination = #(pickupVec - dest.coords)
    until distanceToDestination >= 1000.0 and distanceToDestination <= 5000.0

    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end

    destinationCoords = dest.coords
    destinationText = dest.text
    NotifyTaxi(_U("driveTo", dest.name))
    jobBlip = AddBlipForCoord(dest.coords.x, dest.coords.y, dest.coords.z)
    SetBlipRoute(jobBlip, true)

    CreateThread(function()
        while activeJob do
            Wait(1000)
            local ped = PlayerPedId()
            if #(GetEntityCoords(ped) - vector3(dest.coords.x, dest.coords.y, dest.coords.z)) < Config.Payout.CompletionRadius then
                NotifyTaxi(_U("customerStopHere"))
                Wait(5000)

                local ridePassengers = GetActiveCustomerPeds()
                customerPed = ridePassengers[1]

                if customerPed and DoesEntityExist(customerPed) then
                    PlayPedAmbientSpeechNative(customerPed, "GENERIC_THANKS", "SPEECH_PARAMS_FORCE")
                end

                local price = math.floor(currentFare)
                TriggerServerEvent("npcTaxi:completeRide", price)

                if jobBlip then
                    RemoveBlip(jobBlip)
                    jobBlip = nil
                end

                npcPassenger = false
                SendNUIMessage({
                    action = "stopTimer"
                })
                ResetTaximeter()
                Wait(2000)

                if customerPed and DoesEntityExist(customerPed) then
                    PlayPedAmbientSpeechNative(customerPed, "GENERIC_BYE", "SPEECH_PARAMS_FORCE")
                end

                if taxiVeh then
                    for _, passengerPed in ipairs(ridePassengers) do
                        if passengerPed and DoesEntityExist(passengerPed) then
                            TaskLeaveVehicle(passengerPed, taxiVeh, 0)
                        end
                    end
                end

                Wait(1000)
                if taxiVeh and DoesEntityExist(taxiVeh) then
                    for doorIndex = 1, 3 do
                        if GetVehicleDoorAngleRatio(taxiVeh, doorIndex) > 0.1 then
                            SetVehicleDoorShut(taxiVeh, doorIndex, false)
                        end
                    end
                end

                AddRating(Config.Rating.Add.FinishRide)
                RegisterCleanRide()

                for index, passengerPed in ipairs(ridePassengers) do
                    if passengerPed and DoesEntityExist(passengerPed) then
                        local sideOffset = -4.5
                        local forwardOffset = -6.0 - index
                        local walkAway = GetOffsetFromEntityInWorldCoords(taxiVeh, sideOffset, forwardOffset, 0.0)
                        TaskGoStraightToCoord(passengerPed, walkAway.x, walkAway.y, walkAway.z, 1.0, -1, 0.0, 0.0)
                    end
                end

                Wait(5000)

                for _, passengerPed in ipairs(ridePassengers) do
                    if passengerPed and DoesEntityExist(passengerPed) then
                        TaskStartScenarioInPlace(passengerPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
                        FreezeEntityPosition(passengerPed, true)
                    end
                end

                local pedsToDelete = ridePassengers
                ResetTaxiJob()

                SetTimeout(45000, function()
                    for _, pedToDelete in ipairs(pedsToDelete) do
                        if pedToDelete and DoesEntityExist(pedToDelete) then
                            DeletePed(pedToDelete)
                        end
                    end
                end)

                break
            end
        end
    end)
end

--NPC Reset Funktion
function ResetTaxiJob()
    TriggerServerEvent("npcTaxi:cancelRide")
    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end
    customerPed = nil
    npcPassenger = false
-- ⏱️ Stop the timer
SendNUIMessage({
    action = "stopTimer"
})
ResetTaximeter()
    destinationCoords = nil
    pendingPickup = nil
    activeJob = false
    jobAccepted = false
    pickupTimer = nil
    pickupWarning = false
    jobTimeout = nil
    jobAcceptTime = nil
    idleTimer = 0
    idleComplaintCount = 0
    wrongWayTimer = 0
    lastDistance = nil
end
-------------------------------------------------
-- TAXI JOB SAFETY CHECKS
-------------------------------------------------
CreateThread(function()
    while true do
        Wait(activeJob and 5000 or 10000)
        if activeJob then
            local ped = PlayerPedId()
            -- Player gets out of the taxi while a customer is still inside
            if npcPassenger and not IsPedInVehicle(ped, taxiVeh, false) then
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
    NotifyTaxi(_U("passengerGottenOff"))
                RemoveRating(Config.Rating.Remove.LeaveTaxiWithPassenger)
                CancelTaxiJob()
            end
            -- Taxi wrecked
            if taxiVeh and DoesEntityExist(taxiVeh) and GetVehicleEngineHealth(taxiVeh) < Config.Vehicles.EngineDamageLimit then
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                NotifyTaxi(_U("taxiDamaged"))
                RemoveRating(Config.Rating.Remove.VehicleDamage)
                CancelTaxiJob()
            end
            -- Player dies
            if IsEntityDead(ped) then
                NotifyTaxi(_U("youDied"))
                PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
                RemoveRating(Config.Rating.Remove.Death)
                CancelTaxiJob()
            end
        end
    end
end)
function CancelTaxiJob()
    if customerPed and DoesEntityExist(customerPed) then
        TaskLeaveVehicle(customerPed, taxiVeh, 0)
        Wait(2000)
        DeletePed(customerPed)
    end
    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end
    ResetTaxiJob()
    ResetTaximeter()
    StopTaximeter()
end

function ResetTaxiJob()
    TriggerServerEvent("npcTaxi:cancelRide")
    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end

    ClearCustomerPeds(false)
    npcPassenger = false
    SendNUIMessage({
        action = "stopTimer"
    })
    ResetTaximeter()
    destinationCoords = nil
    pendingPickup = nil
    pendingPassengerCount = 1
    activeJob = false
    jobAccepted = false
    pickupTimer = nil
    pickupWarning = false
    jobTimeout = nil
    jobAcceptTime = nil
    idleTimer = 0
    idleComplaintCount = 0
    wrongWayTimer = 0
    lastDistance = nil
end

function CancelTaxiJob()
    local passengers = GetActiveCustomerPeds()
    for _, passengerPed in ipairs(passengers) do
        if passengerPed and DoesEntityExist(passengerPed) then
            TaskLeaveVehicle(passengerPed, taxiVeh, 0)
        end
    end

    if #passengers > 0 then
        Wait(2000)
        ClearCustomerPeds(true)
    end

    if jobBlip then
        RemoveBlip(jobBlip)
        jobBlip = nil
    end

    ResetTaxiJob()
    ResetTaximeter()
    StopTaximeter()
end
--------------------------------------
-- ON/OFF DUTY TAXIJOB
--------------------------------------
CreateThread(function()
    local lastDuty = nil
    local notifyCooldown = false
    while true do
        Wait(1000)
        local PlayerData = QBCore.Functions.GetPlayerData()        
        if PlayerData and PlayerData.job and PlayerData.job.name == Config.Job.Name then
            if lastDuty == nil then
                lastDuty = PlayerData.job.onduty
            end            
            if lastDuty ~= PlayerData.job.onduty and not notifyCooldown then
                notifyCooldown = true
                lastDuty = PlayerData.job.onduty
                if lastDuty then
                    -- 🟢 Player on duty                    
                    TaxiNotify(_U("customersWaiting"))
                else
                    TaxiNotify(_U("seeYouSoon"))
                end
                SetTimeout(4000, function()
                    notifyCooldown = false
                end)
            end
        end
    end
end)

-----------------------------------------------------
-- HIDE QB NOTIFICATIONS (FOR TAXIJOB ONLY)
-----------------------------------------------------
CreateThread(function()
    while true do
        Wait(1000)
        local PlayerData = QBCore.Functions.GetPlayerData()
        if PlayerData and PlayerData.job and PlayerData.job.name == Config.Job.Name then
            SendNUIMessage({
                action = "hideQB"
            })
        end
    end
end)
------------------------------------------------------
-- ACCEPT/CANCEL A TAXI JOB
------------------------------------------------------
--Employment
RegisterNetEvent("npcTaxi:applyJob", function()
    TriggerServerEvent("npcTaxi:setJob")
    SetTimeout(2000, function()
    end)
end)
-- Resignation
RegisterNetEvent("npcTaxi:quitJob", function()
    if taxiVeh and DoesEntityExist(taxiVeh) then
        RemoveRating(Config.Rating.Remove.NoVehicleReturn)
    end
    TriggerServerEvent("npcTaxi:removeJob")
    RemoveDebugBlips()
    acceptJobRequested = false
    employmentTerminated = false
    terminationVehicle = nil
    cleanRideStreak = 0
    TaxiNotify(_U("youQuitJob"))
    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
end)
------------------------------------------------------
-- HTML TRANSLATE
------------------------------------------------------
CreateThread(function()
    Wait(1000)
        SendNUIMessage({
            action = "setLocale",
            taxiTitle = _U("taxiTitle"),
            fare = _U("fare"),
            distance = _U("distance"),
            time = _U("time"),
            today = _U("today"),
            rides = _U("rides"),
            ratingLabel = _U("rating")
        })
end)
