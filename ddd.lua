--------------------------------- Initial Setup ---------------------------------
repeat task.wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
if not getgenv().key or getgenv().key == '' or getgenv().key == "" then print("❌ No key provided!") return end
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local HttpService = game:GetService("HttpService")

--------------------------------- Detect Executor & Setup ---------------------------
local hasGetHwid = (gethwid ~= nil)
local executorName = getexecutorname and getexecutorname() or ""
local HttpRequestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or request or http_request

if not HttpRequestFunc then print("❌ Your executor does not support HTTP requests!") return end
if not getexecutorname then print("❌ Your executor does not support getexecutorname!") return end

--------------------------------- Utility Functions ---------------------------------
local function urlEncode(str)
    if not str then return "" end
    str = tostring(str)
    str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return str
end

--------------------------------- Check Whitelist ---------------------------
local workerUrl = "https://api-proxy.phuset-zzii.workers.dev"

local function updateHwid(key, hwid, exploit)
    local requestUrl = workerUrl .. "/rest/v1/keys?key=eq." .. urlEncode(key)
    local body = HttpService:JSONEncode({
        exploit = exploit,
        hwid = hwid,
        status = "Active"
    })
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "PATCH",
        Headers = {
            ["Prefer"] = "return=minimal",
            ["Content-Type"] = "application/json"
        },
        Body = body
    })
    if not response then
        print("❌ updateHwid: No response from Worker")
        return false
    end
    print("updateHwid Status: " .. tostring(response.StatusCode))
    print("updateHwid Body: " .. tostring(response.Body))
    if response.StatusCode >= 400 then
        print("❌ updateHwid: Error " .. response.StatusCode)
        return false
    end
    return response.StatusCode == 200 or response.StatusCode == 204
end

local function logUsage(key, hwid, exploit, userId)
    local requestUrl = workerUrl .. "/rest/v1/logs"
    local body = HttpService:JSONEncode({
        key = key,
        exploit = exploit,
        hwid = hwid,
        user_id = userId,
        used_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
    })
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = body
    })
    if not response then
        print("❌ logUsage: No response from Worker")
        return false
    end
    print("logUsage Status: " .. tostring(response.StatusCode))
    print("logUsage Body: " .. tostring(response.Body))
    if response.StatusCode >= 400 then
        print("❌ logUsage: Error " .. response.StatusCode)
        return false
    end
    return response.StatusCode == 201
end

local function checkKey()
    local key = getgenv().key or ""
    local exploit = getexecutorname()
    local userId = player.UserId
    
    if key == "" then
        print("❌ Key is empty!")
        return false, nil, nil
    end

    local requestUrl = workerUrl .. "/rest/v1/keys?key=eq." .. urlEncode(key)
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    
    if not response then
        print("❌ checkKey: No response from Worker")
        return false, nil, nil
    end
    
    print("checkKey Status: " .. tostring(response.StatusCode))
    print("checkKey Body: " .. tostring(response.Body))
    
    if response.StatusCode >= 500 then
        print("❌ checkKey: Server error (" .. response.StatusCode .. ")")
        return false, nil, nil
    elseif response.StatusCode == 403 then
        print("❌ checkKey: Permission denied")
        return false, nil, nil
    elseif response.StatusCode == 404 then
        print("❌ checkKey: Resource not found")
        return false, nil, nil
    end
    
    if not response.Body then
        print("❌ checkKey: Empty response body")
        return false, nil, nil
    end

    local success, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not success then
        print("❌ checkKey: JSON decode error: " .. tostring(data))
        return false, nil, nil
    }
    
    if not data or type(data) ~= "table" or #data == 0 then
        print("❌ Key not found!")
        return false, nil, nil
    end

    local keyData = data[1]
    local status = keyData.status
    local storedHwid = keyData.hwid
    local storedExploit = keyData.exploit
    local allowedPlaceIds = keyData.allowed_place_ids or {}
    local supportedMaps = keyData.maps or {}
    local allowexec = keyData.allowexec or {}

    local hwid = hasGetHwid and gethwid() or (allowexec and type(allowexec) == "table" and table.find(allowexec, executorName) and game:GetService("RbxAnalyticsService"):GetClientId() or "NO_HWID_" .. executorName)
    if not hwid then
        print("❌ No HWID generated")
        return false, nil, nil
    end

    if status == "Pending" then
        if updateHwid(key, hwid, exploit) then
            print("✅ Key activated! // Exploit: " .. exploit)
            logUsage(key, hwid, exploit, userId)
            return true, allowedPlaceIds, supportedMaps
        else
            print("❌ Failed to activate key!")
            return false, nil, nil
        end
    elseif status == "Active" then
        if not storedHwid or not storedExploit then
            if updateHwid(key, hwid, exploit) then
                print("✅ Updated data // Exploit: " .. exploit)
                logUsage(key, hwid, exploit, userId)
                return true, allowedPlaceIds, supportedMaps
            else
                print("❌ Failed to update data")
                return false, nil, nil
            end
        elseif storedHwid == hwid and storedExploit == exploit then
            logUsage(key, hwid, exploit, userId)
            return true, allowedPlaceIds, supportedMaps
        else
            if storedHwid ~= hwid then print("❌ HWID mismatch") end
            if storedExploit ~= exploit then print("❌ Exploit mismatch: " .. storedExploit .. " // Data: " .. exploit) end
            return false, nil, nil
        end
    else
        print("❌ Invalid key status: " .. tostring(status))
        return false, nil, nil
    end
