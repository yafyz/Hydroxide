local tween_service = game:GetService("TweenService")
local client = game:GetService("Players").LocalPlayer
local mouse = client:GetMouse()

local aux = oh.auxiliary
local env = oh.environment

local gui = oh.gui
local assets = oh.assets

local base = gui.Base
local menu = {
    inspect = gui.RSIDropdown,
    remote_log = gui.RSDropdown
}

local body = base.Body
local tabs = body.Tabs
local window = tabs.RemoteSpy
local options = window.Options
local inspect = tabs.RemoteSpyInspection
local conditions = tabs.RemoteSpyConditions

local add_condition = conditions.AddCondition

local remotes = {
    cache = {},
    hard_ignore = {
        CharacterSoundEvent = true
    }
}
local drop_down = {}
local events = {}

local gmt = env.get_metatable(game)
local nmc = gmt.__namecall
local idx = gmt.__index

local hook_to = {
    Instance.new("RemoteEvent").FireServer,
    Instance.new("RemoteFunction").InvokeServer,
    Instance.new("BindableEvent").Fire,
    Instance.new("BindableFunction").Invoke
}

-- C O R E
local make_params = function(remote, parameters)
    print('test version ==',3)
    local results = inspect.Results
    local params = assets.RemoteDataPod:Clone()
    params.Parent = results

    local filler
    local lindex = 0
    local actualsize = 0
    for i=1, 10 do
        filler = (filler or "") .. string.char(math.floor(math.random() * 94 + 33))
    end
    for i,_ in next, parameters do
        lindex = typeof(i) == "number" and i > lindex and i or lindex
        actualsize = actualsize + 1
    end
    if actualsize == 0 then parameters[1] = filler end
    local res, err = pcall(function ()
        for i=1, lindex do
            if not parameters[i] then
                --parameters[i] = not parameters[i] and filler or parameters[i]
                parameters[i] = filler
            end
        end
    end)
    if not res then
        print('uh oh, a fucky wucky prevented us from detecting nil, err:', err)
    end
    for i,parameter in next, parameters do
        if parameter == filler then parameter = nil end
        local __tostring 
        local meta_table = env.get_metatable(v)
        local method = meta_table and meta_table.__tostring

        if method then
            print(method)
            __tostring = method
            env.set_readonly(meta_table, false)
            meta_table.__tostring = nil
        end

        local element = assets.RemoteData:Clone()
        element.Icon.Image = oh.icons[type(parameter)]
        element.Label.Text = (typeof(parameter) == "Instance" and parameter.Name) or tostring(parameter)
        element.Parent = params

        local increment = UDim2.new(0, 0, 0, 16)
        params.Size = params.Size + increment
        results.CanvasSize = results.CanvasSize + increment

        while not element.Label.TextFits do
            element.Size = element.Size + increment
            params.Size = params.Size + increment
            results.CanvasSize = results.CanvasSize + increment
            wait()
        end

        if __tostring then
            meta_table.__tostring = __tostring
            env.set_readonly(meta_table, true)
        end
    end

    params.MouseButton2Click:Connect(function()
        local old = env.get_thread_context()
        env.set_thread_context(6)

        drop_down.inspect(params, remote, parameters)

        env.set_thread_context(old)
    end)

    aux.apply_highlight(params, { mouse2 = true })
end

local to_script = function(remote, parameters)
    local result = "-- This script was generated by Hydroxide\n\n"
    local method = ({
        RemoteEvent = "FireServer",
        RemoteFunction = "InvokeServer",
        BindableEvent = "Fire",
        BindableFunction = "Invoke"
    })[remote.ClassName]

    for i,value in next, parameters do
        result = result .. "local oh" .. i .. " = "
        result = result .. aux.transform_value(value).. '\n'
    end

    local call_params = ""

    for i = 1, #parameters do
        call_params = call_params .. "oh" .. i .. ", "
    end

    return result .. aux.transform_path(remote:GetFullName()) .. ':' .. method .. '(' .. call_params:sub(1, call_params:len() - 2) .. ')'
end

