local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local mm2Highlights = {}

-- Duvar Kontrolü (Wallcheck)
local function isPlayerVisible(targetChar)
    local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    local localChar = player.Character
    if not targetPart or not localChar then return false end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localChar, targetChar}
    raycastParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil -- Engel yoksa (nil) oyuncu görünür durumdadır
end

-- Execute Edildiği An Doğrudan Çalışan Döngü
task.spawn(function()
    while true do
        task.wait(0.1)
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local char = p.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local visible = isPlayerVisible(char)
                    -- Görünürse Mavi, Duvar arkasındaysa Kırmızı
                    local espColor = visible and Color3.fromRGB(0, 140, 255) or Color3.fromRGB(255, 0, 0)
                    
                    -- Highlight (Karakter Renklendirme)
                    local hl = mm2Highlights[p.Name]
                    if not hl or hl.Parent ~= char then
                        if hl then hl:Destroy() end
                        hl = Instance.new("Highlight")
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.Parent = char
                        mm2Highlights[p.Name] = hl
                    end
                    
                    hl.FillColor = espColor
                    hl.OutlineColor = espColor
                end
            end
        end
    end
end)