end

local function checkUserLock()
    local userId = player.UserId
    local charName = player.Name
    local requestUrl = workerUrl .. "/rest/v1/locked_users?user_id=eq." .. urlEncode(userId)
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    
    if not response then
        print("❌ checkUserLock: No response from Worker")
        return false
    end
    
    print("checkUserLock Status: " .. tostring(response.StatusCode))
    print("checkUserLock Body: " .. tostring(response.Body))
    
    if response.StatusCode >= 500 then
        print("❌ checkUserLock: Server error (" .. response.StatusCode .. ")")
        return false
    elseif response.StatusCode == 403 then
        print("❌ checkUserLock: Permission denied")
        return false
    end
    
    if not response.Body then
        print("❌ checkUserLock: Empty response body")
        return false
    end

    local success, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not success then
        print("❌ checkUserLock: JSON decode error: " .. tostring(data))
        return false
    }
    
    if not data or type(data) ~= "table" then
        print("❌ checkUserLock: Invalid response data")
        return false
    end
    
    if #data == 0 then
        return true
    end
    
    local reason = (data[1] and data[1].reason) or "Contact support"
    print("❌ User: " .. charName .. " (ID: " .. userId .. ") is blacklisted // Reason: " .. reason)
    return false
end

local function checkSupportedMap(allowedPlaceIds, supportedMaps)
    if not allowedPlaceIds or #allowedPlaceIds == 0 then
        local mapNames = #supportedMaps > 0 and table.concat(supportedMaps, " / ") or "None"
        print("❌ Unsupported PlaceId: " .. game.PlaceId .. " (Key supports: " .. mapNames .. ")")
        return false
    end
    if not table.find(allowedPlaceIds, game.PlaceId) then
        local mapNames = #supportedMaps > 0 and table.concat(supportedMaps, " / ") or "None"
        print("❌ Unsupported PlaceId: " .. game.PlaceId .. " (Key supports: " .. mapNames .. ")")
        return false
    end
    return true
end

local function performWhitelistCheck()
    local isValidKey, allowedPlaceIds, supportedMaps = checkKey()
    if not isValidKey then return false end
    if not checkUserLock() then return false end
    if not checkSupportedMap(allowedPlaceIds, supportedMaps) then return false end
    print("✅ Whitelist check passed!")
    return true
end

if not performWhitelistCheck() then return end

------------------------------ ScriptHere -------------------------------------


local TeleportService = game:GetService("TeleportService")
local PathfindingService = game:GetService("PathfindingService")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Config
local mainHop = _G.mainHop or 5  
local dungeonHop = _G.dungeonHop or 400 
local enableTeleport = _G.enableTeleport == true 
local targetPlace = _G.targetPlace or "main" 
local dungeonLevel = _G.dungeonLevel or 100
local allowJoin = _G.allowJoin == true 
local dmode = _G.dmode or "e"

local placeMap = {
    ["main"] = 123748395762873,
    ["dungeon"] = 139511259501829
}

local targetGameId = placeMap[targetPlace:lower()] or placeMap["main"]

local startCFrame = CFrame.new(-199.493805, 15.7441902, 27.6950188, -0.543690562, 8.596757e-8, 0.839285731, 6.404197e-8, 1, -6.094295e-8, -0.839285731, 2.0615401e-8, -0.543690562)

