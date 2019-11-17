local players = game:GetService("Players")
local tween_service = game:GetService("TweenService")
local user_input = game:GetService("UserInputService")

local client = players.LocalPlayer
local mouse = client:GetMouse()

local vis_aux = {}

vis_aux.icons = {
    string = "rbxassetid://4231558898",
    number = "rbxassetid://4231558898",
    boolean = "rbxassetid://4231558898",
    ["function"] = "rbxassetid://4231557907",
    table = "rbxassetid://4231559737",
    userdata = "rbxassetid://4231560808",
    RemoteEvent = "rbxassetid://4229806545",
    RemoteFunction = "rbxassetid://4229810474",
    BindableEvent = "rbxassetid://4229809371",
    BindableFunction = "rbxassetid://4229807624"
}

vis_aux.show_path = function(object)
    
end

vis_aux.show_type = function(value)

end

vis_aux.show_info = function(element)

end

-- vis_aux.highlight = function(object, time, extra)
--     local down_event = object.MouseButton1Down
--     local up_event = object.MouseButton1Up

--     local property = extra and extra.property or "BackgroundColor3"
--     local color = object[property]
--     -- local down_color = 
--     -- local up_color = 
--     -- local enter_color = 
--     -- local leave_color = 

--     local animation = tween_service:Create(object, TweenInfo.new(time), {[property] = })

--     if extra and extra.mouse_2 then
--         down_event = object.MouseButton2Down
--         up_event = object.MouseButton2Up
--     end



--     down_event:Connect(function()
    
--     end)

--     up_event:Connect(function()
    
--     end)
-- end

for i,v in next, oh.ui:GetDescendants() do
    if v:FindFirstChild("Description") then
        v.MouseEnter:Connect(function()
            
        end)
    end
end

mouse.Button1Up:Connect(function()
    oh.ui.RightClickMenu.Visible = false
    for i,v in pairs(oh.ui.RightClickMenu:GetChildren()) do
        v.Visible = false
    end
end)

--[[
    Credits to @Tiffblocks for the drag method
]]

local dragging
local dragInput
local dragStart
local startPos
local base = oh.ui.Base
local drag = base.Drag

drag.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = base.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
                dragging = false
			end
		end)
	end
end)

drag.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

user_input.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
	    base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

return vis_aux