local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = LocalPlayer.PlayerGui
ScreenGui.Name = "AnimeFruitGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Main Frame (Horizontal)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 350, 0, 150)
Frame.Position = UDim2.new(0.5, -175, 0.5, -75)
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
Title.Position = UDim2.new(0, 15, 0, 10)
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
GemButton.Size = UDim2.new(0, 100, 0, 40)
GemButton.Position = UDim2.new(0.5, -110, 0.5, 10)
GemButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GemButton.Text = "Gem 99k"
GemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
GemButton.TextSize = 18
GemButton.Font = Enum.Font.SourceSansBold
GemButton.Parent = Frame

local GemUICorner = Instance.new("UICorner")
GemUICorner.CornerRadius = UDim.new(0, 8)
GemUICorner.Parent = GemButton

-- Coins Button
local CoinsButton = Instance.new("TextButton")
CoinsButton.Size = UDim2.new(0, 100, 0, 40)
CoinsButton.Position = UDim2.new(0.5, 10, 0.5, 10)
CoinsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CoinsButton.Text = "Coins 100M"
CoinsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CoinsButton.TextSize = 18
CoinsButton.Font = Enum.Font.SourceSansBold
CoinsButton.Parent = Frame

local CoinsUICorner = Instance.new("UICorner")
CoinsUICorner.CornerRadius = UDim.new(0, 8)
CoinsUICorner.Parent = CoinsButton

-- "By" Text
local ByText = Instance.new("TextLabel")
ByText.Size = UDim2.new(0, 30, 0, 20)
ByText.Position = UDim2.new(0, 15, 0, 45)
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
NameText.Position = UDim2.new(0, 45, 0, 45)
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

-- Button Hover Effects
local function applyHoverEffect(button)
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