local dungeonConfigs = {
    [100] = {
        e = {
            [1] = CFrame.new(-177.694641, 15.5480118, 132.794998, 0.628683925, 5.34754179e-08, -0.777660906, -2.92551174e-08, 1, 4.51137403e-08, 0.777660906, -5.61172264e-09, 0.628683925),
            [2] = CFrame.new(-199.44899, 15.548007, 149.278519, -0.646346867, -1.10499769e-07, 0.763043702, -3.97952142e-08, 1, 1.11105372e-07, -0.763043702, 4.14471231e-08, -0.646346867)
        },
        m = {
            [1] = CFrame.new(-195.904434, 15.5480051, 116.062943, 0.45470196, 6.96520388e-08, -0.890643656, -4.00459683e-08, 1, 5.7759415e-08, 0.890643656, 9.40336964e-09, 0.45470196),
            [2] = CFrame.new(-213.722, 15.5480051, 128.030899, -0.513006687, -8.65471037e-08, 0.858384609, -8.52357331e-08, 1, 4.98851023e-08, -0.858384609, -4.75736535e-08, -0.513006687)
        },
        h = {
            [1] = CFrame.new(-206.893646, 15.5480022, 95.9833908, 0.50477314, -7.05147727e-08, -0.863252044, 7.11124102e-08, 1, -4.01031635e-08, 0.863252044, -4.11449363e-08, 0.50477314),
            [2] = CFrame.new(-226.970016, 15.5480032, 107.365219, -0.416049927, 3.39503572e-08, 0.909341753, -7.17295379e-09, 1, -4.06169214e-08, -0.909341753, -2.34213342e-08, -0.416049927)
        }
    },
    [600] = {
        e = {
            [1] = CFrame.new(-221.118378, 15.5479994, 53.8122101, -0.10023576, -1.57525442e-08, -0.994963706, -8.58711999e-08, 1, -7.18134574e-09, 0.994963706, 8.47189057e-08, -0.10023576),
            [2] = CFrame.new(-243.870331, 15.5479994, 53.8931389, 0.144362316, -7.76575817e-08, 0.989524901, -1.57346687e-08, 1, 8.07752016e-08, -0.989524901, -2.72307421e-08, 0.144362316)
        },
        m = {
            [1] = CFrame.new(-230.383759, 15.5479956, 27.7512169, -0.0042105969, 8.32296934e-08, 0.999991119, 1.08141283e-08, 1, -8.31849007e-08, -0.999991119, 1.04637738e-08, -0.0042105969),
            [2] = CFrame.new(-247.376526, 15.5479956, 27.9295254, 0.0490258858, -1.05333434e-07, 0.998797536, 8.05661138e-09, 1, 1.05064792e-07, -0.998797536, 2.89602897e-09, 0.0490258858)
        },
        h = {
            [1] = CFrame.new(-226.707932, 15.5479956, 3.08944845, 0.986652732, 1.99093133e-08, -0.162838355, -1.33083624e-08, 1, 4.16276649e-08, 0.162838355, -3.89049397e-08, 0.986652732),
            [2] = CFrame.new(-246.55072, 15.5479946, 2.46767831, -0.394230783, 4.52469244e-08, 0.919011474, -3.8458321e-08, 1, -6.57319106e-08, -0.919011474, -6.12571753e-08, -0.394230783)
        }
    },
    [1200] = {
        e = {
            [1] = CFrame.new(-212.55632, 15.5479918, -42.1650848, 0.422885001, 4.03745268e-08, -0.906183362, 3.81329579e-10, 1, 4.47324311e-08, 0.906183362, -1.92622291e-08, 0.422885001),
            [2] = CFrame.new(-227.381912, 15.5479889, -51.9520493, 0.554561257, 5.79606052e-08, 0.832142889, 3.29781313e-09, 1, -7.18499749e-08, -0.832142889, 4.25894626e-08, 0.554561257)
        },
        m = {
            [1] = CFrame.new(-199.649414, 15.5479965, -62.4990959, 0.705783904, -4.45468658e-08, -0.708427191, 1.56071494e-08, 1, -4.73324455e-08, 0.708427191, 2.23499494e-08, 0.705783904),
            [2] = CFrame.new(-215.876999, 15.5479927, -72.6339951, 0.531328261, 5.94664407e-08, 0.847166061, 3.66698956e-08, 1, -9.31932931e-08, -0.847166061, 8.05817209e-08, 0.531328261)
        },
        h = {
            [1] = CFrame.new(-183.941666, 15.5479946, -80.2773972, 0.699560702, 5.7138589e-08, -0.714573205, 1.02867836e-09, 1, 8.09689098e-08, 0.714573205, -5.73777328e-08, 0.699560702),
            [2] = CFrame.new(-197.263901, 15.5479927, -92.066246, 0.664454997, 8.53529869e-08, 0.747328281, 5.13879828e-09, 1, -1.18779774e-07, -0.747328281, 8.27641813e-08, 0.664454997)
        }
    },
    [1500] = {
        e = {
            [1] = CFrame.new(-187.060577, 15.907505, -81.0803909, -0.00439207023, 2.54224997e-08, 0.999990344, -3.26729968e-08, 1, -2.55662478e-08, -0.999990344, -3.27849712e-08, -0.00439207023),
            [2] = CFrame.new(-102.859825, 15.9074984, -137.133652, 0.566411018, -4.57267291e-08, -0.824122906, -1.04471249e-08, 1, -6.26655279e-08, 0.824122906, 4.41041585e-08, 0.566411018),
            [3] = CFrame.new(34.471611, 15.5479956, -93.1514053, -0.138831809, -7.90272665e-08, 0.990315974, -3.08032675e-08, 1, 7.54817577e-08, -0.990315974, -2.00257002e-08, -0.138831809),
            [4] = CFrame.new(48.8399239, 15.5479956, -108.396507, 0.659547091, -6.38960813e-08, -0.751663208, -2.7633078e-08, 1, -1.09252916e-07, 0.751663208, 9.28282162e-08, 0.659547091)
        },
        m = {
            [1] = CFrame.new(-187.060577, 15.907505, -81.0803909, -0.00439207023, 2.54224997e-08, 0.999990344, -3.26729968e-08, 1, -2.55662478e-08, -0.999990344, -3.27849712e-08, -0.00439207023),
            [2] = CFrame.new(-102.859825, 15.9074984, -137.133652, 0.566411018, -4.57267291e-08, -0.824122906, -1.04471249e-08, 1, -6.26655279e-08, 0.824122906, 4.41041585e-08, 0.566411018),
            [3] = CFrame.new(48.8785095, 15.5479956, -76.5747986, -0.717736304, 8.40314698e-08, 0.696314991, 8.63256275e-08, 1, -3.16989173e-08, -0.696314991, 3.73583617e-08, -0.717736304),
            [4] = CFrame.new(63.6830635, 15.5479956, -89.5659332, 0.419869334, 2.59386859e-08, 0.907584548, -4.46230359e-08, 1, -7.93627475e-09, -0.907584548, -3.71669806e-08, 0.419869334)
        },
        h = {
            [1] = CFrame.new(-187.060577, 15.907505, -81.0803909, -0.00439207023, 2.54224997e-08, 0.999990344, -3.26729968e-08, 1, -2.55662478e-08, -0.999990344, -3.27849712e-08, -0.00439207023),
            [2] = CFrame.new(-102.859825, 15.9074984, -137.133652, 0.566411018, -4.57267291e-08, -0.824122906, -1.04471249e-08, 1, -6.26655279e-08, 0.824122906, 4.41041585e-08, 0.566411018),
            [3] = CFrame.new(66.5297699, 15.5479946, -59.6072235, -0.573960304, -6.23015524e-08, -0.818883121, 1.30154305e-08, 1, -8.52037232e-08, 0.818883121, -5.95616712e-08, -0.573960304),
            [4] = CFrame.new(79.1296768, 15.5479946, -71.2087784, 0.655493379, 7.85338514e-08, -0.755200922, -4.35200498e-09, 1, 1.00213256e-07, 0.755200922, -6.2402485e-08, 0.655493379)
        }
    }
}

