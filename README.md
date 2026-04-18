# NPC Taxijob for QBCore

![NPC Taxijob Script](.github-assets/title.png)

An NPC-based taxi job for QBCore with dispatcher jobs, customer pickups, taximeter UI, driver rating, configurable penalties, and persistent rating progress.

## Features

- NPC dispatcher and configurable job locations
- Taxi vehicle spawn and return flow
- NPC passenger pickups with destination routes
- Custom taximeter UI and taxi notifications
- Driver rating system with database persistence
- Bonus and penalty system configurable through `config.lua`
- Automatic termination and rehire lock handling
- Debug location display toggle through `shared/locations.lua`

## Requirements

- QBCore
- oxmysql

## Installation

1. Place the resource in your server `resources` folder.
2. Ensure `oxmysql` is started before this resource.
3. Add `ensure npc-taxijob` to your server config.
4. Adjust `config.lua` and `shared/locations.lua` to your server setup.

## Notes

- The rating data is stored in the database and reset when the player leaves or is removed from the taxi company.
- `config.old.bak` is kept local as a backup and is ignored by git.
