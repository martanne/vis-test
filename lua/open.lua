local win = vis.win
local results = {}
results[1] = win.file.name == 'open.in'
vis:open('open.aux')
-- vis:command('e open.aux')
results[2] = win.file.name == 'open.aux'

delete(win, '%')
for i = 1, #results do
	append(win, i-1, tostring(results[i]))
end
vis:command('w open.status')