local function safeTeleport(placeId)
    if not enableTeleport then
        print("Teleport Detected: Disable")
        return
    end
    local success, error = pcall(function()
        TeleportService:Teleport(placeId, player)
    end)
    if success then
        print("Teleporting to Place ID: " .. placeId)
    else
        print("Teleport failed: " .. error)
        if error:match("773") then
            print("Error 773: Ensure Third-Party Teleportation is enabled")
        end
    end
end

local function moveToPosition(targetPosition)
    local path = PathfindingService:CreatePath()
    local success, error = pcall(function()
        path:ComputeAsync(rootPart.Position, targetPosition)
    end)
    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        if waypoints then
            for _, waypoint in pairs(waypoints) do
                humanoid:MoveTo(waypoint.Position)
                humanoid.MoveToFinished:Wait()
            end
        else
            print("Waypoints: nil")
            rootPart.CFrame = CFrame.new(targetPosition)
        end
    else
        print("Pathfinding failed, teleporting instead: " .. (error or "Unknown error"))
        rootPart.CFrame = CFrame.new(targetPosition)
    end
end

local function checkPlayersInServer()
    return #Players:GetPlayers() > 1 
end

if game.PlaceId == 123748395762873 then
    script_key = ""
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Estevansit0/Scripts/refs/heads/main/loader.lua", true))()
    if targetGameId ~= game.PlaceId then
        spawn(function()
            wait(mainHop)
            if enableTeleport then
                print("Teleporting to: " .. targetPlace .. " (GameID: " .. targetGameId .. ") after " .. mainHop .. " seconds")
                safeTeleport(targetGameId)
            else
                print("Hopping Server: Disable")
            end
        end)
    else
        spawn(function()
            while true do
                wait(mainHop)
                if enableTeleport then
                    print("Hopping Server: after " .. mainHop .. " seconds")
                    safeTeleport(game.PlaceId)
                else
                    print("Hopping Server: Disable")
                    break
                end
            end
        end)
    end

