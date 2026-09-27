local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espEnabled = true
local mm2Highlights = {}


local function isPlayerVisible(targetChar)
    local localChar = LocalPlayer.Character
    if not targetChar or not localChar then return false end

    local origin = Camera.CFrame.Position
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localChar, targetChar}
    raycastParams.IgnoreWater = true

   
    for _, part in ipairs(targetChar:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local direction = part.Position - origin
            local result = workspace:Raycast(origin, direction, raycastParams)
            
            
            if result == nil then
                return true
            end
        end
    end

    return false
end


local function clearHighlights()
    for name, hl in pairs(mm2Highlights) do
        if hl then hl:Destroy() end
    end
    table.clear(mm2Highlights)
end


UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        espEnabled = not espEnabled
        print("[ESP] Durum:", espEnabled and "ON" or "OFF")
        if not espEnabled then
            clearHighlights()
        end
    end
end)


task.spawn(function()
    while true do
        task.wait(0.1)
        
        if espEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local char = p.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    
                    if hrp then
                        local visible = isPlayerVisible(char)
                        
                        local espColor = visible and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(255, 0, 0)
                        
                       
                        local hl = mm2Highlights[p.Name]
                        if not hl or hl.Parent ~= char then
                            if hl then hl:Destroy() end
                            hl = Instance.new("Highlight")
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.FillTransparency = 0.5
                            hl.OutlineTransparency = 0
                            hl.Parent = char
                            mm2Highlights[p.Name] = hl
                        end
                        
                        hl.FillColor = espColor
                        hl.OutlineColor = espColor
                    end
                else
                    
                    if mm2Highlights[p.Name] then
                        mm2Highlights[p.Name]:Destroy()
                        mm2Highlights[p.Name] = nil
                    end
                end
            end
        end
    end
end)


Players.PlayerRemoving:Connect(function(p)
    if mm2Highlights[p.Name] then
        mm2Highlights[p.Name]:Destroy()
        mm2Highlights[p.Name] = nil
    end
end)