local compare_tables = function(args, params)
    for i,v in next, args do
        if v ~= params[i] then
            return false
        end
    end

    return true
end

local is_remote = function(object)
    return object.ClassName == "RemoteEvent" or object.ClassName == "RemoteFunction" or object.ClassName == "BindableEvent" or object.ClassName == "BindableFunction" 
end

drop_down.inspect = function(container, remote, parameters)
    local results = inspect.Results

    menu.inspect.Position = UDim2.new(0, mouse.X + 10, 0, mouse.Y + 10)
    menu.inspect.Visible = true

    if events.igen_script and events.iremove then
        events.igen_script:Disconnect()
        events.iremove:Disconnect()

        events.igen_script = nil
        events.iremove = nil
    end

    events.igen_script = menu.inspect.Script.MouseButton1Click:Connect(function()
        env.to_clipboard(to_script(remote, parameters))
    end)

    events.iremove = menu.inspect:FindFirstChild("Remove").MouseButton1Click:Connect(function()
        results.CanvasSize = results.CanvasSize - UDim2.new(0, 0, 0, container.AbsoluteSize.Y)
        container:Destroy()
    end)
end

drop_down.remote_log = function(remote)
    local remote_log = menu.remote_log
    local remote_data = remotes.cache[remote]
    local window = remote_data.window
    
    if events.rblock and events.rignore and events.rclear and events.rremove and events.rconditions then
        events.rblock:Disconnect()
        events.rignore:Disconnect()
        events.rclear:Disconnect()
        events.rremove:Disconnect()
        events.rconditions:Disconnect()

        events.rblock = nil
        events.rignore = nil
        events.rclear = nil
        events.rremove = nil
        events.rconditions = nil
    end

    events.rblock = remote_log.Block.MouseButton1Click:Connect(remote_data.block)
    events.rignore = remote_log.Ignore.MouseButton1Click:Connect(remote_data.ignore)
    events.rclear = remote_log.Clear.MouseButton1Click:Connect(remote_data.clear)
    events.rremove = remote_log:FindFirstChild("Remove").MouseButton1Click:Connect(function()
        remote_data.ignore = true
        window.Parent.CanvasSize = window.Parent.CanvasSize - UDim2.new(0, 0, 0, 25)
        window:Destroy()
        remote_data.window = nil
    end)
    events.rconditions = remote_log.Conditions.MouseButton1Click:Connect(function()
        local old_context = env.get_thread_context()
        env.set_thread_context(6)

        conditions.Visible = true
        oh.selected_component.Visible = false
        oh.selected_component = conditions

        env.set_thread_context(old_context)
    end)

    remote_log.Position = UDim2.new(0, mouse.X + 5, 0, mouse.Y + 5)
    remote_log.Visible = true

    remote_log.Block.Text = (remote_data.blocked and "Unblock") or "Block"
    remote_log.Ignore.Text = (remote_data.ignored and "Spy") or "Ignore"
end

remotes.make_window = function(remote)
    local log = assets.RemoteObject:Clone()
    local class = remote.ClassName
    local log_window = window[class]

    log.Name = remote.Name
    log.Label.Text = remote.Name
    log.Icon.Image = oh.icons[class]
    log.Parent = log_window

    log_window.CanvasSize = log_window.CanvasSize + UDim2.new(0, 0, 0, 25)

    return log
end

