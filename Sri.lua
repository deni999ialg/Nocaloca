-- Roblox Local Script Executor with GitHub Password Creation and Saving

-- Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService") -- For HTTP requests

-- Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local scriptDataStore = game:GetService("DataStoreService"):GetDataStore("ScriptData") -- DataStore

local userPassword = nil  -- Stores the user's password (fetched from GitHub)
local githubRepo = "yourGitHubUsername/yourRepositoryName"  -- GitHub repository name
local passwordFilePath = "passwords/password.txt"  -- Path to password file in the repository
local githubToken = "yourGitHubToken"  -- Optional: GitHub API token if using a private repository

-- Function to fetch the password from GitHub
local function fetchPasswordFromGitHub()
    local url = "https://api.github.com/repos/" .. githubRepo .. "/contents/" .. passwordFilePath

    -- Headers for GitHub API (use token for private repositories)
    local headers = {
        ["Authorization"] = "token " .. githubToken  -- If you need authentication, otherwise omit this line
    }

    -- Make the request to fetch the password
    local success, response = pcall(function()
        return HttpService:GetAsync(url, true, headers)
    end)

    if success then
        local content = HttpService:JSONDecode(response)
        -- GitHub API returns the content as base64-encoded, decode it
        local passwordBase64 = content.content
        local password = HttpService:Base64Decode(passwordBase64)
        return password
    else
        warn("Error fetching password from GitHub: " .. response)
        return nil
    end
end

-- Function to save password to GitHub
local function savePasswordToGitHub(password)
    local url = "https://api.github.com/repos/" .. githubRepo .. "/contents/" .. passwordFilePath

    -- Prepare the data to send to GitHub (base64 encode the password)
    local content = HttpService:Base64Encode(password)
    local jsonData = HttpService:JSONEncode({
        message = "Save password",
        content = content
    })

    -- Headers for GitHub API (use token for private repositories)
    local headers = {
        ["Authorization"] = "token " .. githubToken,  -- Use your GitHub token
        ["Content-Type"] = "application/json"
    }

    -- Send the PUT request to GitHub API
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "PUT",
            Headers = headers,
            Body = jsonData
        })
    end)

    if success then
        print("Password saved successfully to GitHub!")
    else
        warn("Error saving password to GitHub: " .. response)
    end
end

-- UI Setup
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ScriptExecutorUI"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
mainFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0

local scriptBox = Instance.new("TextBox", mainFrame)
scriptBox.Size = UDim2.new(0.9, 0, 0.7, 0)
scriptBox.Position = UDim2.new(0.05, 0, 0.05, 0)
scriptBox.Text = "-- Enter your script here"
scriptBox.TextColor3 = Color3.fromRGB(255, 255, 255)
scriptBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
scriptBox.TextWrapped = true
scriptBox.TextYAlignment = Enum.TextYAlignment.Top
scriptBox.ClearTextOnFocus = false

-- Password input field for creating the password
local passwordBox = Instance.new("TextBox", mainFrame)
passwordBox.Size = UDim2.new(0.9, 0, 0.1, 0)
passwordBox.Position = UDim2.new(0.05, 0, 0.8, 0)
passwordBox.PlaceholderText = "Enter password to create"
passwordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
passwordBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
passwordBox.ClearTextOnFocus = true
passwordBox.TextMasked = true

-- Verify Password input field (for saving/loading)
local verifyPasswordBox = Instance.new("TextBox", mainFrame)
verifyPasswordBox.Size = UDim2.new(0.9, 0, 0.1, 0)
verifyPasswordBox.Position = UDim2.new(0.05, 0, 0.9, 0)
verifyPasswordBox.PlaceholderText = "Enter password to verify"
verifyPasswordBox.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyPasswordBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
verifyPasswordBox.ClearTextOnFocus = true
verifyPasswordBox.TextMasked = true

-- Function to create a button
local function createButton(name, position, callback)
    local button = Instance.new("TextButton", mainFrame)
    button.Size = UDim2.new(0.2, 0, 0.1, 0)
    button.Position = position
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)

    button.MouseEnter:Connect(function()
        button:TweenSize(UDim2.new(0.21, 0, 0.11, 0), "Out", "Quad", 0.2, true)
    end)

    button.MouseLeave:Connect(function()
        button:TweenSize(UDim2.new(0.2, 0, 0.1, 0), "Out", "Quad", 0.2, true)
    end)

    button.MouseButton1Click:Connect(callback)
    return button
end

-- Function to verify password from GitHub
local function verifyPassword()
    local enteredPassword = verifyPasswordBox.Text
    if enteredPassword == userPassword then
        return true
    else
        warn("Incorrect password!")
        return false
    end
end

-- Function to save script if password is correct
local function saveScript()
    if verifyPassword() then
        local scriptContent = scriptBox.Text
        -- Save the script in the DataStore (example)
        local success, err = pcall(function()
            scriptDataStore:SetAsync(player.UserId, scriptContent)
        end)
        if success then
            print("Script saved successfully!")
        else
            warn("Error saving script: " .. err)
        end
    end
end

-- Function to load script if password is correct
local function loadScript()
    if verifyPassword() then
        local success, result = pcall(function()
            return scriptDataStore:GetAsync(player.UserId)
        end)
        if success and result then
            scriptBox.Text = result
            print("Script loaded successfully!")
        else
            warn("Failed to load script.")
        end
    end
end

-- Function to execute the script entered in the script box
local function executeScript()
    local success, err = pcall(function()
        loadstring(scriptBox.Text)()
    end)
    if success then
        print("Script executed successfully!")
    else
        warn("Error: " .. err)
    end
end

-- When the user creates a password, save it to GitHub
createButton("Save Password", UDim2.new(0.05, 0, 0.7, 0), function()
    local password = passwordBox.Text
    if password ~= "" then
        savePasswordToGitHub(password)  -- Save the password to GitHub
    else
        warn("Please enter a password.")
    end
end)

-- Fetch the password from GitHub when the script runs
userPassword = fetchPasswordFromGitHub()

-- Create the buttons for the UI
createButton("Execute", UDim2.new(0.05, 0, 0.9, 0), function()
    executeScript()
end)

createButton("Save Script", UDim2.new(0.3, 0, 0.9, 0), function()
    saveScript()
end)

createButton("Load Script", UDim2.new(0.55, 0, 0.9, 0), function()
    loadScript()
end)

print("Script Executor with GitHub Password Saving and Creation Ready.")
