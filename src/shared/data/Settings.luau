--!strict
-- Player preferences: every key the Settings screen shows, in display order, with the values the
-- server accepts. A "level" key picks one of `levels` (0-based index stored on the profile; the value
-- at that index is the multiplier the client applies); a "toggle" key stores 0 or 1. Defaults are the
-- index (or 0/1) a fresh profile starts with. Strings: SETTINGS_<key> for the label,
-- SETTINGS_LEVEL_<n> for level names, SETTINGS_ON / SETTINGS_OFF for toggles.
export type SettingDef = { key: string, kind: "level" | "toggle", levels: { number }?, default: number }

local Order: { SettingDef } = {
	{ key = "Ambience", kind = "level", levels = { 0, 0.33, 0.66, 1 }, default = 2 }, -- multiplies Sounds.Volume.Ambience
	{ key = "Sounds", kind = "level", levels = { 0, 0.33, 0.66, 1 }, default = 3 }, -- multiplies Sounds.Volume.UI
	{ key = "ReducedMotion", kind = "toggle", default = 0 }, -- shortens tweens and skips shakes (on top of the system setting)
	{ key = "Silhouettes", kind = "toggle", default = 1 }, -- uncaught species render as shadows until approached
}

local ById: { [string]: SettingDef } = {}
for _, def in ipairs(Order) do
	ById[def.key] = def
end

return { Order = Order, ById = ById }
