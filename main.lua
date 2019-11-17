--[[
                ▄████████▄   ▄█▄    ▄█▄   
                ███    ███   ███    ███   
                ███    ███   ███    ███   
                ███    ███   ████▄▄████  ▄███▄▄▄▄███▄ 
                ███    ███   ████▀▀████  ▀███▀▀▀▀███▀  
                ███    ███   ███    ███   
                ███    ███   ███    ███   
                ▀████████▀   ▀█▀    ▀█▀    
                      :::[H:Y:D:R:O:X:I:D:E]:::
                   -- developed by nrv-ous/hush --   
                   
                  !!PLEASE MAKE SURE YOU HAVE THE!!
                   !!HYDROXIDE AUXILIARY UNIT IN!!
                !!YOUR EXPLOIT'S AUTO-EXECUTE FOLDER!!
]]--
assert(oh, "You do not have the Hydroxide auxiliary unit in your auto-execute folder!")

oh.load_from_file = false -- Toggle to true if you're modifying Hydroxide files from your PC
oh.ui = import(4369731232)
oh.assets = import(4369733667)
oh.v_aux = import("visual_aux.lua")
oh.icons = oh.v_aux.icons

import("upvalue_scanner.lua")

oh.initialize()