--!strict
-- ReplicatedStorage.Shared.WorldContainer: the server containers under Workspace.World that the client scans by name (Wild, Materials,
-- Heaters, Sightings: the list is data/Streaming Persistent). With Workspace streaming on, a loose Part is streamed in and out by
-- distance, so the radar would lose every alien past the streaming radius and the waypoint every far node. Only a Model has a
-- streaming mode, so these are Models set to Persistent: all of their children replicate at once, wherever the player stands, and
-- never stream out. They hold a few dozen small parts each (Config.SpawnMaxWild caps Wild). With streaming off a Persistent Model
-- changes nothing, so the home planet and the editor behave as before.

local WorldContainer = {}

-- The container `name` under `parent`: the one already there (a Model is made Persistent; an old Folder from a hand-built place is
-- returned as it is), else a new Persistent Model, parented last so it replicates whole.
function WorldContainer.Get(parent: Instance, name: string): Instance
	local found = parent:FindFirstChild(name)
	if found then
		if found:IsA("Model") then
			found.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end
		return found
	end
	local created = Instance.new("Model")
	created.Name = name
	created.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	created.Parent = parent
	return created
end

return WorldContainer
