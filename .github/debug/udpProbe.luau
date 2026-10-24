-- Sends one datagram each way between a server bound like discord_stub's and a client bound like std_polyfills'
-- net.udpSocket, and prints the sender address each side sees.
local net = zune.net

local server = net.createSocket(net.ADDRF.INET, net.SOCKF.DGRAM, net.IPPROTO.UDP)
local client = net.createSocket(net.ADDRF.INET, net.SOCKF.DGRAM, net.IPPROTO.UDP)

server:bindIp("127.0.0.1", 0)
client:bindIp("0.0.0.0", 0)

local serverPort = server:getName().port

print(`server bound 127.0.0.1:{serverPort}, client name {client:getName().address}:{client:getName().port}`)

zune.task.delay(5, function()
	print("TIMEOUT: no reply within 5 s")
	zune.process.exit(2)
end)

zune.task.spawn(function()
	local address, packet = server:recvMsg(65536)

	print(
		`server got {buffer.tostring(packet)} from address={address.address} port={address.port} family={address.family}`
	)
	server:sendMsg(address.port, address.address, "pong")
end)

client:sendMsg(serverPort, "127.0.0.1", "ping")

local address, packet = client:recvMsg(65536)

print(`client got {buffer.tostring(packet)} from address={address.address} port={address.port} family={address.family}`)
print(`matches host "127.0.0.1": {address.address == "127.0.0.1"}, matches port: {address.port == serverPort}`)
zune.process.exit(0)
