--------------------------------- Initial Setup ---------------------------------
repeat task.wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
if not getgenv().key or getgenv().key == '' and getgenv().key == "" then end
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
--------------------------------- Request HWID/Exploit ---------------------------
local HttpRequestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or request or http_request
local OriginalHttpFunc = HttpRequestFunc -- Store original reference

if not HttpRequestFunc then
    print("❌ Your executor does not support HTTP requests!")
    return
end
if not getexecutorname then
    print("❌ Your executor does not support getexecutorname!")
    return
end

--------------------------------- Anti-Crack ---------------------------
local function dummyCheck()
    return 424242
end
local dummyResult = dummyCheck()
local function checkHookTamper()
    local newResult = dummyCheck()
    if newResult ~= dummyResult then 
        print("❌ Function Tampering Detected!")
        return false
    end
    local testVal = os.time()
    if testVal == 0 then
        print("❌ Time Function Tampering Detected!")
        return false
    end
    return true
end

-- Secure Key Generation
local function generateSecureKey(data)
    if not data or type(data) ~= "string" then
        print("❌ Invalid Data for Key!")
        return ""
    end
    local seed = os.time() + game.PlaceId + Players.LocalPlayer.UserId
    local key = ""
    for i = 1, #data do
        local char = string.byte(data, i) or 0
        key = key .. string.char(bit32.bxor(char, bit32.bxor(seed, i) % 256))
    end
    return key 
end

-- Secure HTTP Wrapper
local secureHttp = {}
local secureMt = {
    __call = function(_, req)
        if not checkHookTamper() then return nil end
        if type(OriginalHttpFunc) ~= "function" or pcall(OriginalHttpFunc, {Url = "https://example.com", Method = "GET"}) == false then
            print("❌ HTTP Function Corrupted!")
            return nil
        end
        if req.Url and req.Method and string.match(req.Url, "^https://iuxhbfecfllkrpuxucni%.supabase%.co") then
            local encodedReq = {
                Url = generateSecureKey(req.Url),
                Method = req.Method,
                Headers = req.Headers,
                Body = req.Body and generateSecureKey(req.Body) or nil
            }
            local response = OriginalHttpFunc(req)
            if response and response.Body then
                response.Body = generateSecureKey(response.Body) 
            end
            if response.StatusCode and (response.StatusCode < 200 or response.StatusCode >= 400) then
                print("❌ Invalid Response Status: " .. tostring(response.StatusCode))
                return nil
            end
            return response
        else
            print("❌ Invalid HTTP Request!")
            return nil
        end
    end,
    __index = function() return nil end,
    __newindex = function() print("❌ Attempt to Modify Secure HTTP!") return nil end
}
setmetatable(secureHttp, secureMt)
HttpRequestFunc = secureHttp

-- Integrity Check
local function generateChecksum()
    local code = tostring(generateSecureKey) .. tostring(checkHookTamper) .. tostring(dummyCheck)
    local sum = 0
    for i = 1, #code do
        sum = sum + string.byte(code, i)
    end
    return sum
end
local originalChecksum = generateChecksum()
local function verifyIntegrity()
    if generateChecksum() ~= originalChecksum then
        print("❌ Code Integrity Violation!")
        return false
    end
    local testTime = os.time()
    if testTime < 1 then
        print("❌ Runtime Tampering Detected!")
        return false
    end
    return true
end

-- Anti-Environment Tampering
local originalKey = getgenv().key
local function checkEnvTamper()
    if getgenv().key ~= originalKey then
        print("❌ Environment Key Tampering Detected!")
        return false
    end
    return true
end

-- Timeout 
local startTime = os.time()
local function checkTimeout()
    if os.time() - startTime > 5 then
        print("❌ Execution Timeout!")
        return false
    end
    return true
end

--------------------------------- Check Whitelist ---------------------------
local supabaseUrl = "https://iuxhbfecfllkrpuxucni.supabase.co"
local supabaseApiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1eGhiZmVjZmxsa3JwdXh1Y25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MTU0NDQsImV4cCI6MjA1ODQ5MTQ0NH0.x7lOtHcHZ5QuimSLNT2WyrSdLN6ebDTuCwLl5H01ftQ"
local HttpService = game:GetService("HttpService")

