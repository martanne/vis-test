local oldexit = os.exit
os.exit = function(status) if status ~= 0 then oldexit(status) end end
require 'busted.runner'()

local function hardfail()
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
			end
		end
	end
	if failed then hardfail() end
end)

vis.events.subscribe(vis.events.PROCESS_RESPONCE, function (name, d, e)
  print(name, e, d)
	if expected_events[name] and #(expected_events[name]) > 0 then
		local current_event = table.remove(expected_events[name], 1)
		print(name, current_event.etype, current_event.expected)
		if d ~= current_event.expected or e ~= current_event.etype then
			print("Event assert failed for process", name)
			print("Expected event:", current_event.etype)
			print("Got event:", e)
			print("Expected value:", current_event.expected, type(current_event.expected))
			print("Got value:", d, type(d))
			if #(expected_events[name]) > 0 then
				print("Remaining expected events to be fired by process", name)
				for i, k in pairs(expected_events[name]) do
					print(i, ": ", k.etype, " - ", k.expected)
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
end)
