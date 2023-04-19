
package.cpath = package.cpath .. ";C:/lua/clibs/?.dll"

local socket = require("socket")

local function read_request(client)

	local referer_uri = ''
	local reading = true
	while reading do
		local header_line, err = client:receive("*l")
		reading = (header_line ~= "" and header_line ~= nil)
		if reading then

			if string.match (header_line, "Referer: ") then
			
				referer_uri = header_line:sub(10)
				print(referer_uri)

			end
		end
	end

	if referer_uri ~= '' then
		return referer_uri
	else
		return nil, err
	end
end


function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function ViewSelect(conn)

	-- заголовок таблицы.
	local line_table = "<tr>"
	cursor,errorString = conn:execute([[SHOW COLUMNS FROM myarttable]])
	row = cursor:fetch ({}, "a")
	while row do
	   line_table = line_table .. string.format("<td>%s</td>", row.Field)
	   row = cursor:fetch (row, "a")
	end
	cursor:close()
	line_table = line_table .. "</tr>"

	-- строки таблицы.
	cursor,errorString = conn:execute([[SELECT * FROM myarttable WHERE id>14 ORDER BY id DESC]])
	row = cursor:fetch ({}, "a")
	while row do
	   line_table = line_table .. string.format("<tr><td> %s </td><td> %s </td><td> %s </td><td> %s </td></tr>", row.id, row.text, row.description, row.keywords)
	   row = cursor:fetch (row, "a")
	end
	cursor:close()
	
	return line_table
end

local function ViewVer(conn)
	-- версия БД.
	cursor,errorString = conn:execute([[SELECT VERSION() AS ver]])
	row = cursor:fetch ({}, "a")
	local line_ver = row.ver
	cursor:close()
	return line_ver
end

local function thread_func()
-- построчное чтение файла и luasql.
	mysql = require "luasql.mysql"
	local env  = mysql.mysql()
	local conn = env:connect('test','root','','localhost',3306)	
	
	local file = "select.html"
	local line_all = ''
	for line in io.lines(file) do
	
		if line ~= "@tr" and line ~= "@ver" then
			line_all = line_all .. line
		end
		if line == "@tr" then
			line_all = line_all .. ViewSelect(conn)
		end
		if line == "@ver" then
			line_all = line_all .. ViewVer(conn)
		end	
		
		
	end

	conn:close()
	env:close()
	
	coroutine.yield(line_all)
    -- coroutine.yield("<html><body><p>Hello Web!</p></body></html>")
 
end


function urldecode(s)
  s = s:gsub('+', ' '):gsub('%%(%x%x)', function(h)
    return string.char(tonumber(h, 16))
  end)
  return s
end
 
function parseurl(s)
  s = s:match('%s+(.+)')
  local ans = {}
  for k,v in s:gmatch('([^&=?]-)=([^&=?]+)' ) do
    ans[ k ] = urldecode(v)
  end
  return ans
end

function IsGetParInsert(s)
	if s == not null then
		print(s)
		
		
		t = parseurl(s)
		print(t.col1)
	end
end

-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.tcp())
server:setoption("reuseaddr", true)
server:settimeout(0)
assert(server:bind("0.0.0.0", 8080))
server:listen(30)

local ip, port = server:getsockname()
print("Listening on http://localhost:8080/ ...")

-- loop forever waiting for clients
while true do
	-- wait for a connection from any client
	local client, err = server:accept()

	if client then
		local request = read_request(client)
		
		if request ~= '' then
		--	print(request)
			IsGetParInsert(request)
			
			
			local status, data_html = coroutine.resume(coroutine.create(thread_func))
			client:send('HTTP/1.1 200 OK; Content-Type: text/html; charset=utf-8 \n\r\n\r' .. data_html)
			client:close()

			print("Sending to user... ok.\n")
		--	print("send:"..dump(data_html).."\n")

		end

	end
end
