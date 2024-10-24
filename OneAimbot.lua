-- Services
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

-- Local player
local localPlayer = players.LocalPlayer
local locking = false
local moving = false

-- Function to find the nearest player
local function findNearestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge

    -- Get the local player's character and position
    local localCharacter = localPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local localPosition = localCharacter.HumanoidRootPart.Position

    -- Loop through all players to find the closest one
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local playerPosition = player.Character.HumanoidRootPart.Position
            local distance = (localPosition - playerPosition).Magnitude

            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

-- Function to adjust the start delay based on the distance
local function getStartDelay(distance)
    if distance >= 60 then
        return 0
    elseif distance > 20 then
        return 0.3
    else
        return 0.4
    end
end

-- Failsafe timer function to stop movement after 4 seconds
local function stopFollowingAfterTime(connection, startTime)
    local currentTime = tick()
    if currentTime - startTime >= 4 then
        -- Stop following after 4 seconds
        if connection then connection:Disconnect() end
        locking = false
    end
end

-- Function to rotate the local player to face the nearest player and move towards them with a delay
local function lockAndMoveToNearestPlayer()
    if locking then return end -- Prevent re-triggering while already locking

    local nearestPlayer = findNearestPlayer()
    if nearestPlayer and nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local nearestHRP = nearestPlayer.Character.HumanoidRootPart
        local localCharacter = localPlayer.Character

        if localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") then
            locking = true

            -- Start the movement process with a failsafe
            local startTime = tick()
            local connection
            connection = runService.RenderStepped:Connect(function()
                -- Calculate distance between the local player and the nearest player
                local distance = (localCharacter.HumanoidRootPart.Position - nearestHRP.Position).Magnitude

                -- Stop movement if too close (touching) or after 4 seconds
                stopFollowingAfterTime(connection, startTime)

                if distance <= 2.6 then
                    -- Stop moving if within touching distance
                    connection:Disconnect()
                    locking = false
                else
                    -- Lock the player's rotation to face the nearest player
                    localCharacter.HumanoidRootPart.CFrame = CFrame.new(localCharacter.HumanoidRootPart.Position, nearestHRP.Position)

                    -- Get the start delay based on distance
                    local startDelay = getStartDelay(distance)

                    -- Move towards the enemy with delay
                    delay(startDelay, function()
                        if connection.Connected then
                            local moveDirection = (nearestHRP.Position - localCharacter.HumanoidRootPart.Position).unit
                            localCharacter.HumanoidRootPart.CFrame = localCharacter.HumanoidRootPart.CFrame + moveDirection * 2
                        end
                    end)
                end
            end)
        end
    end
end

-- Detect when the "Q" key is pressed to start moving towards the nearest player
userInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.One then
        lockAndMoveToNearestPlayer()
    end
end)

-- Ensure the script reactivates when the player's character resets
localPlayer.CharacterAdded:Connect(function()
    locking = false -- Reset locking state when character respawns
end)