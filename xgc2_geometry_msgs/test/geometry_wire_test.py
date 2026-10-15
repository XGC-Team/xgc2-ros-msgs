"""Checks the generated, installed ROS transport against independent byte goldens."""
import io
import struct
import unittest

from xgc2_geometry_msgs.msg import SceneGeometry, ScenePart, SceneObstacle, SceneSnapshot


class GeometryWireTest(unittest.TestCase):
    def test_only_registry_id_and_bytes_are_transport_fields(self):
        self.assertEqual(SceneGeometry.__slots__, ['type', 'parameters'])
        self.assertEqual(SceneGeometry._slot_types, ['uint32', 'uint8[]'])

    def test_analytic_ring_and_temporary_convex_have_stable_little_endian_bytes(self):
        cases = [(6, struct.pack('<3d', 3.0, 1.0, .8)),
                 (5, struct.pack('<II12d', 4, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)),
                 (0x12345678, bytes([0, 255, 128]))]
        for kind, payload in cases:
            message = SceneGeometry(type=kind, parameters=payload)
            stream = io.BytesIO()
            message.serialize(stream)
            self.assertEqual(stream.getvalue(), struct.pack('<II', kind, len(payload)) + payload)
            decoded = SceneGeometry().deserialize(stream.getvalue())
            self.assertEqual(decoded.type, kind)
            self.assertEqual(bytes(decoded.parameters), payload)

    def test_complete_snapshot_preserves_geometry_and_definition_pose(self):
        payload = struct.pack('<3d', 3.0, 1.0, .8)
        part = ScenePart(id='ring', geometry=SceneGeometry(type=6, parameters=payload))
        part.pose.position.y, part.pose.orientation.w = .3, 1
        obstacle = SceneObstacle(id='o', parts=[part])
        obstacle.pose.position.x, obstacle.pose.orientation.w = 2, 1
        message = SceneSnapshot(epoch='source', revision=7, scene_id='scene', obstacles=[obstacle])
        stream = io.BytesIO()
        message.serialize(stream)
        decoded = SceneSnapshot().deserialize(stream.getvalue())
        self.assertEqual(decoded.obstacles[0].parts[0].geometry.type, 6)
        self.assertEqual(bytes(decoded.obstacles[0].parts[0].geometry.parameters), payload)
        self.assertEqual(decoded.obstacles[0].parts[0].pose.position.y, .3)
        self.assertEqual(decoded.obstacles[0].pose.position.x, 2)


if __name__ == '__main__':
    unittest.main()
