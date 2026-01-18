--!strict

export type Bucket = {
	capacity: number,
	refillPerSecond: number,
	tokens: number,
	lastRefill: number,
}

local TokenBucket = {}

function TokenBucket.new(capacity: number, refillPerSecond: number): Bucket
	capacity = math.max(1, math.floor(capacity))
	refillPerSecond = math.max(0, refillPerSecond)

	return {
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		tokens = capacity,
		lastRefill = os.clock(),
	}
end

function TokenBucket.consume(bucket: Bucket, cost: number): boolean
	cost = math.max(1, math.floor(cost))

	local now = os.clock()
	local elapsed = math.max(0, now - bucket.lastRefill)
	bucket.lastRefill = now

	if bucket.refillPerSecond > 0 then
		bucket.tokens = math.min(bucket.capacity, bucket.tokens + elapsed * bucket.refillPerSecond)
	end

	if bucket.tokens < cost then
		return false
	end

	bucket.tokens -= cost
	return true
end

return TokenBucket
