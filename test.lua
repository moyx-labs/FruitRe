--------------------------------- Initial Setup ---------------------------------
repeat task.wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
if not getgenv().key or getgenv().key == '' or getgenv().key == "" then print("...") return end
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

--------------------------------- Detect Executor & Setup ---------------------------
local hasGetHwid = (gethwid ~= nil)
local executorName = getexecutorname and getexecutorname() or ""
local HttpRequestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or request or http_request
local OriginalHttpFunc = HttpRequestFunc

if not HttpRequestFunc then print("❌ Your executor does not support HTTP requests!") return end
if not getexecutorname then print("❌ Your executor does not support getexecname!") return end

--------------------------------- Anti-Crack ---------------------------
local function dummyCheck()
    return 424242
end
local dummyResult = dummyCheck()
local function checkHookTamper()
    local newResult = dummyCheck()
    if newResult ~= dummyResult then print("❌ Function Tampering Detected!") return false end
    local testVal = os.time()
    if testVal == 0 then print("❌ Time Function Tampering Detected!") return false end
    return true
end

--------------------------------- Anti-Crack for gethwid Executors ---------------------------------
local function generateSecureKey(data)
    if not data or type(data) ~= "string" then print("❌ Invalid Data for Key!") return "" end
    local seed = os.time() + game.PlaceId + Players.LocalPlayer.UserId
    local key = ""
    for i = 1, #data do
        local char = string.byte(data, i) or 0
        key = key .. string.char(bit32.bxor(char, bit32.bxor(seed, i) % 256))
    end
    return key
end

local secureHttp = {}
local secureMt = {
    __call = function(_, req)
        if not checkHookTamper() then return nil end
        if type(OriginalHttpFunc) ~= "function" or pcall(OriginalHttpFunc, {Url = "https://example.com", Method = "GET"}) == false then print("❌ HTTP Function Corrupted!") return nil end
        if req.Url and req.Method and string.match(req.Url, "^https://api%-proxy%.phuset%-zzii%.workers%.dev") then
            local encodedReq = {
                Url = generateSecureKey(req.Url),
                Method = req.Method,
                Headers = req.Headers,
                Body = req.Body and generateSecureKey(req.Body) or nil
            }
            local response = OriginalHttpFunc(req)
            if response and response.Body then response.Body = generateSecureKey(response.Body) end
            if response.StatusCode and (response.StatusCode < 200 or response.StatusCode >= 400) then print("❌ Invalid Response Status: " .. tostring(response.StatusCode)) return nil end
            return response
        else 
            print("❌ Invalid HTTP Request! Must use Worker URL")
            return nil 
        end
    end,
    __index = function() return nil end,
    __newindex = function() print("❌ Attempt to Modify Secure HTTP!") return nil end
}
if hasGetHwid then setmetatable(secureHttp, secureMt) HttpRequestFunc = secureHttp end

local function generateChecksum()
    local code = tostring(generateSecureKey) .. tostring(checkHookTamper) .. tostring(dummyCheck)
    local sum = 0
    for i = 1, #code do
        sum = sum + string.byte(code, i)
    end
    return sum
end
local originalChecksum = hasGetHwid and generateChecksum() or nil
local function verifyIntegrity()
    if not hasGetHwid then return true end
    if generateChecksum() ~= originalChecksum then print("❌ Code Integrity Violation!") return false end
    local testTime = os.time()
    if testTime < 1 then print("❌ Runtime Tampering Detected!") return false end
    return true
end

local originalKey = getgenv().key
local function checkEnvTamper()
    if getgenv().key ~= originalKey then print("❌ Environment Key Tampering Detected!") return false end
    return true
end

local startTime = os.time()
local function checkTimeout()
    if os.time() - startTime > 5 then print("❌ Execution Timeout!") return false end
    return true
end

--------------------------------- HWID Generation ---------------------------------
local function getFingerprint(allowexec)
    if hasGetHwid then 
        return gethwid() 
    elseif allowexec and type(allowexec) == "table" and table.find(allowexec, executorName) then
        return game:GetService("RbxAnalyticsService"):GetClientId() or "NO_HWID_" .. executorName
    else
        print("❌ No Support: " .. executorName)
        return nil
    end
end

--------------------------------- Check Whitelist ---------------------------
local workerUrl = "https://api-proxy.phuset-zzii.workers.dev" 
local HttpService = game:GetService("HttpService")

local function updateHwid(key, hwid, exploit)
    local requestUrl = workerUrl .. "/rest/v1/keys?key=eq." .. key
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "PATCH",
        Headers = {
            ["Prefer"] = "return=minimal",
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            exploit = exploit,
            hwid = hwid,
            status = "Active"
        })
    })
    return response and (response.StatusCode == 200 or response.StatusCode == 204)
