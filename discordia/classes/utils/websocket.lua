local jit = require('jit')
local json = require('json')
local websocket = require('coro-websocket')

local WebSocket = class('WebSocket')

function WebSocket:__init(gateway)
	if gateway then self:connect(gateway) end
end

function WebSocket:connect(gateway)
	gateway = gateway .. '/' -- hotfix for codec error
	local options = websocket.parseUrl(gateway)
	self.res, self.read, self.write = websocket.connect(options)
end

function WebSocket:send(payload)
	local message = {opcode = 1, payload = json.encode(payload)}
	return self.write(message)
end

function WebSocket:receive()
	local message = self.read()
	if not message then return end
	return json.decode(message.payload)
end

function WebSocket:heartbeat(sequence)
	self:send({
		op = 1,
		d = sequence
	})
end

function WebSocket:identify(token)
	self:send({
		op = 2,
		d = {
			token = token,
			properties = {
				['$os'] = jit.os,
				['$browser'] = 'Discordia',
				['$device'] = 'Discordia',
				['$referrer'] = '',
				['$referring_domain'] = ''
			},
			large_threshold = 100, -- 50 to 250
			compress = false
		}
	})
end

function WebSocket:statusUpdate(idleSince, gameName)
	self:send({
		op = 3,
		d = {
			idle_since = idleSince or json.null,
			game = {name = gameName or json.null}
		}
	})
end

function WebSocket:voiceStateUpdate(guildId, channelId, selfMute, selfDeaf)
	self:send({
		op = 4,
		d = {
			guild_id = guildId,
			channel_id = channelId or json.null,
			self_mute = selfMute,
			self_deaf = selfDeaf
		}
	})
end

function WebSocket:voiceServerPing()
	-- not documented
end

function WebSocket:resume()
end

function WebSocket:requestGuildMembers(guildId)
	self:send({
		op = 8,
		d = {
			guild_id = guildId,
			query = '',
			limit = 0
		}
	})
end

return WebSocket
