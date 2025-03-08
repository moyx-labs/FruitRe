--[[

 _   .-')    
( '.( OO )_  
 ,--.   ,--.)
 |   `.'   | 
 |         | 
 |  |'.'|  | 
 |  |   |  | 
 |  |   |  | 
 `--'   `--' 

]]--

repeat wait() until game:IsLoaded()
wait(8)

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
repeat wait() until player.Character
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")

-- ใช้ค่า config จาก _G หรือกำหนดค่าเริ่มต้นถ้าไม่พบ
local mainHop = _G.mainHop or 60
local dungeonHop = _G.dungeonHop or 300
local enableTeleport = _G.enableTeleport or true
local targetPlace = _G.targetPlace or "main"
local dungeonLevel = _G.dungeonLevel or 1200

-- Mapping ชื่อไปยัง Game ID
local placeMap = {
    ["main"] = 123748395762873,
    ["dungeon"] = 139511259501829
}

-- แปลง targetPlace เป็น Game ID
local targetGameId = placeMap[targetPlace:lower()] or placeMap["main"]

-- Config สำหรับดันเจี้ยน (เฉพาะ Game ID: 139511259501829)
local dungeonConfigs = {
    [1200] = {
        teleportCFrame = CFrame.new(-225.706253, 15.8267012, 66.6150665, -0.741998672, 1.39716789e-08, 0.670401335, 2.29041035e-08, 1, 4.50944215e-09, -0.670401335, 1.8700943e-08, -0.741998672),
        targetCFrame = CFrame.new(-235.21228, 15.8267012, 75.4034576, -0.752270281, -2.74759095e-08, 0.658854663, 2.67198637e-08, 1, 7.22108737e-08, -0.658854663, 7.19265998e-08, -0.752270281)
    },
    [1500] = {
        teleportCFrame = CFrame.new(-195.884064, 15.7415295, -70.4139023, 0.152334943, -3.57731729e-08, 0.988328934, -2.19380625e-09, 1, 3.65337556e-08, -0.988328934, -7.73356934e-09, 0.152334943),
        targetCFrame = CFrame.new(-207.992157, 15.7415228, -74.1903839, 0.167791769, -8.41429113e-08, 0.985822439, -2.69223452e-08, 1, 8.99353196e-08, -0.985822439, -4.16310613e-08, 0.167791769)
    }
}

-- ฟังก์ชันสร้างโฟลเดอร์ Moyx
local function EnsureMoyxFolder()
    if not isfolder("Moyx") then
        makefolder("Moyx")
    end
end

-- ฟังก์ชัน Teleport ทั่วไป
local function safeTeleport(placeId)
    if not enableTeleport then
        print("Teleport is disabled")
        return
    end

    local AllIDs = {}
    local foundAnything = ""
    local actualHour = os.date("!*t").hour

    -- โหลดไฟล์ NotSameServers.json ถ้ามี (สำหรับ main)
    if placeId == 123748395762873 then
        EnsureMoyxFolder()
        local FileSuccess, FileError = pcall(function()
            if isfile and readfile and isfile("Moyx/NotSameServers.json") then
                AllIDs = HttpService:JSONDecode(readfile("Moyx/NotSameServers.json"))
            end
        end)
        if not FileSuccess then
            print("Failed to load Moyx/NotSameServers.json: " .. FileError)
            table.insert(AllIDs, actualHour)
        end
    end

    local function TPReturner()
        local Site
        local success, result = pcall(function()
            if foundAnything == "" then
                return HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                return HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
        end)

        if not success then
            print("Failed to fetch servers: " .. result)
            return false
        end

        Site = result
        local ID = ""
        if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
            foundAnything = Site.nextPageCursor
        end

        for i, v in pairs(Site.data) do
            local Possible = true
            ID = tostring(v.id)
            if tonumber(v.maxPlayers) > tonumber(v.playing) then
                for _, Existing in pairs(AllIDs) do
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                end
                if Possible then
                    table.insert(AllIDs, ID)
                    local teleportSuccess, teleportError = pcall(function()
                        if placeId == 123748395762873 then
                            EnsureMoyxFolder()
                            writefile("Moyx/NotSameServers.json", HttpService:JSONEncode(AllIDs))
                        end
                        TeleportService:TeleportToPlaceInstance(tonumber(placeId), ID, player)
                    end)
                    if teleportSuccess then
                        print("Teleporting to server: " .. ID)
                        wait(4)
                        return true
                    else
                        print("Teleport failed: " .. teleportError)
                        if teleportError:match("773") then
                            print("Error 773: Ensure Third-Party Teleportation is enabled")
                        end
                    end
                end
            end
        end
        return false
    end

    local attempt = 0
    local maxAttempts = 5
    while attempt < maxAttempts do
        if TPReturner() then
            break
        end
        wait(5)
        attempt = attempt + 1
    end
    if attempt >= maxAttempts then
        print("Teleport failed after " .. maxAttempts .. " attempts.")
    end