local function getFingerprint()
    if gethwid then
        return gethwid()
    else
        return getexecutorname() -- Use exploit name if gethwid is not supported
    end
end

local function updateHwid(key, hwid, exploit)
    local requestUrl = supabaseUrl .. "/rest/v1/keys?key=eq." .. key
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "PATCH",
        Headers = {
            ["apikey"] = supabaseApiKey,
            ["Authorization"] = "Bearer " .. supabaseApiKey,
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
    local requestUrl = supabaseUrl .. "/rest/v1/logs"
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "POST",
        Headers = {
            ["apikey"] = supabaseApiKey,
            ["Authorization"] = "Bearer " .. supabaseApiKey,
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
    local hwid = getFingerprint()
    local exploit = getexecutorname()
    local userId = player.UserId
    
    if not hwid then
        print("❌ Failed to get HWID or Exploit Name")
        return false, nil, nil
    end
    if key == "" then
        print("❌ Key?")
        return false, nil, nil
    end

    local requestUrl = supabaseUrl .. "/rest/v1/keys?key=eq." .. key
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["apikey"] = supabaseApiKey,
            ["Authorization"] = "Bearer " .. supabaseApiKey,
            ["Content-Type"] = "application/json"
        }
    })
    if not response or not response.Body then
        print("❌ Failed to Fetch: Data")
        return false, nil, nil
    end

    local decodedBody = generateSecureKey(response.Body)
    local data = HttpService:JSONDecode(decodedBody)
    if #data > 0 then
        local keyData = data[1]
        local status = keyData.status
        local storedHwid = keyData.hwid
        local storedExploit = keyData.exploit
        local allowedPlaceIds = keyData.allowed_place_ids or {} 
        local supportedMaps = keyData.maps or {} 

        if status == "Pending" then
            if updateHwid(key, hwid, exploit) then
                print("✅ Key Activated! // Exploit: " .. exploit)
                logUsage(key, hwid, exploit, userId) 
                return true, allowedPlaceIds, supportedMaps
            else
                print("❌ Failed to Activate Key")
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
            elseif not gethwid then -- Auto-pass whitelist if gethwid is not supported
                if updateHwid(key, hwid, exploit) then
                    print("✅ Auto-Passed Whitelist (No HWID Support) // Exploit: " .. exploit)
                    logUsage(key, hwid, exploit, userId)
                    return true, allowedPlaceIds, supportedMaps
                else
                    print("❌ Failed to Update: Data")
                    return false, nil, nil
                end
            else
                if storedHwid ~= hwid then
                    print("❌ HWID Mismatch")
                end
                if storedExploit ~= exploit then
                    print("❌ Exploit Mismatch: " .. storedExploit .. " // Data: " .. exploit)
                end
                return false, nil, nil
            end
        else
            return false, nil, nil
        end
    else
        print("❌ Key Not Found!")
        return false, nil, nil
    end
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

local function checkUserLock()
    if not verifyIntegrity() or not checkEnvTamper() then return false end
    local userId = player.UserId
    local charName = player.Name
    local requestUrl = supabaseUrl .. "/rest/v1/locked_users?user_id=eq." .. userId
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["apikey"] = supabaseApiKey,
            ["Authorization"] = "Bearer " .. supabaseApiKey,
            ["Content-Type"] = "application/json"
        }
    })
    if not response or not response.Body then
        print("❌ Failed to Fetch: LData")
        return false
    end

    local decodedBody = generateSecureKey(response.Body)
    local data = HttpService:JSONDecode(decodedBody)
    if #data == 0 then return true end
    local reason = (data[1] and data[1].reason)
    if not reason or reason == "" then reason = "DM Discord: Moyx#5001" end
    if #data > 0 then
        print("❌ User: " .. charName .. " (ID: " .. userId .. ") is Blacklisted // (Reason: " .. reason ..")")
        return false
    end
    return true
end

local function performWhitelistCheck()
    if not checkTimeout() then return false end
    local isValidKey, allowedPlaceIds, supportedMaps = checkKey()
    if not isValidKey then return false end
    if not checkSupportedMap(allowedPlaceIds, supportedMaps) then return false end
    if not checkUserLock() then return false end
    print("✅ Whitelist!")
    return true 
end
if not performWhitelistCheck() then return end 

------------------------------ ScriptHere -------------------------------------
print("W")
