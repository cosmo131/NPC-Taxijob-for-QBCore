Config = {}

-- Language
Config.Locale = "en"

-- Keybinds
Config.Keys = {
    AcceptJobLabel = "E",
    AcceptJobMapper = "E",
    AcceptJobCommand = "npctaxi_accept_job",
    AcceptJobControl = 38
}

-- Job setup
Config.Job = {
    Name = "taxi",
    RequiredLicense = "driver",
    Grade = 0,
    ResetJobOnDisconnect = true
}

-- Dispatcher NPC
Config.Dispatcher = {
    Model = "s_m_m_gentransport",
    Coords = vector4(1737.82, 3709.0, 34.13, 14.37)
}

-- Vehicle setup
Config.Vehicles = {
    List = { "taxi" },
    Model = "taxi",
    StoreRadius = 20.0,
    EngineDamageLimit = 200,
    CrashSpeed = 45.0,

    SpawnPoints = {
        vector4(1749.11, 3715.99, 33.69, 111.7),
        vector4(1748.02, 3718.82, 33.65, 112.28),
        vector4(1746.86, 3721.98, 33.60, 110.54)
    }
}

-- Dispatch flow
Config.Dispatch = {
    CooldownMin = 30000,
    CooldownMax = 90000,
    AcceptTimeout = 20000,
    MissedJobNotifyDelay = 5000
}

-- Taximeter and payout
Config.Taximeter = {
    BaseFare = 5,
    PricePerKM = 12,
    MinFare = 8,
    MaxFare = 150
}

-- Payout validation
Config.Payout = {
    Account = "cash",
    MinRideSeconds = 15,
    CompletionRadius = 10.0
}

-- Tip rewards
Config.Tips = {
    ChancePercent = 30,
    MinAmount = 5,
    MaxAmount = 15,
    DelayMs = 5000,
    ExtraPassengerMultiplier = 0.5
}

-- NPC passenger setup
Config.Passengers = {
    MaxCount = 2,
    DoublePassengerChance = 35,
    Seats = { 1, 2 }
}

-- Rating system
Config.Rating = {
    Start = 50,
    Min = 0,
    Max = 100,
    WarningThreshold = 0,

    Add = {
        AcceptJob = 1,
        FinishRide = 3,
        Tip = 1
    },

    Bonus = {
        CleanRideCount = 5,
        CleanRidePoints = 3
    },

    Remove = {
        MissedJob = 1,
        OrderAutoCanceled = 5,
        NoTaxiEntry = 3,
        NpcEnterFail = 1,
        IdleWarning = 1,
        CustomerLeftVehicle = 5,
        CustomerTookDifferentTaxi = 5,
        WrongWayCancel = 5,
        LeaveTaxiWithPassenger = 1,
        NoVehicleReturn = 5,
        BadDrive = 1,
        PoliceCall = 1,
        VehicleDamage = 3,
        WrongWay = 1,
        Death = 10
    }
}

-- Automatic termination
Config.Termination = {
    Threshold = 0,
    VehicleDespawnDelay = 300000
}

-- Timers
Config.Timers = {
    PickupWarning = 240000,
    PickupCancel = 360000,
    AcceptTimeout = 20000,
    RideTimeout = 120000
}

-- Missed jobs
Config.JobLimits = {
    MaxMissedJobs = 10
}

-- NPC behavior
Config.NPC = {
    IdleWarning = 60,
    IdleLeave = 120,
    MaxIdleComplaints = 5,
    IdleComplaintInterval = 5,
    ApproachRadius = 10.0,
    EnterVehicleTimeout = 15000
}

-- Anti-farm and route checks
Config.AntiFarm = {
    WrongWayDistance = 60,
    MaxWrongTime = 25
}
