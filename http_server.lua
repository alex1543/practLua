-- создание един. подключения к MySQL.
package.cpath = package.cpath .. ";C:/lua/clibs/?.dll"
local socket = require("socket")
mysql = require "luasql.mysql"
local env  = mysql.mysql()
local conn = env:connect('test','root','','localhost',3306)
cursor,errorString = conn:execute('SET NAMES utf8')
	
-- чтение заголовка от User для нахождения строки с параметрами.
local function read_param_string(client)
	local first_header_line, err = client:receive("*l")
	if first_header_line == nil then return nil, err end

	local pattern = "GET%s(%S+)%sHTTP"
	local match = string.match(first_header_line, pattern)
	match = string.gsub(tostring(match), "/?%?", "")
			:gsub("^/", "")
			:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)

	if match ~= '' then
		return match
	else
		return nil, err
	end
end

-- основная функция для формирования таблицы.
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

-- получение версии БД из MySQL.
local function ViewVer(conn)
	print("BD VERSION.\n")
	cursor,errorString = conn:execute([[SELECT VERSION() AS ver]])
	row = cursor:fetch ({}, "a")
	local line_ver = row.ver
	cursor:close()
	return line_ver
end

-- формирование HTML для отправки User.
local function thread_func()
-- построчное чтение файла из шаблона.	
	local file = "select.html"
	local line_all = ''
	for line in io.lines(file) do
		if not string.find(line, "@tr") and not string.find(line, "@ver") then
			line_all = line_all .. line
		end
		if string.find(line, "@tr") then
			line_all = line_all .. ViewSelect(conn)
		end
		if string.find(line, "@ver") then
			line_all = line_all .. ViewVer(conn)
		end	
	end
	coroutine.yield(line_all)
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

-- парсинг строки с параметрами.
function parse_param_string(paramString)
	print("Given params: " .. paramString)

	local col1, col2, col3
	for pair in paramString:gmatch("([^&]+)") do
		local key, value = pair:match("([^=]+)=(.*)")
		if key == "col1" then
			col1 = value
		elseif key == "col2" then
			col2 = value
		elseif key == "col3" then
			col3 = value
		end
	end

	print("First value: " .. tostring(col1))
	print("Second value: " .. tostring(col2))
	print("Third value: " .. tostring(col3))

	return col1, col2, col3
end

-- добавление строки в таблицу.
function insert_values(col1, col2, col3)
	local sql = string.format("INSERT INTO myarttable (text, description, keywords) VALUES ('%s', '%s', '%s')", col1, col2, col3)
	cursor,errorString = conn:execute(sql)
	if errorString == nil then
		print("Insertion successful")
	end
end

-- создание web-сервера.
local server = assert(socket.tcp())
server:setoption("reuseaddr", true)
server:settimeout(0)
assert(server:bind("0.0.0.0", 8880))
server:listen(0)

print("Listening on http://localhost:8880/ ...")

while true do
	-- ожидание подключений...
	local client, err = server:accept()

	if client then
		local param_string = read_param_string(client)

		if param_string ~= nil then
			local col1, col2, col3 = parse_param_string(param_string)
			if col1 ~= nil and col2 ~= nil and col3 ~= nil then
				insert_values(col1, col2, col3)
			end
		end

		local status, data_html = coroutine.resume(coroutine.create(thread_func))
		client:send('HTTP/1.1 200 OK; Content-Type: text/html; charset=utf-8 \n\r\n\r' .. data_html)
		client:close()

		print("Sending to user... ok.\n")
	end
end

-- закрытие подключения к БД.
conn:close()
env:close()