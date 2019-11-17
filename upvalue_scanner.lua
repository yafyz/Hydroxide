local run_service = game:GetService("RunService")
local players = game:GetService("Players")

local client = players.LocalPlayer
local mouse = client:GetMouse()

local rclick_menu = oh.ui.RightClickMenu
local upvalue_menu = rclick_menu.Upvalue

local window = oh.ui.Base.Body.UpvalueScanner
local output = window.Output.Results
local tool_bar = window.Toolbar
local query = window.Query
local search = window.Search
local status = window.Output.Status

local current_query
local pattern_flag = true
local check_tables = false
local selected_type = window.SetValue.Types.String
local selected_upvalue = {}
local cache = {}
local events = {}

local disconnect = function()
    rclick_menu.Visible = false
    upvalue_menu.Visible = false

    for i,v in pairs(events) do
        v:Disconnect()
    end
end

local create_upvalue = function(closure, index, value)
    local object = {}

    local upvalue = oh.assets.UpvalueScanner.Upvalue:Clone()
    local increment = UDim2.new(0, 0, 0, 20)
    local log = cache[closure].log
    local initial = value

    upvalue.Index.Text = index
    upvalue.Value.Text = to_string(value)
    upvalue.BackgroundTransparency = pattern_flag and 0 or 1
    upvalue.Parent = log.Upvalues
    upvalue.Icon.Image = oh.icons[type(value)]

    events.mouse2clicked = upvalue.MouseButton2Click:Connect(function()
        rclick_menu.Visible = true
        upvalue_menu.Visible = true

        rclick_menu.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)
        upvalue_menu:TweenSize(UDim2.new(0, 150, 0, 60), "Out", "Quad", 0.1, false)

        selected_upvalue.closure = closure
        selected_upvalue.index = index

        events.change_value = upvalue_menu.ChangeValue.MouseButton1Click:Connect(function()
            window.SetValue.Input.Text = ""
            window.SetValue.Visible = true
            disconnect()
        end)

        events.generate_script = upvalue_menu.GenerateScript.MouseButton1Click:Connect(function()
            disconnect()
        end)

        events.reset_value = upvalue_menu.ResetValue.MouseButton1Click:Connect(function()
            oh.env.set_upvalue(closure, index, initial)
            disconnect()
        end)
    end)

    log.Size = log.Size + increment
    log.Upvalues.Size = log.Upvalues.Size + increment
    output.CanvasSize = output.CanvasSize + increment

    pattern_flag = not pattern_flag
    
    object.value = value
    object.update = function(new_value)
        upvalue.Value.Text = to_string(new_value)
        upvalue.Icon.Image = oh.icons[type(new_value)]
        object.value = new_value
    end

    return object
end

local create_log = function(closure, indices)
    if cache[closure] then
        return cache[closure]
    end

    local object = {}
    local log = oh.assets.UpvalueScanner.Log:Clone()
    local text = tostring(closure)
    
    log.Name = text
    log.Function.Label.Text = text
    log.Parent = output
    
    output.CanvasSize = output.CanvasSize + UDim2.new(0, 0, 0, 20)
    
    object.log = log
    object.upvalues = {}
    object.update = function()
        for index, upvalue in pairs(object.upvalues) do
            local value = oh.env.get_upvalue(closure, index)
            if value ~= upvalue.value then
                upvalue.update(value)
            end
        end
    end

    cache[closure] = object

    for index, value in pairs(indices) do
        object.upvalues[index] = create_upvalue(closure, index, value)
    end

    return object
end

local search_upvalues = function(input)
    local query = input.Text
    if query:gsub(' ', "") ~= "" then
        pattern_flag = true

        for i,v in pairs(output:GetChildren()) do
            if v.ClassName ~= "UIListLayout" then
                v:Destroy()
            end
        end

        output.CanvasSize = UDim2.new(0, 0, 0, 0)

        cache = {}

        local logs = 0
        for closure, upvalues in pairs(scan_upvalue(query, check_tables)) do
            create_log(closure, upvalues)
            logs = logs + 1
        end

        if logs == 0 then
            status.Text = "No results were found"
        else
            status.Text = ""
        end

        input.Text = ""
    end
end

search.MouseButton1Click:Connect(function()
    search_upvalues(query)
end)

query.FocusLost:Connect(function(from_enter)
    if from_enter then
        search_upvalues(query)
    end
end)

tool_bar.Tables.Check.MouseButton1Click:Connect(function()
    check_tables = not check_tables
    tool_bar.Tables.Check.ImageTransparency = check_tables and 0 or 1
end)

for i,v in next, window.SetValue.Types:GetChildren() do
    if v:IsA("Frame") then
        v.Toggle.MouseButton1Click:Connect(function()
            if v ~= selected_type then
                selected_type.Toggle.Image = "rbxassetid://4137040743"
                v.Toggle.Image = "rbxassetid://4136986319"
                selected_type = v
            end
        end)
    end
end

window.SetValue.Change.MouseButton1Click:Connect(function()
    local input = window.SetValue.Input.Text
    local utype = selected_type.Name:lower()
    if utype == "string" then
    elseif utype == "number" then
        input = tonumber(input)
    elseif utype == "boolean" then
        input = input == "true"
    elseif utype == "function" then
        local ran, result = pcall(loadstring, "return " .. input)
        if ran and typeof(result) == "function" then
            input = result
        end
    elseif utype == "table" then
        local ran, result = pcall(loadstring, "return" .. input)
        if ran and typeof(result) == "table" then
            input = result
        end
    elseif utype == "userdata" then
        local ran, result = pcall(loadstring, "return" .. input)
        if ran and type(result) == "userdata" then
            input = result
        end
    elseif utype == "nil" then
        input = nil
    end

    oh.env.set_upvalue(selected_upvalue.closure, selected_upvalue.index, input)
    window.SetValue.Visible = false
end)

window.SetValue.Cancel.MouseButton1Click:Connect(function()
    window.SetValue.Visible = false
end)

-- Upvalue updating loop
oh.events.poll_upvalues = run_service.RenderStepped:Connect(function()
    if not oh.running then -- If Hydroxide is not running, then disconnect this event to preserve space
        oh.events.poll_upvalues:Disconnect()
    end

    for closure, data in pairs(cache) do -- Update upvalue visuals
        data.update()
    end
end)
