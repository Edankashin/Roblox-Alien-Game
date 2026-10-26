"""Tests for tools/lint_data.lint_streaming (data/Streaming against the three Rojo project files and its own rules), with no Studio.

Standard library only. Run:  python3 -I -m unittest discover -s tools/tests -p 'test_*.py'
"""
from __future__ import annotations

import copy
import json
import pathlib
import shutil
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import lint_data  # noqa: E402

NAMES = ("Streaming", "Config", "Worlds", "WorldGen1", "WorldGen2")


class StreamingLint(unittest.TestCase):
    def setUp(self):
        reader = lint_data.TableReader()
        self.pristine = {name: reader.read(ROOT / f"src/shared/data/{name}.luau") for name in NAMES}
        self.tmp = pathlib.Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, True)
        for project in lint_data.STREAMING_PROJECTS:
            shutil.copy(ROOT / project, self.tmp / project)
        services = self.tmp / "src/server/Services"
        services.mkdir(parents=True)
        for name in lint_data.STREAMING_CONTAINER_FILES:
            shutil.copy(ROOT / "src/server/Services" / f"{name}.luau", services / f"{name}.luau")

    def failures(self, change=None):
        tables = copy.deepcopy(self.pristine)
        if change:
            change(tables)
        return lint_data.lint_streaming(tables, self.tmp)

    def edit_project(self, project, change):
        path = self.tmp / project
        data = json.loads(path.read_text())
        change(data["tree"]["Workspace"]["$properties"])
        path.write_text(json.dumps(data, indent=2))

    def test_shipped_files_are_clean(self):
        self.assertEqual(lint_data.lint_streaming(self.pristine, ROOT), [])
        self.assertEqual(self.failures(), [])

    def test_min_radius_under_the_spawn_ring_fails(self):
        def change(tables):
            tables["Streaming"]["MinRadius"] = tables["Config"]["SpawnRadius"] - 1
        self.assertTrue(any("under Config.SpawnRadius" in f for f in self.failures(change)))

    def test_target_below_min_fails(self):
        def change(tables):
            tables["Streaming"]["TargetRadius"] = tables["Streaming"]["MinRadius"] - 1
        self.assertTrue(any("TargetRadius" in f and "under MinRadius" in f for f in self.failures(change)))

    def test_target_past_the_far_corner_fails(self):
        def change(tables):
            tables["Streaming"]["TargetRadius"] = 1024
        self.assertTrue(any("farthest corner" in f for f in self.failures(change)))

    def test_a_built_world_without_a_row_fails(self):
        def change(tables):
            del tables["Streaming"]["Enabled"][2]
        self.assertTrue(any("no row for built world 2" in f for f in self.failures(change)))

    def test_a_project_file_that_disagrees_fails(self):
        self.edit_project("default.project.json", lambda props: props.update(StreamingTargetRadius=1024))
        found = self.failures()
        self.assertEqual(len(found), 1)
        self.assertIn("default.project.json: StreamingTargetRadius", found[0])

    def test_a_project_file_without_the_switch_fails(self):
        self.edit_project("world2.project.json", lambda props: props.pop("StreamingEnabled"))
        self.assertTrue(any("world2.project.json: StreamingEnabled" in f for f in self.failures()))

    def test_the_home_planet_must_not_stream(self):
        self.edit_project("home.project.json", lambda props: props.update(StreamingEnabled=True))
        self.assertTrue(any("home.project.json: StreamingEnabled" in f for f in self.failures()))

    def test_a_missing_persistent_name_fails(self):
        def change(tables):
            names = tables["Streaming"]["Persistent"]
            for index, name in list(names.items()):
                if name == "Wild":
                    del names[index]
        self.assertTrue(any("Streaming.Persistent must list Wild" in f for f in self.failures(change)))

    def test_a_service_that_builds_a_plain_folder_fails(self):
        path = self.tmp / "src/server/Services/Spawner.luau"
        path.write_text(path.read_text().replace("WorldContainer.Get(", "Folder.Get("))
        self.assertTrue(any("Spawner.luau" in f for f in self.failures()))


if __name__ == "__main__":
    unittest.main()