elseif game.PlaceId == 75959166903570 or game.PlaceId == 80157158224004 or game.PlaceId == 126000682773050 or game.PlaceId == 88115991272896 then
    if not allowJoin then
        local timeout = 10 
        local elapsed = 0
        while elapsed < timeout do
            if checkPlayersInServer() then
                print("Found other players in server")
                safeTeleport(139511259501829)
                return 
            end
            wait(1)
            elapsed = elapsed + 1
        end
        print("No other players found after " .. timeout .. " seconds")
    else
        print("Players Check: Disable")
    end
  
    script_key = ""
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Estevansit0/Scripts/refs/heads/main/loader.lua", true))()
    if not allowJoin then
        spawn(function()
            while true do
                if checkPlayersInServer() then
                    print("Found other players in server")
                    safeTeleport(139511259501829)
                    return
                end
                wait(5)
            end
        end)
    end

    local playerGui = player:WaitForChild("PlayerGui", 10)
    if not playerGui then return end

    spawn(function()
        wait(dungeonHop)
        if enableTeleport then
            print("Time's up, after " .. dungeonHop .. " seconds")
            safeTeleport(139511259501829)
        else
            print("Teleport Detected: enableTeleport <false>")
        end
    end)

    local function tryTeleport()
        local success, victoryFrame = pcall(function()
            return playerGui:FindFirstChild("DungeonProgress") and
                   playerGui.DungeonProgress:FindFirstChild("Background") and
                   playerGui.DungeonProgress.Background:FindFirstChild("Victory")
        end)
        if success and victoryFrame and victoryFrame.Visible then
            wait(2)
            if enableTeleport then
                print("Victory Detected: <true>")
                safeTeleport(139511259501829)
            else
                print("Victory Detected: enableTeleport <false>")
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
    local config = dungeonConfigs[dungeonLevel][dmode] or dungeonConfigs[dungeonLevel].e
    
    if character and rootPart and humanoid then
        wait(1)
        print("Moving to Start position")
        moveToPosition(startCFrame.Position)
        
spawn(function()
    for i = 1, #config do
        print("Moving to Target" .. i .. ": Level " .. dungeonLevel .. " Difficulty " .. dmode)
        moveToPosition(config[i].Position)
    end

    local lastPoint = #config
    if lastPoint > 1 then
        while true do
            wait(12) 
            print("Returning: Target " .. lastPoint .. " -> Target " .. (lastPoint - 1) .. " -> Target " .. lastPoint)
            moveToPosition(config[lastPoint - 1].Position) 
            moveToPosition(config[lastPoint].Position) 
        end
    else
        while true do
            wait(12)
            print("Staying at Target " .. lastPoint .. ": Level " .. dungeonLevel .. " Difficulty " .. dmode)
        end
    end
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
            if success and victoryFrame and victoryFrame.Visible then
                wait(2)
                if enableTeleport and game.PlaceId == targetGameId then
                    safeTeleport(targetGameId)
                else
                    print("Victory Detected: enableTeleport <false>")
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
