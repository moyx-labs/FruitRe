-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- Supabase Configuration
local SUPABASE_URL = "https://eusxbcbwyhjtfjplwtst.supabase.co/rest/v1"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1c3hiY2J3eWhqdGZqcGx3dHN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQzNTEzOTksImV4cCI6MjA1OTkyNzM5OX0.d6DTqwlZ4X69orabNA0tzxrucsnVv531dqzUcsxum6E"

-- Custom function to replace table.find for compatibility
local function findInTable(tbl, value)
    if type(tbl) ~= "table" then return false end
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Wait for game to load
repeat task.wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
if not getgenv().key or getgenv().key == '' or getgenv().key == "" then print("❌ Please provide a key!") return end

-- Local Player
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
local secureHttp = {}
local secureMt = {
    __call = function(_, req)
        if not checkHookTamper() then return nil end
        if type(OriginalHttpFunc) ~= "function" or pcall(OriginalHttpFunc, {Url = "https://example.com", Method = "GET"}) == false then 
            print("❌ HTTP Function Corrupted!") 
            return nil 
        end
        if req.Url and req.Method and string.match(req.Url, "^https://eusxbcbwyhjtfjplwtst%.supabase%.co/rest/v1/") then
            local response = OriginalHttpFunc(req)
            if response and response.StatusCode and (response.StatusCode < 200 or response.StatusCode >= 400) then 
                print("❌ Invalid Response Status: " .. tostring(response.StatusCode)) 
                return nil 
            end
            return response
        else 
            print("❌ Invalid HTTP Request! Must use Supabase URL")
            return nil 
        end
    end,
    __index = function() return nil end,
    __newindex = function() print("❌ Attempt to Modify Secure HTTP!") return nil end
}
if hasGetHwid then 
    setmetatable(secureHttp, secureMt) 
    HttpRequestFunc = secureHttp 
end

local function generateChecksum()
    local code = tostring(checkHookTamper) .. tostring(dummyCheck)
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
    elseif allowexec and type(allowexec) == "table" and findInTable(allowexec, executorName) then
        return game:GetService("RbxAnalyticsService"):GetClientId() or "NO_HWID_" .. executorName
    else
        print("❌ No Support: " .. executorName)
        return nil
    end
end

--------------------------------- Check Whitelist ---------------------------
local function updateHwid(key, hwid, exploit)
    local requestUrl = SUPABASE_URL .. "/keys?key=eq." .. key
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "PATCH",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Prefer"] = "return=minimal",
            ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
            ["apikey"] = SUPABASE_ANON_KEY
        },
        Body = HttpService:JSONEncode({
            exploit = exploit,
            hwid = hwid,
            status = "Active"
        })
    })
    if not response then
        print("❌ Failed to Activate Key: No response from server")
        return false
    end
    if response.StatusCode == 500 then
        print("❌ Failed to Activate Key: Internal Server Error")
        return false
    elseif response.StatusCode == 401 then
        print("❌ Failed to Activate Key: Unauthorized - Response:", response)
        return false
    elseif response.StatusCode == 403 then
        print("❌ Failed to Activate Key: Forbidden")
        return false
    elseif response.StatusCode == 200 or response.StatusCode == 204 then
        return true
    else
        print("❌ Failed to Activate Key: Status " .. tostring(response.StatusCode))
        return false
    end
end

local function logUsage(key, hwid, exploit, userId)
    local requestUrl = SUPABASE_URL .. "/logs"
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
            ["apikey"] = SUPABASE_ANON_KEY
        },
        Body = HttpService:JSONEncode({
            key = key,
            exploit = exploit,
            hwid = hwid,
            user_id = userId,
            used_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
        })
    })
    if not response then
        print("❌ Failed to Log Usage: No response")
        return false
    end
    if response.StatusCode == 500 then
        print("❌ Failed to Log Usage: Internal Server Error")
        return false
    elseif response.StatusCode == 401 then
        print("❌ Failed to Log Usage: Unauthorized - Response:", response)
        return false
    elseif response.StatusCode == 201 then
        return true
    else
        print("❌ Failed to Log Usage: Status " .. tostring(response.StatusCode))
        return false
    end
end

