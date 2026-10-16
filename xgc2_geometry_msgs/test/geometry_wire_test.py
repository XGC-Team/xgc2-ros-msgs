"""Checks the generated, installed ROS transport against independent byte goldens."""
import io
import struct
import unittest

from xgc2_geometry_msgs.msg import SceneGeometry, ScenePart, SceneObstacle, SceneSnapshot, SceneGround


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
        part = ScenePart(id='ring', geometry_index=0)
        part.pose.position.y, part.pose.orientation.w = .3, 1
        obstacle = SceneObstacle(id='o', parts=[part])
        obstacle.pose.position.x, obstacle.pose.orientation.w = 2, 1
        message = SceneSnapshot(ground=SceneGround(mode=SceneGround.MODE_DEFAULT_PLANE), epoch='source', revision=7, scene_id='scene',
                                geometries=[SceneGeometry(type=6, parameters=payload)], obstacles=[obstacle])
        stream = io.BytesIO()
        message.serialize(stream)
        decoded = SceneSnapshot().deserialize(stream.getvalue())
        self.assertEqual(decoded.obstacles[0].parts[0].geometry_index, 0)
        self.assertEqual(decoded.geometries[0].type, 6)
        self.assertEqual(bytes(decoded.geometries[0].parameters), payload)
        self.assertEqual(decoded.obstacles[0].parts[0].pose.position.y, .3)
        self.assertEqual(decoded.obstacles[0].pose.position.x, 2)

    def test_repeated_large_payload_is_serialized_once(self):
        self.assertEqual(ScenePart.__slots__, ['id', 'pose', 'geometry_index', 'color'])
        self.assertEqual(ScenePart._slot_types[2:], ['uint32', 'std_msgs/ColorRGBA'])
        # A large indexed mesh of disjoint closed tetrahedra. The real wire
        # serializer retains this one definition for all repeated instances.
        vertices, triangles = [], []
        for index in range(2048):
            first = len(vertices)
            vertices.extend((3 * index + x, y, z) for x, y, z in
                            ((0, 0, 0), (1, 0, 0), (0, 1, 0), (0, 0, 1)))
            triangles.extend(tuple(first + i for i in face) for face in
                             ((0, 2, 1), (0, 1, 3), (0, 3, 2), (1, 2, 3)))
        payload = (struct.pack('<II', len(vertices), len(triangles))
                   + b''.join(struct.pack('<3d', *v) for v in vertices)
                   + b''.join(struct.pack('<3I', *t) for t in triangles))
        message = SceneSnapshot(ground=SceneGround(mode=SceneGround.MODE_DEFAULT_PLANE), geometries=[SceneGeometry(type=9, parameters=payload)])
        first = SceneObstacle(id='instance', parts=[ScenePart(id='part', geometry_index=0)])
        first.pose.orientation.w = first.parts[0].pose.orientation.w = 1
        message.obstacles = [first]
        stream = io.BytesIO()
        message.serialize(stream)
        one = stream.getvalue()
        message.obstacles = [first] * 100
        stream = io.BytesIO()
        message.serialize(stream)
        many = stream.getvalue()
        # Each extra instance adds only its fixed obstacle/part wire record.
        instance = io.BytesIO()
        first.serialize(instance)
        self.assertEqual(len(many) - len(one), 99 * len(instance.getvalue()))
        decoded = SceneSnapshot().deserialize(many)
        self.assertEqual(len(decoded.geometries), 1)
        self.assertEqual(bytes(decoded.geometries[0].parameters), payload)
        self.assertEqual([o.parts[0].geometry_index for o in decoded.obstacles], [0] * 100)


if __name__ == '__main__':
    unittest.main()
