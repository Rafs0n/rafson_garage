# 🚗 Rafson Garage - Advanced Garage System for FiveM

Welcome to **Rafson Garage**, an advanced and efficient garage system designed for **FiveM**, fully compatible with the **QBCore** and **ESX Frameworks**. This script includes a VIN generation feature and seamless integration with the radial menu for easy access to garages.

---

## ✨ Features

- **🔢 Generate Unique VIN Numbers** for vehicles.
- **🛠 Full Support for QBCore & ESX Frameworks.**
- **🎯 Target System Compatibility:**
  - ✅ **ox_target**  
  - ✅ **qb-target**  
- **⚡ Optimized Performance**, ensuring smooth gameplay.
- **🔧 Easy to Configure** for custom garage points.
- **🌀 Dynamic Menu Management**, only showing garage options when nearby.
- **🚘 Customizable Garage Locations** via `config.lua`.
- **🗄 Interaction Options:**
  - 👨‍🔧 **Ped Interaction** – Interact with NPCs to access garages.
  - 🌀 **Radial Menu Integration** – Open the garage directly via radial menu.
- **🔧 Easily configurable** in **`config.lua`**.

---

## 🛠 Configuration

To configure how players interact with garages, open the `config.lua` file and adjust the following setting:

```lua
Config.UseRadialMenu = true  -- Set to 'false' to use ped interaction instead of radial menu.


## 🛠 Installation Guide

1. Download the script and place it in your FiveM `resources` folder.

2. Add the following line to your `server.cfg` or `resources.cfg`:
    ```
    ensure rafson_garage
    ```

3. Import the appropriate SQL file based on your framework:

   - **For QBCore:** Import `qb.sql`  
   - **For ESX:** Import `esx.sql`

4. In `config.lua`, uncomment the framework you are using and comment out the other.
   Example:
   ```lua
   -- Uncomment for QBCore
   -- QBCore = exports['qb-core']:GetCoreObject() 

   -- Uncomment for ESX
   -- ESX = exports["es_extended"]:getSharedObject()

---

## 🔢 Generate VIN Function

The VIN (Vehicle Identification Number) feature allows you to assign a unique identifier to vehicles in your server.

### **Usage Example:**

To generate a VIN, use the following code in any part of your script:

```lua
local vin = GenerateVin()
function GenerateVin()
    local vin = ''

    local chars = {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
        'N', 'P', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
    }

    for i = 1, 10 do
        vin = vin .. chars[math.random(1, #chars)]
    end

    return vin
end
```

## 🔧 QBCore Integration
If you're using QBCore, follow the steps below to integrate Rafson Garage into your radial menu.

Add the following code to qb-radialmenu/client/main.lua to dynamically show the garage option when the player is nearby:
```

local garageIndex = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        local nearestGarage = exports['rafson_garage']:GetClosestGarage()

        if nearestGarage then
            local garageOptionAdded = {
                id = optionid,
                title = 'Open Garage',
                icon = 'warehouse',
                type = 'client',
                event = 'rafson_garage:openGarage',
                shouldClose = true
            }
            garageIndex = exports['qb-radialmenu']:AddOption(garageOptionAdded, garageIndex)
        else
            if garageIndex then
                exports['qb-radialmenu']:RemoveOption(garageIndex)
                garageIndex = nil
            end
        end
    end
end)

```


## 🔧 ESX Integration



If you're using ESX, follow the steps below to integrate Rafson Garage into your radial menu.
Add the following code to (radialmenu/config.lua) to dynamically show the garage option when the player is nearby:
```
    {
        id = 'mainmenu',
        addElement = function()
            local garage = exports['rafson_garage']:GetClosestGarage()
            if garage ~= nil and not IsPedInAnyVehicle(PlayerPedId(), false) then
                return true
            end
            return false
        end,
        items = {
            {
                id    = 'garage',
                title = 'Garage',
                icon = '#warehouse',
                type = 'client',
                event = 'rafson_garage:openGarage',
                shouldClose = true,
            }
        }
    },
```

-- Paste this to <svg id="icons"> in (radialmenu/html/index.html)


```
            <svg id="warehouse" width="64" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M32 2L4 16V56C4 57.0609 4.42143 58.0783 5.17157 58.8284C5.92172 59.5786 6.93913 60 8 60H56C57.0609 60 58.0783 59.5786 58.8284 58.8284C59.5786 58.0783 60 57.0609 60 56V16L32 2ZM56 56H8V20L32 8L56 20V56ZM20 48H12V36H20V48ZM36 48H28V28H36V48ZM52 48H44V44H52V48ZM52 40H44V36H52V40ZM52 32H44V28H52V32Z" fill="white"/>
            </svg>

```

## 🔗 Support
If you need any help or have questions regarding the script, feel free to join our Discord server:
**👉 Discord Support - https://discord.gg/BZTWb2bXgR**



Watch tutorial videos and learn more about our scripts on YouTube:
**👉 YouTube Channel - https://www.youtube.com/@rafson3982**

## 📜 License
This script is licensed, and unauthorized distribution is prohibited.

Thank you for using **Rafson Garage**! If you enjoy it, please consider leaving a review on our Tebex store. 🚘✨