local function checkKey()
    if not verifyIntegrity() or not checkEnvTamper() then return false, nil, nil end
    local key = getgenv().key or ""
    local exploit = getexecutorname()
    local userId = player.UserId
    
    if key == "" then print("❌ Key?") return false, nil, nil end

    local requestUrl = SUPABASE_URL .. "/keys?key=eq." .. key
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
            ["apikey"] = SUPABASE_ANON_KEY
        }
    })
    if not response or not response.Body then 
        print("❌ Failed to Fetch: Data (Status: " .. (response and response.StatusCode or "No response") .. ")")
        return false, nil, nil 
    end
    if response.StatusCode == 500 then
        print("❌ Failed to Fetch Key: Internal Server Error")
        return false, nil, nil
    elseif response.StatusCode == 401 then
        print("❌ Failed to Fetch Key: Unauthorized - Response:", response)
        return false, nil, nil
    end

    local data = HttpService:JSONDecode(response.Body)
    if not data or type(data) ~= "table" or #data == 0 then 
        print("❌ Key Not Found!")
        return false, nil, nil 
    end

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
        print("❌ Invalid Key Status: " .. tostring(status))
        return false, nil, nil
    end
end

local function checkUserLock()
    if not verifyIntegrity() or not checkEnvTamper() then return false end
    local userId = player.UserId
    local charName = player.Name
    local requestUrl = SUPABASE_URL .. "/locked_users?user_id=eq." .. userId
    local response = HttpRequestFunc({
        Url = requestUrl,
        Method = "GET",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
            ["apikey"] = SUPABASE_ANON_KEY
        }
    })
    if not response or not response.Body then 
        print("❌ Failed to Fetch: LData (Status: " .. (response and response.StatusCode or "No response") .. ")")
        return false 
    end
    if response.StatusCode == 500 then
        print("❌ Failed to Fetch Locked Users: Internal Server Error")
        return false
    elseif response.StatusCode == 401 then
        print("❌ Failed to Fetch Locked Users: Unauthorized - Response:", response)
        return false
    end

    local data = HttpService:JSONDecode(response.Body)
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
    if not findInTable(allowedPlaceIds, game.PlaceId) then
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
    
    -- Start loading data
    print("⏳ Loading key data...")
    
    -- Fetch key data (exploit, script status, days, and functionss)
    local exploit, scriptStatus, days, functionss = getKeyData()
    if not exploit then
        print("❌ Failed to load data!")
        return false
    end
    
    -- Determine button states before creating the GUI
    local hasGem = findInTable(functionss, "gem")
    local hasCoins = findInTable(functionss, "coins")
    
    -- Determine if buttons should be enabled
    local gemEnabled = scriptStatus == "w" and hasGem
    local coinsEnabled = scriptStatus == "w" and hasCoins
    
    -- Determine disable reasons for each button
    local gemDisableReason = scriptStatus == "p" and "( Patched )" or not hasGem and "( No Access )" or ""
    local coinsDisableReason = scriptStatus == "p" and "( Patched )" or not hasCoins and "( No Access )" or ""
    
    -- Create GUI after all data is loaded
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = playerGui
    ScreenGui.Name = "AnimeFruitGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    -- Main Frame (Horizontal, Extended Height)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 350, 0, 200) -- Increased height to accommodate reason labels
    Frame.Position = UDim2.new(0.5, -175, 0.5, -100)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    Frame.ClipsDescendants = true
    Frame.Visible = true

    -- Apply corner radius
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame

    -- Draggable functionality
    local dragging = false
    local dragStart = nil
    local startPos = nil

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
        end
    end)

    Frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Title Label with Smooth Animation (Size Only)
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0, 200, 0, 40)
    Title.Position = UDim2.new(0, 15, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "AnimeFruit"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 24
    Title.Font = Enum.Font.FredokaOne
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    -- Title animation (smooth pulsing size only)
    local function animateTitle()
        local sizeTween = TweenService:Create(Title, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextSize = 26})
        sizeTween:Play()
    end
    animateTitle()

    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -40, 0, 5)
    CloseButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 18
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.Parent = Frame

    local CloseUICorner = Instance.new("UICorner")
    CloseUICorner.CornerRadius = UDim.new(0, 5)
    CloseUICorner.Parent = CloseButton

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Gem Button
    local GemButton = Instance.new("TextButton")
    GemButton.Size = UDim2.new(0, 100, 0, 40)
    GemButton.Position = UDim2.new(0.5, -110, 0.5, -10)
    GemButton.BackgroundColor3 = gemEnabled and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(255, 245, 145) -- Pastel yellow for disabled
    GemButton.Text = "Gem"
    GemButton.TextColor3 = gemEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    GemButton.TextSize = 18
    GemButton.Font = Enum.Font.SourceSansBold
    GemButton.AutoButtonColor = gemEnabled
    GemButton.Parent = Frame

    local GemUICorner = Instance.new("UICorner")
    GemUICorner.CornerRadius = UDim.new(0, 8)
    GemUICorner.Parent = GemButton

    -- Gem Disable Reason Label
    local GemReasonLabel = Instance.new("TextLabel")
    GemReasonLabel.Size = UDim2.new(0, 100, 0, 15)
    GemReasonLabel.Position = UDim2.new(0.5, -110, 0.5, 30)
    GemReasonLabel.BackgroundTransparency = 1
    GemReasonLabel.Text = gemDisableReason
    GemReasonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    GemReasonLabel.TextSize = 10
    GemReasonLabel.Font = Enum.Font.SourceSans
    GemReasonLabel.TextXAlignment = Enum.TextXAlignment.Center
    GemReasonLabel.Parent = Frame

    -- Coins Button
    local CoinsButton = Instance.new("TextButton")
    CoinsButton.Size = UDim2.new(0, 100, 0, 40)
    CoinsButton.Position = UDim2.new(0.5, 10, 0.5, -10)
    CoinsButton.BackgroundColor3 = coinsEnabled and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(255, 245, 145) -- Pastel yellow for disabled
    CoinsButton.Text = "Coins"
    CoinsButton.TextColor3 = coinsEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    CoinsButton.TextSize = 18
    CoinsButton.Font = Enum.Font.SourceSansBold
    CoinsButton.AutoButtonColor = coinsEnabled
    CoinsButton.Parent = Frame

    local CoinsUICorner = Instance.new("UICorner")
    CoinsUICorner.CornerRadius = UDim.new(0, 8)
    CoinsUICorner.Parent = CoinsButton

    -- Coins Disable Reason Label
    local CoinsReasonLabel = Instance.new("TextLabel")
    CoinsReasonLabel.Size = UDim2.new(0, 100, 0, 15)
    CoinsReasonLabel.Position = UDim2.new(0.5, 10, 0.5, 30)
    CoinsReasonLabel.BackgroundTransparency = 1
    CoinsReasonLabel.Text = coinsDisableReason
    CoinsReasonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CoinsReasonLabel.TextSize = 10
    CoinsReasonLabel.Font = Enum.Font.SourceSans
    CoinsReasonLabel.TextXAlignment = Enum.TextXAlignment.Center
    CoinsReasonLabel.Parent = Frame

    -- "By" Text
    local ByText = Instance.new("TextLabel")
    ByText.Size = UDim2.new(0, 30, 0, 20)
    ByText.Position = UDim2.new(0, 15, 0, 40)
    ByText.BackgroundTransparency = 1
    ByText.Text = "By"
    ByText.TextColor3 = Color3.fromRGB(150, 150, 150)
    ByText.TextSize = 14
    ByText.Font = Enum.Font.FredokaOne
    ByText.TextXAlignment = Enum.TextXAlignment.Left
    ByText.Parent = Frame

    -- "Mo Iamchuasawad" Text with Soft Pink Animation
    local NameText = Instance.new("TextLabel")
    NameText.Size = UDim2.new(0, 150, 0, 20)
    NameText.Position = UDim2.new(0, 45, 0, 40)
    NameText.BackgroundTransparency = 1
    NameText.Text = "Mo Iamchuasawad"
    NameText.TextColor3 = Color3.fromRGB(200, 200, 200)
    NameText.TextSize = 20
    NameText.Font = Enum.Font.FredokaOne
    NameText.TextXAlignment = Enum.TextXAlignment.Left
    NameText.Parent = Frame

    -- Creator animation (soft pink glow for NameText only)
    local function animateCreator()
        local colorTweenName = TweenService:Create(NameText, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextColor3 = Color3.fromRGB(255, 220, 220)})
        colorTweenName:Play()
    end
    animateCreator()

    -- Note Frame
    local NoteFrame = Instance.new("Frame")
    NoteFrame.Size = UDim2.new(0, 300, 0, 20)
    NoteFrame.Position = UDim2.new(0.5, -150, 1, -30)
    NoteFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    NoteFrame.BorderSizePixel = 0
    NoteFrame.Parent = Frame

    local NoteUICorner = Instance.new("UICorner")
    NoteUICorner.CornerRadius = UDim.new(0, 5)
    NoteUICorner.Parent = NoteFrame

    -- Note Text
    local expiryText = days == 999999 and "LifeTime" or tostring(days) .. " Day"
    local statusText = scriptStatus == "w" and "Working" or "Patched"
    local statusColor = scriptStatus == "w" and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150) -- Pastel neon green/red

    local NoteText = Instance.new("TextLabel")
    NoteText.Size = UDim2.new(1, -30, 1, 0)
    NoteText.Position = UDim2.new(0, 15, 0, 0)
    NoteText.BackgroundTransparency = 1
    NoteText.Text = "Exploit: " .. exploit .. " / Expired at: " .. expiryText .. " / Status: " .. statusText
    NoteText.TextColor3 = Color3.fromRGB(200, 200, 200)
    NoteText.TextSize = 10
    NoteText.Font = Enum.Font.SourceSans
    NoteText.TextXAlignment = Enum.TextXAlignment.Center
    NoteText.Parent = NoteFrame

    -- Status Dot with Neon Animation
    local StatusDot = Instance.new("Frame")
    StatusDot.Size = UDim2.new(0, 10, 0, 10)
    StatusDot.Position = UDim2.new(1, -15, 0.5, -5)
    StatusDot.BackgroundColor3 = statusColor
    StatusDot.BorderSizePixel = 0
    StatusDot.Parent = NoteFrame

    local DotUICorner = Instance.new("UICorner")
    DotUICorner.CornerRadius = UDim.new(1, 0)
    DotUICorner.Parent = StatusDot

    -- Neon Glow Animation for Status Dot
    local function animateStatusDot()
        local glowTween = TweenService:Create(StatusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            BackgroundColor3 = scriptStatus == "w" and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 200, 200)
        })
        glowTween:Play()
    end
    animateStatusDot()

    -- Button Hover Effects
    local function applyHoverEffect(button)
        if (button == GemButton and not gemEnabled) or (button == CoinsButton and not coinsEnabled) then return end
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        end)
    end

    applyHoverEffect(GemButton)
    applyHoverEffect(CoinsButton)
    applyHoverEffect(CloseButton)

    -- Gem Script
    GemButton.MouseButton1Click:Connect(function()
        if not gemEnabled then return end
        local Event = game:GetService("ReplicatedStorage").Assets.Okay
        Event:FireServer(table.unpack({
            (function(bytes)
                local b = buffer.create(#bytes)
                for i = 1, #bytes do
                    buffer.writeu8(b, i - 1, bytes[i])
                end
                return b
            end)({ 71 }),
            (function(bytes)
                local b = buffer.create(#bytes)
                for i = 1, #bytes do
                    buffer.writeu8(b, i - 1, bytes[i])
                end
                return b
            end)({ 254, 2, 0, 6, 1, 50, 2, 25, 252 })
        }))
    end)

    -- Coins Script
    CoinsButton.MouseButton1Click:Connect(function()
        if not coinsEnabled then return end
        local Event = game:GetService("ReplicatedStorage").Assets.Okay
        Event:FireServer(table.unpack({
            (function(bytes)
                local b = buffer.create(#bytes)
                for i = 1, #bytes do
                    buffer.writeu8(b, i - 1, bytes[i])
                end
                return b
            end)({ 71 }),
            (function(bytes)
                local b = buffer.create(#bytes)
                for i = 1, #bytes do
                    buffer.writeu8(b, i - 1, bytes[i])
                end
                return b
            end)({ 254, 2, 0, 6, 1, 49, 3, 96, 121, 254, 255 })
        }))
    end)

    return true
end

-- Perform authentication check
if not performWhitelistCheck() then return end
