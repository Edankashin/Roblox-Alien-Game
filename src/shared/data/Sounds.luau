--!strict
-- Sound ids for every UI and capture cue. All placeholders (rbxassetid://0) until the audio pass;
-- Builder.playSound skips an id of 0 so nothing errors while they are empty.
return {
	Click = "rbxassetid://0",
	CatchHit = "rbxassetid://0", -- the ticker stops in the Good zone
	Perfect = "rbxassetid://0", -- the ticker stops in the Perfect zone
	Miss = "rbxassetid://0",
	Wiggle = "rbxassetid://0", -- a Good hit that failed the catch roll
	Fled = "rbxassetid://0",
	ScrapTick = "rbxassetid://0", -- the Scrap counter rolls
	Reveal = {
		Common = "rbxassetid://0",
		Uncommon = "rbxassetid://0",
		Rare = "rbxassetid://0",
		Epic = "rbxassetid://0",
		Legendary = "rbxassetid://0",
		Cosmic = "rbxassetid://0",
		Secret = "rbxassetid://0",
	} :: { [string]: string },
}