end

local function logUsage(key, hwid, exploit, userId)
    local requestUrl = workerUrl .. "/rest/v1/logs"
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            key = key,
            exploit = exploit,
            hwid = hwid,
            user_id = userId,
            used_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
        })
    })
    return response and response.StatusCode == 201
end

local function checkKey()
    if not verifyIntegrity() or not checkEnvTamper() then return false, nil, nil end
    local key = getgenv().key or ""
    local exploit = getexecutorname()
    local userId = player.UserId
    
    if key == "" then print("❌ Key?") return false, nil, nil end

    local requestUrl = workerUrl .. "/rest/v1/keys?key=eq." .. key
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    if not response or not response.Body then print("❌ Failed to Fetch: Data") return false, nil, nil end

    local decodedBody = hasGetHwid and generateSecureKey(response.Body) or response.Body
    local data = HttpService:JSONDecode(decodedBody)
    if not data or type(data) ~= "table" or #data == 0 then print("❌ Key Not Found!") return false, nil, nil end

    local keyData = data[1]
    local status = keyData.status
    local storedHwid = keyData.hwid
    local storedExploit = keyData.exploit
    local allowedPlaceIds = keyData.allowed_place_ids or {}
    local supportedMaps = keyData.maps or {}
    local allowexec = keyData.allowexec or {}

    local hwid = getFingerprint(allowexec)
    if not hwid then return false, nil, nil end

    if status == "Pending" then
        if updateHwid(key, hwid, exploit) then 
            print("✅ Key Activated! // Exploit: " .. exploit) 
            logUsage(key, hwid, exploit, userId) 
            return true, allowedPlaceIds, supportedMaps
        else 
            print("❌ Failed to Activate Key!") 
            return false, nil, nil 
        end
    elseif status == "Active" then
        if not storedHwid or not storedExploit then
            if updateHwid(key, hwid, exploit) then 
                print("✅ Updated Data // Exploit: " .. exploit) 
                logUsage(key, hwid, exploit, userId) 
                return true, allowedPlaceIds, supportedMaps
            else 
                print("❌ Failed to Update: Data") 
                return false, nil, nil 
            end
        elseif storedHwid == hwid and storedExploit == exploit then 
            logUsage(key, hwid, exploit, userId) 
            return true, allowedPlaceIds, supportedMaps
        else
            if storedHwid ~= hwid then print("❌ HWID Mismatch") end
            if storedExploit ~= exploit then print("❌ Exploit Mismatch: " .. storedExploit .. " // Data: " .. exploit) end
            return false, nil, nil
        end
    else 
        return false, nil, nil 
    end
end

local function checkUserLock()
    if not verifyIntegrity() or not checkEnvTamper() then return false end
    local userId = player.UserId
    local charName = player.Name
    local requestUrl = workerUrl .. "/rest/v1/locked_users?user_id=eq." .. userId
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json"
        }
    })
    if not response or not response.Body then print("❌ Failed to Fetch: LData") return false end

    local decodedBody = hasGetHwid and generateSecureKey(response.Body) or response.Body
    local data = HttpService:JSONDecode(decodedBody)
    if not data or type(data) ~= "table" then return false end
    if #data == 0 then return true end
    local reason = (data[1] and data[1].reason) or "DM Discord: Moyx#5001"
    print("❌ User: " .. charName .. " (ID: " .. userId .. ") is Blacklisted // (Reason: " .. reason ..")")
    return false
end

local function checkSupportedMap(allowedPlaceIds, supportedMaps)
    if not verifyIntegrity() or not checkEnvTamper() then return false end
    if not allowedPlaceIds or #allowedPlaceIds == 0 then
        local mapNames = #supportedMaps > 0 and table.concat(supportedMaps, " / ") or "None"
        print("❌ Unsupported PlaceId: " .. game.PlaceId .. " (Key Supports: " .. mapNames .. ")")
        return false
    end
    if not table.find(allowedPlaceIds, game.PlaceId) then
        local mapNames = #supportedMaps > 0 and table.concat(supportedMaps, " / ") or "None"
        print("❌ Unsupported PlaceId: " .. game.PlaceId .. " (Key Supports: " .. mapNames .. ")")
        return false
    end
    return true
end

local function performWhitelistCheck()
    if not checkTimeout() then return false end
    local isValidKey, allowedPlaceIds, supportedMaps = checkKey()
    if not isValidKey then return false end
    if not checkUserLock() then return false end
    if not checkSupportedMap(allowedPlaceIds, supportedMaps) then return false end
    print("✅ Whitelist!")
    return true
end

if not performWhitelistCheck() then return end

------------------------------ ScriptHere -------------------------------------

print("TW")
