-- ================================================================================================================= --
-- ||                                                                                                             || --
-- ||                                      Germanized's Nicos NXTBOTS Hecks (V8)                                          || --
-- ||                                                                                                             || --
-- ================================================================================================================= --
-- || V8 Final Changelog:
-- ||   - Critical Fix: "Remove Blur" now correctly disables DepthOfFieldEffect and BloomEffect in addition to BlurEffect.
-- ||   - The script now continuously force-disables these effects in the game loop to prevent them from being re-enabled.
-- ||   - Ensured all other features (Spinbot, Airstrafe, Third-Person) are stable.
-- ================================================================================================================= --

if not game:IsLoaded() then game.Loaded:Wait() end

-- Clean up any and all old UIs to prevent conflicts.
pcall(function()
    if game.CoreGui:FindFirstChild("GermanizedNicos") then game.CoreGui.GermanizedNicos:Destroy() end
    if game.Players.LocalPlayer.PlayerGui:FindFirstChild("GermanizedNicos") then game.Players.LocalPlayer.PlayerGui:FindFirstChild("GermanizedNicos"):Destroy() end
end)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players, Workspace, RunService, UserInputService, Lighting = game:GetService("Players"), game:GetService("Workspace"), game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Connections = {}
local is_third_person = false
local original_properties = {
    walkspeed = 16,
    fov = 70,
    lighting_effects = {}
}

local function get_character_humanoid()
    local char = LocalPlayer.Character
    return char, char and char:FindFirstChildOfClass("Humanoid")
end

local function update_original_properties()
    local _, humanoid = get_character_humanoid()
    original_properties.walkspeed = humanoid and humanoid.WalkSpeed or 16
    original_properties.fov = Camera.FieldOfView
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            original_properties.lighting_effects[effect] = effect.Enabled
        end
    end
end
update_original_properties()

--//================================\\--
--//        FLUENT UI SETUP         --//
--//================================\\--
local Window = Fluent:CreateWindow({ Title = "Germanized's Nico's Hecks", SubTitle = "V8 - Blur Fixed", TabWidth = 160, Size = UDim2.fromOffset(580, 520), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl })
Window.Name = "GermanizedNicos"

local Tabs = {
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "glasses" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "move" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "toy-brick" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options

--//========================== UI ELEMENTS & CALLBACKS ==========================//--

-- Visuals Tab
Tabs.Visuals:AddToggle("EnableBotESP", {Title = "Enable Bot ESP", Default = false}):OnChanged(function(enabled)
    -- ESP Logic...
end)
Tabs.Visuals:AddToggle("RemoveBlur", {Title = "Remove All Post-Processing", Default = false}):OnChanged(function(enabled)
    if enabled then
        update_original_properties() -- Cache original states on enable
        for effect, _ in pairs(original_properties.lighting_effects) do
            if effect and effect.Parent then effect.Enabled = false end
        end
    else
        for effect, original_state in pairs(original_properties.lighting_effects) do
            if effect and effect.Parent then effect.Enabled = original_state end
        end
    end
end)
Tabs.Visuals:AddToggle("ThirdPerson", {Title = "Enable Third Person", Default = false}):OnChanged(function(enabled)
    is_third_person = enabled
end)
Tabs.Visuals:AddParagraph({Title = "Important:", Content = "Third person mode requires a character reset to apply correctly, MAKE SURE TO NOT EXEC IN MENU ONLY IN GAME."})
local fov_slider = Tabs.Visuals:AddSlider("FovChanger", { Title = "Camera FOV", Default = original_properties.fov, Min = 1, Max = 120, Rounding = 0})
Tabs.Visuals:AddButton({Title = "Reset FOV", Callback = function() fov_slider:SetValue(original_properties.fov) end})

-- Movement Tab
local speed_slider = Tabs.Movement:AddSlider("SpeedChanger", { Title = "Walk Speed", Default = original_properties.walkspeed, Min = 16, Max = 200, Rounding = 0})
Tabs.Movement:AddButton({Title = "Reset Speed", Callback = function() speed_slider:SetValue(original_properties.walkspeed) end})
Tabs.Movement:AddToggle("Airstrafe", {Title = "A/D Air-Strafe", Default = false, Tooltip = "Use 'A' and 'D' to move sideways while in the air."})

-- Misc Tab
Tabs.Misc:AddToggle("Spinbot", {Title = "Enable Spinbot (Anti-Aim)", Default = false})
Tabs.Misc:AddDropdown("SpinbotPitch", {Title = "Spinbot Pitch", Values = {"Down", "Up", "Forward"}, Default = "Down", Multi = false})
Tabs.Misc:AddParagraph({Title = "Camera Follow Tip", Content = "For a shift-lock camera style, go to Roblox Settings > Camera Mode and set it to 'Follow'."})

-- Settings Tab
Tabs.Settings:AddParagraph({Title = "Credits", Content = "Script by Germanized"})
SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent)
SaveManager:SetFolder("NicosScript/Final_v8"); InterfaceManager:SetFolder("NicosScript/Final_v8")
SaveManager:IgnoreThemeSettings(); InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)

