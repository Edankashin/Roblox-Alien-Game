--!strict
-- ReplicatedStorage.Shared.TokenBucket: a budget that refills with time, for the server's own cost limits (Visiting
-- spends one token per read of another player's save or home server). Pure: the caller passes the clock, so the
-- same rule runs in the headless tests. A bucket starts full, holds at most `capacity`, gains one token every
-- `refillSeconds`, and Take spends one or is refused.

local TokenBucket = {}

export type Bucket = { capacity: number, refillSeconds: number, tokens: number, at: number }

-- A full bucket as of `now`.
function TokenBucket.New(capacity: number, refillSeconds: number, now: number): Bucket
	return { capacity = capacity, refillSeconds = refillSeconds, tokens = capacity, at = now }
end

-- Spends one token as of `now`; false (and nothing spent) when the bucket is empty. A clock that goes backwards
-- refills nothing.
function TokenBucket.Take(bucket: Bucket, now: number): boolean
	local elapsed = math.max(now - bucket.at, 0)
	bucket.tokens = math.min(bucket.capacity, bucket.tokens + elapsed / bucket.refillSeconds)
	bucket.at = math.max(now, bucket.at)
	if not (bucket.tokens >= 1) then
		return false
	end
	bucket.tokens -= 1
	return true
end

return TokenBucket