remotes.new = function(remote)
    if remotes.cache[remote] then
        return remotes.cache[remote]
    end

    local remote_data = {}
    remote_data.calls = 0
    remote_data.logs = {}
    remote_data.ignored = false
    remote_data.blocked = false
    remote_data.ignored_params = {}
    remote_data.blocked_params = {}
    remote_data.window = remotes.make_window(remote)

    remote_data.is_ignored = function(params)
        for i,ignored_params in next, remote_data.ignored_params do
            if compare_tables(ignored_params, params) then
                return true
            end
        end

        return false
    end

    remote_data.is_blocked = function(params)
        for i,blocked_params in next, remote_data.blocked_params do
            if compare_tables(blocked_params, params) then
                return true
            end
        end

        return false
    end

    remote_data.update = function(parameters)
        remote_data.window.Count.Text = (remote_data.calls <= 999 and remote_data.calls) or "..."
        table.insert(remote_data.logs, parameters)
        
        if remotes.selected == remote then
            make_params(remote, parameters)
        end
    end

    remote_data.block = function()
        local old = env.get_thread_context()
        env.set_thread_context(6)

        local color 
        local blocked = Color3.fromRGB(150, 0, 0)
        local unblocked = Color3.fromRGB(200, 200, 200)

        remote_data.blocked = not remote_data.blocked
        
        if remote_data.ignored then
            blocked = Color3.fromRGB(0, 0, 0)
            unblocked = Color3.fromRGB(100, 100, 100)
        end

        if remote_data.blocked then
            color = blocked
        else
            color = unblocked
        end

        local animation = tween_service:Create(remote_data.window.Label, TweenInfo.new(0.1), {TextColor3 = color})
        animation:Play()

        env.set_thread_context(old)
    end

    remote_data.clear = function()
        local old = env.get_thread_context()
        env.set_thread_context(6)

        local results = inspect.Results
        remote_data.logs = {}
        remote_data.calls = 0
        remote_data.window.Count.Text = "0"

        if remotes.selected == remote then
            for i, result in next, results:GetChildren() do
                if not result:IsA("UIListLayout") then
                    result:Destroy()
                end
            end

            results.CanvasSize = UDim2.new(0, 0, 0, 0)
        end

        env.set_thread_context(old)
    end

    remote_data.ignore = function()
        local old = env.get_thread_context()
        env.set_thread_context(6)

        local text
        local color 
        local ignored = Color3.fromRGB(100, 100, 100)
        local spy = Color3.fromRGB(200, 200, 200)

        remote_data.ignored = not remote_data.ignored
        
        if remote_data.blocked then
            ignored = Color3.fromRGB(0, 0, 0)
            spy = Color3.fromRGB(150, 0, 0)
        end

        if remote_data.ignored then
            color = ignored
            text = "Spy"
        else
            color = spy
            text = "Ignore"
        end

        local animation = tween_service:Create(remote_data.window.Label, TweenInfo.new(0.1), {TextColor3 = color})
        animation:Play()

        inspect.Toggle.Text = text

        env.set_thread_context(old)
    end

    remote_data.window.MouseButton1Click:Connect(function()
        local old = env.get_thread_context()
        env.set_thread_context(6)

        if remotes.selected ~= remote then
            local results = inspect.Results
            for i, result in next, results:GetChildren() do
                if not result:IsA("UIListLayout") then
                    result:Destroy()
                end
            end

            results.CanvasSize = UDim2.new(0, 0, 0, 0)

            for i, log in next, remote_data.logs do
                make_params(remote, log)
            end

            if events.ignore and events.clear and events.conditions then
                events.ignore:Disconnect()
                events.clear:Disconnect()
                events.conditions:Disconnect()
    
                events.ignore = nil
                events.clear = nil
                events.conditions = nil
            end
    
            inspect.Toggle.Text = (remote_data.ignored and "Spy") or "Ignore"

            events.ignore = inspect.Toggle.MouseButton1Click:Connect(remote_data.ignore)
            events.clear = inspect.Clear.MouseButton1Click:Connect(remote_data.clear)
            events.conditions = inspect.Conditions.MouseButton1Click:Connect(function()
                conditions.Visible = true
                oh.selected_component.Visible = false
                oh.selected_component = conditions
            end)
        end

        local label = inspect.Remote.Label
        label.Text = remote.Name
        label.Size = UDim2.new(0, label.TextBounds.X + 5, 0, 25)
        label.Position = UDim2.new(1, -(label.TextBounds.X + 10), 0, 0)
        
        inspect.Remote.Icon.Position = UDim2.new(1, -(label.TextBounds.X + 35), 0, 0)

        body.TabsLabel.Text = "  RemoteSpy : Inspection"

        inspect.Visible = true
        oh.selected_component.Visible = false
        oh.selected_component = inspect
        remotes.selected = remote

        env.set_thread_context(old)
    end)

    remote_data.window.MouseButton2Click:Connect(function()
        local old = env.get_thread_context()
        env.set_thread_context(6)

        drop_down.remote_log(remote)

        env.set_thread_context(old)
    end)

    remotes.cache[remote] = remote_data
    return remote_data
