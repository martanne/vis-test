require 'busted.runner'()

local function hardfail()
	-- It is only way to change exitcode of vis from the QUIT event handler
	io.popen("kill -9 $PPID", "r")
end

local expected_events = {}

local failed = false
vis.events.subscribe(vis.events.QUIT, function ()
	for k, v in pairs(expected_events) do
		if v and #v > 0 then
			failed = true
			print("The following events did not happened for process", k)
			for i, vv in pairs(v) do
				print(i, ": ", vv.etype, " - ", vv.expected)
				print(tostring(i)..": ", vv.etype, " - ("..type(vv.expected)..")",
				      vv.expected)
			end
		end
	end
	if failed then hardfail() end
end)

vis.events.subscribe(vis.events.PROCESS_RESPONSE, function (name, d, e)
	if expected_events[name] and #(expected_events[name]) > 0 then
		local current_event = table.remove(expected_events[name], 1)
		if d ~= current_event.expected or e ~= current_event.etype then
			print("Event assert failed for process", name)
			print("Expected event:", current_event.etype)
			print("Got event:     ", e)
			print("Expected value:("..type(current_event.expected)..")",
			      current_event.expected)
			print("Got value:     ("..type(d)..")", d)
			if #(expected_events[name]) > 0 then
				print("Remaining expected events to be fired by process", name)
				for i, k in pairs(expected_events[name]) do
					print(tostring(i)..": ", k.etype, " - ("..type(k.expected)..")",
					      k.expected)
				end
			end
			hardfail()
		end
	end
end)

local function event_assert(name, eventtype, expected)
	if not expected_events[name] then expected_events[name] = {} end
	table.insert(expected_events[name], {etype = eventtype, expected = expected})
end

describe("vis.communicate", function ()
	it("process creation", function ()
		event_assert("starttest", "STDOUT", "testanswer\n")
		event_assert("starttest", "EXIT", 0)
		vis:communicate("starttest", "echo testanswer")
	end)
	it("process termination", function()
	  event_assert("termtest", "SIGNAL", 15)
		local handle = vis:communicate("termtest", "sleep 1s")
		handle:close()
	end)
	it("process input/stderr", function()
	  event_assert("inputtest", "STDERR", "testdata\n")
	  event_assert("inputtest", "EXIT", 0)
		local handle = vis:communicate("inputtest", "read n; echo $n 1>&2")
		handle:write("testdata\n")
		handle:flush()
		-- do not close handle because it is being closed automaticaly
		-- when process quits
	end)
end)
