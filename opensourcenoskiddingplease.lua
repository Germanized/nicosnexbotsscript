-- ================================================================================================================= --
-- ||                                                                                                             || --
-- ||                                      Germanized's NicoNXBTS Script (V9)                                     || --
-- ||                                                                                                             || --
-- ================================================================================================================= --
-- || V9 Final Changelog:
-- ||   - Critical Fix: Re-implemented the missing Bot ESP logic. The toggle now correctly finds and shows bot icons.
-- ||   - All previous fixes for Blur, Third-Person, Spinbot, Airstrafe, and WalkSpeed are retained.
-- ================================================================================================================= --

if not game:IsLoaded() then game.Loaded:Wait() end

-- Clean up old UIs to prevent conflicts.
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
local Window = Fluent:CreateWindow({ Title = "Germanized's Nico's Hecks", SubTitle = "V9 - Final", TabWidth = 160, Size = UDim2.fromOffset(580, 520), Acrylic = true, Theme = "Dark", MinimizeKey = Enum.KeyCode.RightControl })
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
    local bots_folder = Workspace:FindFirstChild("bots")
    if not bots_folder then return Fluent:Notify({Title = "Error", Content = "Workspace.bots folder not found!"}) end
    
    local function set_esp(bot, state)
        if bot and bot:FindFirstChild("HumanoidRootPart") and bot.HumanoidRootPart:FindFirstChild("icon") then
            bot.HumanoidRootPart.icon.Enabled = state
            bot.HumanoidRootPart.icon.AlwaysOnTop = state
        end
    end

    for _, bot in pairs(bots_folder:GetChildren()) do
        if bot:IsA("Model") then set_esp(bot, enabled) end
    end
    
    if Connections.BotAdded then Connections.BotAdded:Disconnect() end
    if enabled then
        Connections.BotAdded = bots_folder.ChildAdded:Connect(function(bot)
            if bot:IsA("Model") and Options.EnableBotESP.Value then task.wait(0.1); set_esp(bot, true); end
        end)
    end
end)
Tabs.Visuals:AddToggle("RemoveBlur", {Title = "Remove All Post-Processing", Default = false}):OnChanged(function(enabled)
    if enabled then update_original_properties() end
    for effect, original_state in pairs(original_properties.lighting_effects) do
        if effect and effect.Parent then effect.Enabled = enabled and false or original_state end
    end
end)
Tabs.Visuals:AddToggle("ThirdPerson", {Title = "Enable Third Person", Default = false}):OnChanged(function(enabled)
    is_third_person = enabled
end)
Tabs.Visuals:AddParagraph({Title = "Important:", Content = "Third person mode requires a character reset to apply correctly, also only execute in game not in the menu."})
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
SaveManager:SetFolder("NicosScript/Final_v9"); InterfaceManager:SetFolder("NicosScript/Final_v9")
SaveManager:IgnoreThemeSettings(); InterfaceManager:BuildInterfaceSection(Tabs.Settings); SaveManager:BuildConfigSection(Tabs.Settings)

--//========================== MAIN GAME LOOP & LOGIC ==========================//--

local function manage_character_scripts(char)
    if not char then return end
    pcall(function()
        local enabled = Options.ThirdPerson and Options.ThirdPerson.Value or false
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("LocalScript") and obj.Name:lower():match("firstperson") then
                obj.Disabled = enabled
            end
        end
        Camera.CameraSubject = enabled and char:WaitForChild("Humanoid") or nil
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    update_original_properties()
    manage_character_scripts(char)
end)

local spin_angle, spin_speed = 0, 45
RunService:BindToRenderStep("GermanizedLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
    pcall(function()
        local char, humanoid = get_character_humanoid()
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Apply continuous properties
        humanoid.WalkSpeed = Options.SpeedChanger.Value
        if Options.ThirdPerson.Value then
            Camera.FieldOfView = Options.FovChanger.Value
        elseif Camera.FieldOfView ~= original_properties.fov then
            Camera.FieldOfView = original_properties.fov
        end

        if Options.RemoveBlur.Value then
            for _, v in ipairs(Lighting:GetChildren()) do
                if (v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("BloomEffect")) and v.Enabled then
                    v.Enabled = false
                end
            end
        end
        
        -- Feature logic
        if Options.Spinbot.Value then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                humanoid.AutoRotate = false
                local cam_cframe = Camera.CFrame
                spin_angle = (spin_angle + dt * spin_speed) % (math.pi * 2)
                local pitch = 0
                if Options.SpinbotPitch.Value == "Down" then pitch = math.rad(90) elseif Options.SpinbotPitch.Value == "Up" then pitch = math.rad(-90) end
                root.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, spin_angle, pitch)
                if not Options.ThirdPerson.Value then Camera.CFrame = cam_cframe end
            end
        else
            if not humanoid.AutoRotate then humanoid.AutoRotate = true end
        end
        
        if Options.Airstrafe.Value and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            local root = char.HumanoidRootPart
            if root then
                local strafe_vector = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then strafe_vector += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then strafe_vector -= Camera.CFrame.RightVector end
                if strafe_vector.Magnitude > 0 then root.Velocity += Vector3.new(strafe_vector.X, 0, strafe_vector.Z).Unit * 120 * dt end
            end
        end
    end)
end)


--//========================== INITIALIZATION & NOTIFICATION ==========================//--
Window:SelectTab(1)
Fluent:Notify({Title = "Germanized's Nico Hacks", Content = "V9 | Bot ESP Fixed!", Duration = 5})
pcall(SaveManager.LoadAutoloadConfig, SaveManager)