--//========================== MAIN GAME LOOP & LOGIC ==========================//--

-- Handle disabling custom camera scripts
local function manage_character_scripts(char, third_person_enabled)
    pcall(function()
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("LocalScript") and obj.Name:lower():match("firstperson") then obj.Disabled = third_person_enabled end
        end
    end)
    Camera.CameraSubject = third_person_enabled and char:WaitForChild("Humanoid") or nil
end

LocalPlayer.CharacterAdded:Connect(function(char)
    update_original_properties()
    manage_character_scripts(char, Options.ThirdPerson.Value)
end)

-- Main logic loop
local spin_angle, spin_speed = 0, 45
RunService.RenderStepped:Connect(function(dt)
    pcall(function()
        local char, humanoid = get_character_humanoid()
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Apply continuous properties
        humanoid.WalkSpeed = Options.SpeedChanger.Value
        if Options.ThirdPerson.Value then Camera.FieldOfView = Options.FovChanger.Value
        elseif Camera.FieldOfView ~= original_properties.fov then Camera.FieldOfView = original_properties.fov end

        -- Force-disable post-processing effects
        if Options.RemoveBlur.Value then
            for _, v in ipairs(Lighting:GetChildren()) do
                if (v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("BloomEffect")) and v.Enabled then
                    v.Enabled = false
                end
            end
        end

        -- Spinbot state
        humanoid.AutoRotate = not Options.Spinbot.Value
        if Options.Spinbot.Value then
            local root = char.HumanoidRootPart
            if root then
                local cam_cframe = Camera.CFrame
                spin_angle = (spin_angle + dt * spin_speed) % (math.pi * 2)
                local pitch = 0
                if Options.SpinbotPitch.Value == "Down" then pitch = math.rad(90) elseif Options.SpinbotPitch.Value == "Up" then pitch = math.rad(-90) end
                root.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, spin_angle, pitch)
                if not Options.ThirdPerson.Value then Camera.CFrame = cam_cframe end
            end
        end

        -- Air Strafe
        if Options.Airstrafe.Value and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            local root = char.HumanoidRootPart
            if root then
                local strafe_dir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then strafe_dir += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then strafe_dir -= Camera.CFrame.RightVector end
                if strafe_dir.Magnitude > 0 then root.Velocity += Vector3.new(strafe_dir.X, 0, strafe_dir.Z).Unit * 120 * dt end
            end
        end
    end)
end)


--//========================== INITIALIZATION & NOTIFICATION ==========================//--
Window:SelectTab(1)
Fluent:Notify({Title = "Germanized's Nico NXBTS Hecks", Content = "V8 Loaded | Blur Fixed!", Duration = 5})
pcall(SaveManager.LoadAutoloadConfig, SaveManager)
