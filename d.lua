local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer.PlayerGui
ScreenGui.Name = "AnimeFruitGUI"
ScreenGui.ResetOnSpawn = false

-- Main Frame
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0.5, -100, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.ClipsDescendants = true

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

-- Title Label with Animation
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "AnimeFruit"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 24
Title.Font = Enum.Font.FredokaOne
Title.Parent = Frame

-- Title animation (pulsing effect)
local function pulseTitle()
    local tween = TweenService:Create(Title, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextSize = 26})
    tween:Play()
end
pulseTitle()

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 10)
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
GemButton.Size = UDim2.new(0, 160, 0, 50)
GemButton.Position = UDim2.new(0.5, -80, 0, 70)
GemButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GemButton.Text = "Gem 99k"
GemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GemButton.TextSize = 20
GemButton.Font = Enum.Font.SourceSansBold
GemButton.Parent = Frame

local GemUICorner = Instance.new("UICorner")
GemUICorner.CornerRadius = UDim.new(0, 8)
GemUICorner.Parent = GemButton

-- Coins Button
local CoinsButton = Instance.new("TextButton")
CoinsButton.Size = UDim2.new(0, 160, 0, 50)
CoinsButton.Position = UDim2.new(0.5, -80, 0, 130)
CoinsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CoinsButton.Text = "Coins 100M"
CoinsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CoinsButton.TextSize = 20
CoinsButton.Font = Enum.Font.SourceSansBold
CoinsButton.Parent = Frame

local CoinsUICorner = Instance.new("UICorner")
CoinsUICorner.CornerRadius = UDim.new(0, 8)
CoinsUICorner.Parent = CoinsButton

-- Creator Label with Animation
local Creator = Instance.new("TextLabel")
Creator.Size = UDim2.new(1, 0, 0, 30)
Creator.Position = UDim2.new(0, 0, 1, -40)
Creator.BackgroundTransparency = 1
Creator.Text = "By: Mo Iamchuasawad"
Creator.TextColor3 = Color3.fromRGB(255, 255, 255)
Creator.TextSize = 16
Creator.Font = Enum.Font.FredokaOne
Creator.Parent = Frame

-- Creator animation (color fade)
local function fadeCreator()
    local tween = TweenService:Create(Creator, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextColor3 = Color3.fromRGB(200, 200, 200)})
    tween:Play()
end
fadeCreator()

-- Button Hover Effects
local function applyHoverEffect(button)
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
    end)
end

applyHoverEffect(GemButton)
applyHoverEffect(CoinsButton)
applyHoverEffect(CloseButton)

-- Gem Script
GemButton.MouseButton1Click:Connect(function()
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
