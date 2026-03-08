Name = "SEED_PC"
----------------------get-hardware---------------------------------
local storage = component.proxy(component.findComponent("seed_con"))
local switch = component.proxy(component.findComponent("seed_switch"))

local var_x = 100
local var_running = "start"
 
while true do
    event.pull(3)
    var_running = "start"
    for i=1, #storage do
        lines = i
        inv = storage[i]:getInventories()[1]
        inv:sort()
        amount = inv.itemCount
        itemName = "Empty"
        max = 0
        if amount > 1 then
            max = inv:getStack(0).count * inv.size
            itemName = inv:getStack(0).item.type.name
            if amount > (max-var_x) then
                var_running = "stop"
            end
        end
    end
    for i=1, #switch do
    	print(var_running)
        if var_running == "stop" then
            switch[i]:setIsSwitchOn(false)
        else
            switch[i]:setIsSwitchOn(true)
        end
    end
end