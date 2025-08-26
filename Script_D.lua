-- Auto CP Teleporter (Executor Client) versi FINAL FIXED FULL
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ========================
-- Konfigurasi CP
-- ========================
local CPs = {
    {pos = Vector3.new(-621.72, 250.20, -383.89), expect = 1, wait_here = true},  -- CP1
    {pos = Vector3.new(-1203.19, 261.56, -487.08), expect = 2, wait_here = true}, -- CP2
    {pos = Vector3.new(-1399.29, 578.31, -949.93), expect = 3, wait_here = true}, -- CP3
    {pos = Vector3.new(-1701.05, 816.51, -1399.99), expect = 4, wait_here = true},-- CP4
    {pos = Vector3.new(-1971.53, 841.99, -1671.81), expect = 5, wait_here = false, delay = 5}, -- CP5 delay 5s
    {pos = Vector3.new(-3231.311, 1718.793, -2590.812), expect = 5, wait_here = true, auto_die = true},-- CP6
}

-- ========================
-- RemoteEvent notif
-- ========================
local REMOTE_NAME = "ShowShelterNotification"
local notifEvent = ReplicatedStorage:FindFirstChild(REMOTE_NAME, true)

if not notifEvent then
    for _, inst in ipairs(game:GetDescendants()) do
        if inst:IsA("RemoteEvent") and inst.Name:lower():find("shelter") and inst.Name:lower():find("notif") then
            notifEvent = inst
            break
        end
    end
end

local seen = {} -- notif yang sudah diterima
local lastNotifId = nil

if notifEvent then
    notifEvent.OnClientEvent:Connect(function(...)
        local args = {...}
        local num
        for _, v in ipairs(args) do
            if typeof(v) == "number" then num = v break end
            if typeof(v) == "string" then num = tonumber(v) break end
            if typeof(v) == "table" then
                for _, vv in pairs(v) do
                    if typeof(vv) == "number" then num = vv break end
                end
                if num then break end
            end
        end
        if num then
            lastNotifId = num
            seen[num] = true
            print("[ShowShelterNotification] ->", num)
        end
    end)
end

-- ========================
-- Helper
-- ========================
local function getChar()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not c:FindFirstChild("Humanoid") then c:WaitForChild("Humanoid") end
    if not c:FindFirstChild("HumanoidRootPart") then c:WaitForChild("HumanoidRootPart") end
    return c
end

local function getHRP()
    local c = getChar()
    return c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

local function safeTeleport(targetPos)
    local hrp, hum = getHRP()
    pcall(function() hum.Sit = false end)
    pcall(function() hum.PlatformStand = false end)
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    pcall(function() hrp.RotVelocity = Vector3.zero end)
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,5,0))
end

-- ========================
-- Main Loop
-- ========================
local running = false

local function runCycle()
    running = true
    while running do
        local currentCP = 1
        while currentCP <= #CPs do
            if not running then break end
            local cp = CPs[currentCP]

            print(("[Teleporter] Ke CP%d ..."):format(currentCP))
            safeTeleport(cp.pos)

            -- delay CP5
            if cp.delay then
                print(("[Teleporter] Delay %d detik di CP%d ..."):format(cp.delay, currentCP))
                task.wait(cp.delay)
            end

            -- tunggu notif jika ada
            if cp.wait_here then
                while not seen[cp.expect] do
                    local hrp, hum = getHRP()
                    -- jika player mati, tunggu respawn & teleport ulang
                    if not hum or hum.Health <= 0 then
                        print(("[Teleporter] Player mati saat menunggu notif %d, respawn & lanjut..."):format(cp.expect))
                        LocalPlayer.CharacterAdded:Wait()
                        safeTeleport(cp.pos)
                    end
                    task.wait(0.1)
                end
            end

            -- CP6 auto-die
            if cp.auto_die then
                local hrp, hum = getHRP()
                if hum and hum.Health > 0 then
                    print("[Teleporter] CP6 notif diterima → Auto die & restart loop...")
                    hum.Health = 0
                end
                -- tunggu respawn sebelum reset loop
                LocalPlayer.CharacterAdded:Wait()
                -- reset semua notif, mulai dari CP1
                seen = {}
                currentCP = 1
                break -- keluar loop CP, mulai dari CP1
            else
                currentCP = currentCP + 1
            end
        end
    end
end

-- ========================
-- UI Start/Stop
-- ========================
local gui = Instance.new("ScreenGui")
gui.Name = "CP_Teleporter_UI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(220, 120)
frame.Position = UDim2.new(0,20,0,200)
frame.BackgroundColor3 = Color3.fromRGB(26,26,26)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-10,0,24)
title.Position = UDim2.fromOffset(10,8)
title.BackgroundTransparency = 1
title.Text = "CP Teleporter"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,-20,0,20)
status.Position = UDim2.fromOffset(10,36)
status.BackgroundTransparency = 1
status.Text = "Status: Idle"
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.TextColor3 = Color3.fromRGB(200,200,200)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.5,-15,0,40)
startBtn.Position = UDim2.fromOffset(10,70)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 16
startBtn.TextColor3 = Color3.fromRGB(255,255,255)
startBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,8)
startBtn.Parent = frame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.5,-15,0,40)
stopBtn.Position = UDim2.new(0.5,5,0,70)
stopBtn.Text = "Stop"
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 16
stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,8)
stopBtn.Parent = frame

startBtn.MouseButton1Click:Connect(function()
    if running then return end
    status.Text = "Status: Running"
    task.spawn(runCycle)
end)

stopBtn.MouseButton1Click:Connect(function()
    running = false
    status.Text = "Status: Stopped"
end)

-- drag sederhana
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("[Teleporter] Siap. Klik Start untuk mulai loop.")