end

-- H O O K I N G

for remote_index = 1, #hook_to do
    local hook 
    hook = env.hook_function(hook_to[remote_index], env.new_cclosure(function(remote, ...)
        local old = env.get_thread_context()
        local vargs = {...}

        env.set_thread_context(6)

        if env.check_caller() or remotes.hard_ignore[remote.Name] then
            return hook(remote, ...)
        end

        local remote_data = remotes.cache[remote] or remotes.new(remote)

        if remote_data.ignored or remote_data.is_ignored(vargs) then
            return hook(remote, ...)
        elseif remote_data.blocked or remote_data.is_blocked(vargs) then
            return nil
        end

        remote_data.calls = remote_data.calls + 1
        remote_data.update(vargs)

        env.set_thread_context(old)

        return hook(remote, ...)
    end))
end

local namecall = Instance.new("BindableFunction")
namecall.OnInvoke = env.new_cclosure(function(remote, vargs)
    local remote_data = remotes.cache[remote] or remotes.new(remote)

    if remote_data.blocked or remote_data.ignored or remote_data.is_ignored(vargs) or remote_data.is_blocked(vargs) then
        return remote_data
    end

    remote_data.calls = remote_data.calls + 1
    remote_data.update(vargs)

    return remote_data
end)

env.set_readonly(gmt, false)

gmt.__namecall = env.new_cclosure(function(obj, ...) [nonamecall]
    local old = env.get_thread_context()
    local vargs = {...}
    env.set_thread_context(6)

    if is_remote(obj) then
        if env.check_caller() or remotes.hard_ignore[obj.Name] then
            return nmc(obj, ...)
        end

        local remote_data = namecall.Invoke(namecall, obj, vargs)

        if remote_data.blocked or remote_data.is_blocked(vargs) then
            return nil
        end
    end

    env.set_thread_context(old)

    return nmc(obj, ...)
end)

env.set_readonly(gmt, true)

-- E V E N T S
remotes.selected_option = options.RemoteEvent
for i, option in next, options:GetChildren() do
    if option:IsA("TextButton") then
        option.MouseButton1Click:Connect(function()
            local old = window[remotes.selected_option.Name]
            local old_anim = tween_service:Create(options[remotes.selected_option.Name], TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
            local new_anim = tween_service:Create(option, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
        
            old.Visible = false
            old_anim:Play()

            window[option.Name].Visible = true
            new_anim:Play()

            remotes.selected_option = option
            inspect.Remote.Icon.Image = oh.icons[remotes.selected_option.Name]
        end)

        aux.apply_highlight(option, {
            condition = selected_option ~= option,
            new_color = Color3.fromRGB(40, 40, 40),
            down_color = Color3.fromRGB(40, 40, 40),
        })
    end
end

mouse.Button1Up:Connect(function()
    menu.inspect.Visible = false
    menu.remote_log.Visible = false
end)

for i,option in next, menu.inspect:GetChildren() do
    if option:IsA("TextButton") then
        option.MouseButton1Click:Connect(function()
            menu.inspect.Visible = false
        end)

        aux.apply_highlight(option)
    end
end

for i,option in next, menu.remote_log:GetChildren() do
    if option:IsA("TextButton") then
        option.MouseButton1Click:Connect(function()
            menu.remote_log.Visible = false
        end)

        aux.apply_highlight(option)
    end
end

local condition_type = add_condition.Types.String
for i,v in next, add_condition.Types:GetChildren() do
    if v:IsA("Frame") then
        v.Toggle.MouseButton1Click:Connect(function()
            condition_type.Toggle.Image = "rbxassetid://4137040743" 
            v.Toggle.Image = "rbxassetid://4136986319"
            condition_type = v
        end)
    end
end
