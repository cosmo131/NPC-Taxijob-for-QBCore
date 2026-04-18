TaxiLocations = {}

TaxiLocations.Debug = {
    Enabled = false,
    BlipScale = 0.75,
    ShowDispatcher = true,
    ShowVehicleSpawns = true,
    ShowPickups = true,
    ShowDestinations = true
}

TaxiLocations.Pickups = {
--  Sandy Shores
    vector4(2690.68, 4322.33, 45.85, 48.47),    -- Park View Diner -
    vector4(2916.93, 4371.14, 50.48, 64.82),    -- Union Grain Supply Inc. -
    vector4(2750.09, 3457.93, 55.94, 253.97),   -- You Tool Markt
    vector4(2685.4, 3287.03, 55.41, 234.85),    -- 24/7 Markt --
    vector4(2338.48, 3140.68, 48.2, 78.8),     -- Recycling Center --
    vector4(2554.08, 2612.36, 37.96, 9.64),     -- Rex Diner -
    vector4(2521.06, 1609.84, 30.1, 226.53),    -- Green Power
    vector4(2001.72, 3053.06, 47.21, 321.64),   -- Yellow Jack -
    vector4(1853.71, 2591.25, 45.67, 271.71),   -- Bolingbroke --
    vector4(1845.09, 3321.55, 43.67, 139.62),   -- Senora National Park
    vector4(391.47, 3586.7, 33.29, 350.55),     -- Tractor Parts Service -
    vector4(916.48, 3643.08, 32.64, 174.84),    -- Liquor Markt --
    vector4(1369.17, 3605.28, 34.89, 198.3),    -- Hand Carwash
    vector4(1537.38, 3775.75, 34.52, 210.6),    -- The Boat House --
    vector4(1929.95, 3718.72, 32.87, 211.31),   -- Barbers Shop --
    vector4(1859.05, 3681.37, 33.8, 226.01),    -- County Sheriff
    vector4(1836.82, 3667.32, 33.68, 208.79),   -- Medical Center --
    vector4(1704.09, 3584.02, 35.44, 216.91),   -- Fire Station
    vector4(2022.57, 3772.83, 32.18, 309.33),   -- Sandys Gas Station
    vector4(2432.71, 3781.53, 40.09, 48.79),    -- UFO
    vector4(3514.76, 3761.88, 30.07, 351.51),   -- Humane Labs
    vector4(3797.64, 4471.27, 5.35, 192.38),    -- Fischrei Ost
    vector4(3320.88, 5162.98, 18.36, 225.49),     -- Leuchtturm
    vector4(2321.08, 2589.39, 46.65, 64.54),    -- Peace
    vector4(1704.77, 3754.9, 34.34, 232.62),    -- Ammunination
    vector4(1961.07, 3735.5, 32.38, 207.99),    -- 24/7 Market SS
    vector4(1400.52, 3599.21, 35.03, 213.73),   -- Liquor ACE
    vector4(1781.01, 3318.03, 41.45, 291.66),   -- Airfield
    vector4(1960.93, 3835.0, 32.18, 340.83),    -- Noname Bar
-- Grapeseed
    vector4(2544.07, 4685.47, 33.63, 64.39),    --Shady Tree Farm
    vector4(2450.49, 4951.92, 44.97, 228.97),   --Oneil Ranch
    vector4(2019.85, 4965.99, 41.37, 248.21),  --Union Grain Feld
    vector4(2097.11, 4759.76, 41.21, 285.7),   --Flufeld
    vector4(1956.91, 4632.58, 40.81, 43.64),   --R.L. Hunter&Sons
    vector4(1803.14, 4589.79, 37.53, 212.0),   --Alamo Früchte Markt
    vector4(1703.85, 4723.52, 42.26, 100.33),  --Feed Store
    vector4(1695.31, 4791.28, 41.92, 85.12),   --Wonderama Arcade
    vector4(1680.87, 4823.19, 42.05, 95.01),   --Discount Store
    vector4(1673.41, 4920.95, 42.03, 85.13),   --Tankstelle
    vector4(1305.6, 4316.3, 37.84, 308.68),    --Millars Fischrei
-- Route 63
    vector4(1230.37, 2725.18, 38.0, 190.09),   --Larry´s RV Sales
    vector4(1204.18, 2655.76, 37.85, 358.67),  --Route 68 Store
    vector4(1171.66, 2699.48, 38.18, 189.43),  --Flecca Bank
    vector4(1141.24, 2664.58, 38.16, 50.51),   --The Motor Motel
    vector4(1049.68, 2663.68, 39.55, 353.27),  --Tankstellen Cafe
    vector4(631.94, 2733.31, 41.89, 93.35),    --Taco Laden
    vector4(611.71, 2745.17, 41.97, 187.14),   --Kleider Shop
    vector4(585.87, 2741.77, 42.08, 185.27),   --Dollar Pills
    vector4(559.95, 2738.39, 42.2, 183.7),     --Animal ARK
    vector4(549.58, 2675.68, 42.2, 3.42),      --24/7 Shop
    vector4(319.28, 2622.77, 44.47, 310.28),   --Eastern Motel
    vector4(254.16, 2597.33, 44.78, 358.56),   --All Cars Service
    vector4(43.97, 2789.11, 57.88, 149.28),    --Xero Markt
    vector4(-383.17, 2811.79, 45.46, 53.56),   --Kirche
    vector4(-1110.22, 2692.09, 18.6, 217.15),  --Ammunation Sporting Goods
    vector4(-2535.97, 2319.72, 33.22, 1.73),   --Ron Tankstelle
    vector4(-1586.87, 2098.21, 68.69, 295.04), --Wasserfall
    vector4(-1923.09, 2061.48, 140.83, 243.34),--Weingut
    vector4(-1502.86, 1515.44, 115.29, 254.44),--White ater Activity Center
    vector4(184.35, 2791.22, 45.58, 276.21),   --Lagerhaus
    vector4(254.38, 2856.26, 43.58, 167.04),   --Stone and Cement Work
    vector4(-83.22, 1885.19, 197.25, 185.0),   --Smal Farm on Great Chaparral
    vector4(808.84, 2174.21, 52.31, 327.45),   --Lagerhaus an der Crossbahn
    vector4(734.73, 2525.78, 73.23, 262.04),   --Rebel Radio Station
    vector4(1246.55, 1868.24, 79.16, 175.72),  --Blarneys Beer
--Nord Chumash
    vector4(-2215.85, 4272.1, 47.3, 64.84),    --Hookies Seafood Diner
    vector4(-1492.42, 4973.21, 63.84, 89.91),  --Raton Canyon Trails
 --Paleto Bay
    vector4(-766.79, 5580.97, 33.61, 120.75),  --Pala Springs
    vector4(-685.62, 5838.17, 17.33, 73.33),   --Bayview Lodge
    vector4(-215.63, 6551.73, 11.01, 220.74),  --Pier
    vector4(-426.47, 6027.64, 31.49, 293.75),  --Sheriff Department
    vector4(-392.22, 6128.91, 31.48, 40.82),   --Feuerwache
    vector4(-403.03, 6144.28, 31.44, 224.09),  --Post Station
    vector4(-334.5, 6152.33, 31.49, 131.56),   --Kirche
    vector4(-289.07, 6203.13, 31.47, 312.64),  --Tattoo Salon
    vector4(-249.35, 6212.17, 31.94, 137.5),   --Pixel Petes
    vector4(-293.66, 6253.35, 31.45, 232.78),  --The Hen House
    vector4(-283.2, 6239.6, 31.39, 48.77),     --Barber Shop
    vector4(-259.12, 6287.41, 31.45, 220.67),  --Bay Bar
    vector4(-233.91, 6313.75, 31.47, 223.45),  --Medical Station
    vector4(-129.34, 6393.11, 31.5, 48.59),    --Mojito Inn
    vector4(-111.4, 6455.76, 31.47, 136.72),   --Bank
    vector4(-155.65, 6453.48, 31.36, 311.5),   --South Seas Apartments
    vector4(-57.78, 6527.38, 31.49, 314.6),    --Willies Supermarkt
    vector4(1.42, 6522.68, 31.52, 73.79),      --Kleidung Shop
    vector4(121.91, 6625.42, 31.95, 220.36),   --Auto Service
    vector4(172.85, 6630.64, 31.75, 224.62),   --Dons Country Store
    vector4(-39.17, 6409.76, 31.49, 310.06),   --Morris & Sons
    vector4(-93.29, 6328.06, 31.49, 220.0),    --Dream View Motel
    vector4(-317.89, 6083.07, 31.32, 245.13),  --Waffengeschäft
    vector4(430.45, 6524.6, 27.83, 84.79),     --Donkey Punch Family Farm
    vector4(1586.34, 6450.37, 25.32, 159.02),  --Rays and Mays Diner
    vector4(1738.38, 6404.71, 34.93, 161.9),   --24/7 Shop
    vector4(-576.92, 5307.82, 70.26, 45.21),   --Sägewerk
}
TaxiLocations.Destinations = {
-- Sandy Shores
    {
        coords = vector3(2689.85, 4322.52, 45.85),
        name = "Park View Diner"
    },
    {
        coords = vector3(2916.93, 4371.14, 50.48),
        name = "Union Grain Supply Inc."
    },
    {
        coords = vector3(2750.09, 3457.93, 55.94),
        name = "You Tool Market"
    },
    {
        coords = vector3(2685.36, 3287.16, 55.41),
        name = "24/7 Market"
    },
    {
        coords = vector3(2339.21, 3140.65, 48.2),
        name = "Recycling Center"
    },
    {
        coords = vector3(2554.08, 2612.35, 37.96),
        name = "Rex Diner"
    },
    {
        coords = vector3(2554.08, 2612.35, 37.96),
        name = "Green Power"
    },
    {
        coords = vector3(2554.08, 2612.35, 37.96),
        name = "Yellow Jack Bar"
    },
    {
        coords = vector3(1852.59, 2595.98, 45.67),
        name = "Bolingbroke"
    },
    {
        coords = vector3(1844.71, 3320.97, 43.62),
        name = "Senora National Park"
    },
    {
        coords = vector3(391.47, 3586.7, 33.29),
        name = "Tractor Parts Service"
    },
    {
        coords = vector3(917.44, 3643.32, 32.63),
        name = "Liquor Markt"
    },
    {
        coords = vector3(1368.84, 3605.0, 34.89),
        name = "Hand Carwash"
    },
    {
        coords = vector3(1537.67, 3776.52, 34.52),
        name = "Boat House"
    },
    {
       coords = vector3(1932.13, 3719.61, 32.87),
        name = "Barbers Shop"
    },
    {
       coords = vector3(1859.05, 3681.37, 33.8),
        name = "County Sheriff"
    },
    {
       coords = vector3(1836.82, 3667.99, 33.68),
        name = "Medical Center"
    },
    {
        coords = vector3(1704.09, 3584.02, 35.44),
        name = "Fire Station"
    },
    {
        coords = vector3(2022.57, 3772.83, 32.18),
        name = "Gas Station"
    },
    {
        coords = vector3(2432.71, 3781.53, 40.09),
        name = "Save Life"
    },
    {
        coords = vector3(3514.76, 3761.88, 30.07),
        name = "Human Labs"
    },
    {
        coords = vector3(3797.64, 4471.27, 5.35),
        name = "Fish Farming"
    },
    {
        coords = vector3(3320.88, 5162.98, 18.36),
        name = "Lighthouse"
    },
    {
        coords = vector3(2321.41, 2589.41, 46.65),
        name = "Flower Village"
    },
    {
        coords = vector3(1704.77, 3754.9, 34.34),
        name = "Ammunation Shop"
    },
    {
        coords = vector3(1961.07, 3735.5, 32.38),
        name = "24/7 Supermarkt"
    },
    {
        coords = vector3(1400.52, 3599.21, 35.03),
        name = "Liquor ACE"
    },
    {
        coords = vector3(1781.01, 3318.03, 41.45),
        name = "Airfield Sandy Shores"
    },
    {
        coords = vector3(1960.93, 3835.0, 32.18),
        name = "No Name Bar"
    },
-- Grapeseed
    {
        coords = vector3(2543.87, 4686.01, 33.61),
        name = "Shady Tree Farm"
    },
    {
        coords = vector3(2451.13, 4951.47, 45.05),
        name = "O'Neil Ranch"
    },
    {
        coords = vector3(2020.96, 4967.25, 41.37),
        name = "Union Grain Feld"
    },
    {
        coords = vector3(2097.11, 4759.76, 41.21),
        name = "Airfield Grapeseed"
    },
    {
        coords = vector3(1957.1, 4633.05, 40.81),
        name = "R.L. Hunter"
    },
    {
        coords = vector3(1803.14, 4589.79, 37.53),
        name = "Almao Fruitmarket"
    },
    {
        coords = vector3(1703.85, 4723.52, 42.26),
        name = "Feed Business"
    },
    {
        coords = vector3(1694.24, 4790.76, 41.92),
        name = "Wonderama Arcade Grapeseed"
    },
    {
        coords = vector3(1680.87, 4823.19, 42.05),
        name = "Discount Store Grapeseed"
    },
    {
        coords = vector3(1673.41, 4920.95, 42.03),
        name = "Gas Station Grapeseed"
    },
    {
        coords = vector3(1305.6, 4316.3, 37.84),
        name = "Millar's Fish Farm"
    },
-- Route 63
    {
        coords = vector3(1230.37, 2725.18, 38.0),
        name = "Larrys RV Sales"
    },
    {
        coords = vector3(1204.18, 2655.76, 37.85),
        name = "Route 68 Store"
    },
    {
        coords = vector3(1171.66, 2699.48, 38.18),
        name = "Route 68 Flecca Bank"
    },
    {
        coords = vector3(1140.89, 2663.87, 38.16),
        name = " Route 68Motor Motel"
    },
    {
        coords = vector3(1049.73, 2663.6, 39.55),
        name = "Route 68 Gas Station Cafe"
    },
    {
        coords = vector3(631.94, 2733.31, 41.89),
        name = "Taco Stand"
    },
    {
        coords = vector3(611.71, 2745.17, 41.97),
        name = "Route 68 Fashion Shop"
    },
    {
        coords = vector3(585.87, 2741.77, 42.08),
        name = "Dollar Pills"
    },
    {
        coords = vector3(559.95, 2738.39, 42.2),
        name = "Pet Store"
    },
    {
        coords = vector3(549.58, 2675.68, 42.2),
        name = "24/7 Market"
    },
    {
        coords = vector3(319.22, 2622.77, 44.47),
        name = "24/7 Market"
    },
    {
        coords = vector3(254.16, 2597.33, 44.78),
        name = "All Cars Service"
    },
    {
        coords = vector3(43.97, 2789.11, 57.88),
        name = "Xero Market"
    },
    {
        coords = vector3(-383.17, 2811.79, 45.46),
        name = "Church"
    },
    {
        coords = vector3(-1110.05, 2691.83, 18.6),
        name = "Ammunation Sporting Goods"
    },
    {
        coords = vector3(-2535.97, 2319.72, 33.22),
        name = "Ron Gas Station"
    },
    {
        coords = vector3(-1586.87, 2098.21, 68.69),
        name = "Two Hoots Waterfall"
    },
    {
        coords = vector3(-1923.09, 2061.48, 140.83),
        name = "Marlowe Valley"
    },
    {
        coords = vector3(-1502.86, 1515.44, 115.29),
        name = "White Water Activity Center"
    },
    {
        coords = vector3(184.35, 2791.22, 45.58),
        name = "Warehouse"
    },
    {
        coords = vector3(253.98, 2856.44, 43.57),
        name = "SCW"
    },
    {
        coords = vector3(-83.22, 1885.19, 197.25),
        name = "Farm in Great Chaparral"
    },
    {
        coords = vector3(810.58, 2175.1, 52.31),
        name = "Warehouse on Crossbahn"
    },
    {
        coords = vector3(734.73, 2525.78, 73.23),
        name = "Rebel Radio Station"
    },
     {
        coords = vector3(1246.61, 1868.5, 79.14),
        name = "Blarneys Beer Company"
    },
--Nord Chumash
    {
        coords = vector3(-2215.85, 4272.1, 47.3),
        name = "Hookies Seafood Diner"
    },
    {
        coords = vector3(-1492.42, 4973.21, 63.84),
        name = "Raton Canyon Trails"
    },
--Paleto Bay
    {
        coords = vector3(-766.79, 5580.97, 33.61),
        name = "Pala Springs"
    },
    {
        coords = vector3(-685.62, 5838.17, 17.33),
        name = "Bayview Lodge"
    },
    {
        coords = vector3(-215.63, 6551.73, 11.01),
        name = "Pier Paleto Bay"
    },
    {
        coords = vector3(-426.47, 6027.64, 31.49),
        name = "Sheriff Department Paleto Bay"
    },
    {
        coords = vector3(-392.22, 6128.91, 31.48),
        name = "fire Department Paleto Bay"
    },
    {
        coords = vector3(-403.03, 6144.28, 31.44),
        name = "Post Station"
    },
    {
        coords = vector3(-334.5, 6152.33, 31.49),
        name = "Church Paleto BAy"
    },
    {
        coords = vector3(-289.07, 6203.13, 31.47),
        name = "Tattoo Salon"
    },
    {
        coords = vector3(-249.35, 6212.17, 31.94),
        name = "Pixel Petes Paleto Bay"
    },
    {
        coords = vector3(-293.29, 6253.06, 31.45),
        name = "The Hen House"
    },
    {
        coords = vector3(-283.2, 6239.6, 31.39),
        name = "Barber Shop"
    },
    {
        coords = vector3(-259.12, 6287.41, 31.45),
        name = "Bay Bar"
    },
    {
        coords = vector3(-233.91, 6313.75, 31.47),
        name = "Hospital"
    },
    {
        coords = vector3(-129.34, 6393.11, 31.5),
        name = "Mojito Inn Cafe/Bar"
    },
    {
        coords = vector3(-111.4, 6455.76, 31.47),
        name = "Bank Paleto Bay"
    },
    {
        coords = vector3(-155.65, 6453.48, 31.36),
        name = "South Seas Apartments"
    },
    {
        coords = vector3(-56.85, 6528.53, 31.49),
        name = "Willies Supermarkt"
    },
    {
        coords = vector3(1.42, 6522.68, 31.52),
        name = "Clothing Store Paleto Bay"
    },
    {
        coords = vector3(121.91, 6625.42, 31.95),
        name = "Car Service Paleto Bay"
    },
    {
        coords = vector3(172.85, 6630.64, 31.75),
        name = "Dons Country Store"
    },
     {
        coords = vector3(-39.3, 6410.32, 31.49),
        name = "Morris & Sons"
    },
    {
        coords = vector3(-93.33, 6328.04, 31.49),
        name = "Dream View Motel"
    },
    {
        coords = vector3(-317.12, 6082.31, 31.29),
        name = "Gun Shop Paleto Bay"
    },
    {
        coords = vector3(429.82, 6523.39, 27.85),
        name = "Donkey Punch Family Farm"
    },
    {
        coords = vector3(1586.34, 6450.37, 25.32),
        name = "Rays and Mays Diner"
    },
    {
        coords = vector3(1738.38, 6404.71, 34.93),
        name = "24/7 Shop"
    },
    {
        coords = vector3(-576.92, 5307.82, 70.26),
        text = "Lumber Mill"
    },
}
