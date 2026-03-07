--------------main functions-----------
function tableConcat( t1, t2 )
    for i=1, #t2 do
       t1[#t1+1] = t2[i]
    end
    return t1
end

function tableHasValue( t, value )
    if t == nil or value == nil then
        return false
    end

    for _,v in pairs( t ) do
        if v == value then
            return true
        end
    end

    return false
end

function getComponentsByClass( class, getOne )
    local results = {}

    if ( getOne == nil ) then
        getOne = false
    end

    if type( class ) == "table" then

        for _, c in pairs( class ) do
            local proxies = getComponentsByClass( c, getOne )
            if not getOne then
                tableConcat( results, proxies )
            else
                if( proxies ~= nil ) then
                    return proxies
                end
            end
        end

    elseif type( class ) == "string" then

        local ctype = classes[ class ]
        if ctype ~= nil then
            local comps = component.findComponent( ctype )
            for _, c in pairs( comps ) do
                local proxy = component.proxy( c )
                if getOne and proxy ~= nil then
                    return proxy
                elseif not tableHasValue( results, proxy ) then
                    table.insert( results, proxy )
                end
            end
        end

    end

    if ( getOne ) then
        return {}
    end

    return results
end

function getComponentsByClassAndNick( class, nickParts )
    if type( nickParts ) == 'string' then
        nickParts = { nickParts }
    end

    local classComponents = getComponentsByClass( class )
    local results = {}

    for _, component in pairs( classComponents ) do
        for _, nickPart in pairs( nickParts ) do
            if component.nick:find( nickPart, 1, true ) == nil then
                goto nextComponent
            end
        end

        table.insert( results, component )

        ::nextComponent::
    end

    return results
end

function settingsFromString( str, lowerKeys )
    lowerKeys = lowerKeys or false
    local results = {}
    if str == nil or type( str ) ~= "string" then return results end
    for key, value in string.gmatch( str, '(%w+)=(%b"")' ) do
        if lowerKeys then key = string.lower( key ) end
        results[ key ] = string.sub( value, 2, string.len( value ) - 1 )
    end
    return results
end

function settingsFromComponentNickname( proxy, lowerKeys )
    if proxy == nil then return nil end
    return settingsFromString( proxy[ "nick" ], lowerKeys )
end

Vector2d = {
    x = 0,
    y = 0,
    pattern = '{x=%d,y=%d}',
}
Vector2d.__index = Vector2d
function Vector2d.new( x, y )
    if x == nil or type( x ) ~= "number" then return nil end
    if y == nil or type( y ) ~= "number" then return nil end
    local o = { x = math.floor( x ), y = math.floor( y ) }
    setmetatable( o, { __index = Vector2d } )
    return o
end

--------------GPU----------------------
local gpu = computer.getPCIDevices( classes.GPU_T2_C )[1]
if gpu == nil then
    computer.panic( "No GPU T2 found. Cannot continue." )
end
print(gpu)
--------------Screen-------------------
local computerSettings = settingsFromComponentNickname( computer.getInstance() )
local screens = getComponentsByClassAndNick( {
    "ModuleScreen_C",
   	"Build_Screen_C",
}, computerSettings.screen or '' )
if #screens == 0 then
    computer.panic( "No screen found. Cannot continue." )
end
gpu:bindScreen( screens[1] )
screenSize = gpu:getScreenSize()
print( 'Screen resolution: ' .. screenSize.x .. 'x' .. screenSize.y )
--------------line calc----------------
function get_line(line)
	spacer = (size + 10) * line
	return spacer
end
--------------row calc-----------------
function get_row(row)
	spacer = (size - 25) * row
	return spacer
end
---------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------
function draw_frame(x,y,le,dire,size_d,color_d)
	for i=0, le do
		if dire == "right" then
			gpu:drawText(Vector2d.new(get_row(x+i),get_line(y)),"_",size_d,color_d,TRUE)
		end
		if dire == "down" then
			gpu:drawText(Vector2d.new(get_row(x),get_line(y+i)),"|",size_d,color_d,TRUE)
		end
	end
end

function round(x)
  return math.floor(x + 0.5)
end
----------Parameters------------------
size = 50
color_white = {1.000, 1.000, 1.000, 1.0}
color_red = {1.000, 0.000, 0.000, 1.0}
color_yellow = {1.000, 1.000, 0.000, 1.0}
color_green = {0.000, 1.000, 0.000, 1.0}
w = screenSize.x
h = screenSize.y
---------------------------------------
function main()
	while true do
	draw_frame(0,1,119,"right",size,color_white)
	draw_frame(0,2,36,"down",size,color_white)
	draw_frame(119,2,36,"down",size,color_white)
	draw_frame(60,2,36,"down",size,color_white)
	draw_frame(0,38,119,"right",size,color_white)
	gpu:drawText(Vector2d.new(get_row(50),get_line(0)),"Storage Monitor V3.2",size,color_white,TRUE)
	local storage = component.proxy(component.findComponent("Storage"))
	local fluid = component.proxy(component.findComponent("F_Storage"))
	print("Container:"..#storage)
	print("Tanks:"..#fluid)
	for i=1, #storage do
		inv = storage[i]:getInventories()[1]
		inv:sort()
		amount = inv.itemCount
		itemName = "Empty"
		max = 0
		if amount > 1 then
			max = inv:getStack(0).count * inv.size
			itemName = inv:getStack(0).item.type.name
		end
		gpu:drawText(Vector2d.new(get_row(2),get_line(i+1)),"Container_"..i,size,color_white,TRUE)
		gpu:drawText(Vector2d.new(get_row(19),get_line(i+1)),itemName,size,color_white,TRUE)
		if (max/2) > amount then
			gpu:drawText(Vector2d.new(get_row(44),get_line(i+1)),amount.."/"..max,size,color_red,TRUE)
		end
		if (max/2) < amount then
			gpu:drawText(Vector2d.new(get_row(44),get_line(i+1)),amount.."/"..max,size,color_yellow,TRUE)
		end
		if amount == max then
			gpu:drawText(Vector2d.new(get_row(44),get_line(i+1)),amount.."/"..max,size,color_green,TRUE)
		end
		if amount == 0 then
			gpu:drawText(Vector2d.new(get_row(44),get_line(i+1)),amount.."/"..max,size,color_white,TRUE)
		end	
	end
	for i=1, #fluid do
		itemName = "Empty"
		isF = fluid[i].fluidContent
		maxF = fluid[i].maxFluidContent
		if isF > 1 then
			itemName = fluid[i]:getFluidType().name
		end
		gpu:drawText(Vector2d.new(get_row(62),get_line(i+1)),"Fluid_"..i,size,color_white,TRUE)
		gpu:drawText(Vector2d.new(get_row(72),get_line(i+1)),itemName,size,color_white,TRUE)		
		if (maxF/2) > isF then
			gpu:drawText(Vector2d.new(get_row(106),get_line(i+1)),round(isF).."/"..round(maxF),size,color_red,TRUE)
		end
		if (maxF/2) < isF then
			gpu:drawText(Vector2d.new(get_row(106),get_line(i+1)),round(isF).."/"..round(maxF),size,color_yellow,TRUE)
		end
		if isF == maxF then
			gpu:drawText(Vector2d.new(get_row(106),get_line(i+1)),round(isF).."/"..round(maxF),size,color_green,TRUE)
		end
		if isF > maxF then
			gpu:drawText(Vector2d.new(get_row(106),get_line(i+1)),round(isF).."/"..round(maxF),size,color_green,TRUE)
		end
		if isF == 0 then
			gpu:drawText(Vector2d.new(get_row(106),get_line(i+1)),round(isF).."/"..round(maxF),size,color_white,TRUE)
		end	
	end
	gpu:flush()
	event.pull(10)
	end
end
---------------------------------------
gpu:flush()
gpu:drawText(Vector2d.new(get_row(0),get_line(0)),"Start Terminal......",size,color_white,TRUE)
gpu:drawText(Vector2d.new(get_row(0),get_line(1)),"Please wait......",size,color_red,TRUE)
gpu:flush()
event.pull(10)
gpu:flush()
main()