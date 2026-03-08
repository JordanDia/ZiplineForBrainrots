local Hud = require(script.Parent.mount.Hud)

return function(parent: Instance)
    local mounted = {}

    mounted.Hud = Hud(parent)
    
    return function()
        for _, gui in pairs(mounted) do
            if gui.Destroy then
                gui:Destroy()
            end
        end
    end
end