end

-- 逻辑ตาม Game ID
if game.PlaceId == 123748395762873 then
    -- ฟาร์มใน Game ID: 123748395762873
    while not player:FindFirstChild("leaderstats") do
        wait(1)
    end
    while not player.leaderstats:FindFirstChild("Level") do
        wait(1)
    end

    getgenv().DeleteFile = false
    getgenv().OvKey = ""
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Estevansit0/Scripts/refs/heads/main/loader.lua", true))()

    -- ถ้า targetPlace ไม่ใช่ "main" ให้ teleport ไป targetGameId
    if targetGameId ~= game.PlaceId then
        spawn(function()
            wait(mainHop)
            if enableTeleport then
                print("Teleporting to target place: " .. targetPlace .. " (Game ID: " .. targetGameId .. ") after " .. mainHop .. " seconds")
                safeTeleport(targetGameId)
            end
        end)
    else
        -- ถ้า targetPlace เป็น "main" ให้ hop เซิร์ฟทุก mainHop วินาที
        spawn(function()
            while enableTeleport do
                wait(mainHop)
                print("Hopping server in 'main' after " .. mainHop .. " seconds")
                safeTeleport(game.PlaceId) -- Hop ไปเซิร์ฟใหม่ใน Game ID เดียวกัน
            end
        end)
    end

elseif game.PlaceId == 80157158224004 or game.PlaceId == 75959166903570 then
    -- ฟาร์มใน Game ID: 80157158224004 หรือ 75959166903570 และ teleport ไป targetGameId
    getgenv().DeleteFile = false
    getgenv().OvKey = ""
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Estevansit0/Scripts/refs/heads/main/loader.lua", true))()

    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then
        return
    end

    spawn(function()
        wait(dungeonHop)
        if enableTeleport and game.PlaceId ~= targetGameId then
            print("Teleporting to target place: " .. targetPlace .. " (Game ID: " .. targetGameId .. ") after " .. dungeonHop .. " seconds")
            safeTeleport(targetGameId)
        end
    end)

    local function tryTeleport()
        local success, victoryFrame = pcall(function()
            return playerGui:FindFirstChild("DungeonProgress") and
                   playerGui.DungeonProgress:FindFirstChild("Background") and
                   playerGui.DungeonProgress.Background:FindFirstChild("Victory")
        end)
        
        if success and victoryFrame then
            if victoryFrame.Visible == true then
                wait(2)
                if enableTeleport and game.PlaceId ~= targetGameId then
                    safeTeleport(targetGameId)
                end
            end
        end
    end

    spawn(function()
        while true do
            tryTeleport()
            wait(1)
        end
    end)

elseif game.PlaceId == 139511259501829 then
    -- ฟาร์มในดันเจี้ยน (Game ID: 139511259501829)
    local config = dungeonConfigs[dungeonLevel] or dungeonConfigs[1200]
    local teleportCFrame = config.teleportCFrame
    local targetCFrame = config.targetCFrame

    if character and rootPart and humanoid then
        rootPart.CFrame = teleportCFrame
        wait(8)
        spawn(function()
            local targetPosition = targetCFrame.Position
            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()
        end)
    end

    local playerGui = player:WaitForChild("PlayerGui", 10)
    if playerGui then
        local function tryTeleport()
            local success, victoryFrame = pcall(function()
                return playerGui:FindFirstChild("DungeonProgress") and
                       playerGui.DungeonProgress:FindFirstChild("Background") and
                       playerGui.DungeonProgress.Background:FindFirstChild("Victory")
            end)
            
            if success and victoryFrame then
                if victoryFrame.Visible == true then
                    wait(2)
                    if enableTeleport and game.PlaceId ~= targetGameId then
                        safeTeleport(targetGameId)
                    end
                end
            end
        end

        spawn(function()
            while true do
                tryTeleport()
                wait(1)
            end
        end)
    end
end
