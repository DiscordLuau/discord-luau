local frktest = require("../../../luau_packages/frktest")
local Dave = require("../src")

local test = frktest.test
local check = frktest.assert.check

local sys = Dave.sys

local function makeFrame(content: string): buffer
	local buf = buffer.create(#content)
	buffer.writestring(buf, 0, content)
	return buf
end

local function frameEq(a: buffer, b: buffer): boolean
	if buffer.len(a) ~= buffer.len(b) then
		return false
	end
	return buffer.readstring(a, 0, buffer.len(a)) == buffer.readstring(b, 0, buffer.len(b))
end

return function()
	test.suite("Encryptor", function()
		test.case("constructs without error", function()
			local enc = Dave.Encryptor.new()
			check.not_nil(enc)
			enc:destroy()
		end)

		test.case("hasKeyRatchet is false on a fresh encryptor", function()
			local enc = Dave.Encryptor.new()
			check.is_false(enc:hasKeyRatchet())
			enc:destroy()
		end)

		test.case("isPassthroughMode is false on a fresh encryptor", function()
			local enc = Dave.Encryptor.new()
			check.is_false(enc:isPassthroughMode())
			enc:destroy()
		end)

		test.case("setPassthroughMode toggles isPassthroughMode", function()
			local enc = Dave.Encryptor.new()
			enc:setPassthroughMode(true)
			check.is_true(enc:isPassthroughMode())
			enc:setPassthroughMode(false)
			check.is_false(enc:isPassthroughMode())
			enc:destroy()
		end)

		test.case("assignSsrcToCodec succeeds without error", function()
			local enc = Dave.Encryptor.new()
			check.should_not_error(function()
				enc:assignSsrcToCodec(12345, sys.codec.opus)
				return
			end)
			enc:destroy()
		end)

		test.case("passthrough encrypt preserves frame bytes", function()
			local enc = Dave.Encryptor.new()
			enc:setPassthroughMode(true)

			local frame = makeFrame("hello dave")
			local out = enc:encrypt(sys.mediaType.audio, 12345, frame)

			check.equal(buffer.len(out), buffer.len(frame))
			check.is_true(frameEq(out, frame))

			enc:destroy()
		end)

		test.case("getStats passthroughCount increments after passthrough encrypt", function()
			local enc = Dave.Encryptor.new()
			enc:setPassthroughMode(true)

			enc:encrypt(sys.mediaType.audio, 12345, makeFrame("frame"))

			local stats = enc:getStats(sys.mediaType.audio)
			check.equal(stats.passthroughCount, 1)
			check.equal(stats.encryptSuccessCount, 0)

			enc:destroy()
		end)
	end)

	test.suite("Decryptor", function()
		test.case("constructs without error", function()
			local dec = Dave.Decryptor.new()
			check.not_nil(dec)
			dec:destroy()
		end)

		test.case("passthrough decrypt preserves frame bytes", function()
			local dec = Dave.Decryptor.new()
			dec:transitionToPassthroughMode(true)

			local frame = makeFrame("hello dave")
			local out = dec:decrypt(sys.mediaType.audio, frame)

			check.equal(buffer.len(out), buffer.len(frame))
			check.is_true(frameEq(out, frame))

			dec:destroy()
		end)

		test.case("getStats passthroughCount increments after passthrough decrypt", function()
			local dec = Dave.Decryptor.new()
			dec:transitionToPassthroughMode(true)

			dec:decrypt(sys.mediaType.audio, makeFrame("frame"))

			local stats = dec:getStats(sys.mediaType.audio)
			check.equal(stats.passthroughCount, 1)
			check.equal(stats.decryptSuccessCount, 0)

			dec:destroy()
		end)
	end)

	test.suite("Encrypt-decrypt roundtrip", function()
		test.case("passthrough roundtrip preserves frame bytes", function()
			local enc = Dave.Encryptor.new()
			local dec = Dave.Decryptor.new()
			enc:setPassthroughMode(true)
			dec:transitionToPassthroughMode(true)

			local frame = makeFrame("roundtrip test frame")
			local encrypted = enc:encrypt(sys.mediaType.audio, 12345, frame)
			local decrypted = dec:decrypt(sys.mediaType.audio, encrypted)

			check.equal(buffer.len(decrypted), buffer.len(frame))
			check.is_true(frameEq(decrypted, frame))

			enc:destroy()
			dec:destroy()
		end)

		test.case("passthrough roundtrip works for video frames", function()
			local enc = Dave.Encryptor.new()
			local dec = Dave.Decryptor.new()
			enc:setPassthroughMode(true)
			enc:assignSsrcToCodec(99999, sys.codec.vp8)
			dec:transitionToPassthroughMode(true)

			local frame = makeFrame("video frame data")
			local encrypted = enc:encrypt(sys.mediaType.video, 99999, frame)
			local decrypted = dec:decrypt(sys.mediaType.video, encrypted)

			check.equal(buffer.len(decrypted), buffer.len(frame))
			check.is_true(frameEq(decrypted, frame))

			enc:destroy()
			dec:destroy()
		end)
	end)
end
