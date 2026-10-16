"""Actual generated ROS ground wire, sharing the snapshot geometry table."""
import io
import struct
import unittest

from xgc2_geometry_msgs.msg import SceneGeometry, SceneGround, SceneObstacle, ScenePart, SceneSnapshot


def roundtrip(message):
    stream = io.BytesIO()
    message.serialize(stream)
    return SceneSnapshot().deserialize(stream.getvalue())


class GroundWireTest(unittest.TestCase):
    def test_exact_fields_and_named_modes(self):
        self.assertEqual(SceneGround.__slots__, ['mode', 'z', 'pose', 'parts'])
        self.assertEqual(SceneGround._slot_types,
                         ['string', 'float64', 'geometry_msgs/Pose', 'xgc2_geometry_msgs/ScenePart[]'])
        self.assertEqual(SceneGround.MODE_DEFAULT_PLANE, 'default_plane')
        self.assertEqual(SceneGround.MODE_MODEL, 'model')
        self.assertEqual(SceneGround.MODE_NONE, 'none')
        self.assertEqual(SceneSnapshot.__slots__[-3:], ['geometries', 'ground', 'obstacles'])

    def test_explicit_default_plane_and_none_preserve_no_numeric_parts(self):
        for mode, z in ((SceneGround.MODE_DEFAULT_PLANE, 1.25), (SceneGround.MODE_NONE, 0.0)):
            with self.subTest(mode=mode):
                message = SceneSnapshot(ground=SceneGround(mode=mode, z=z))
                decoded = roundtrip(message)
                self.assertEqual(decoded.ground.mode, mode)
                self.assertEqual(decoded.ground.z, z)
                self.assertEqual(decoded.ground.parts, [])
                self.assertEqual(decoded.obstacles, [])

    def test_model_pose_parts_color_and_obstacle_share_one_geometry_definition(self):
        payload = struct.pack('<3d', 3.0, 1.0, .8)
        part = ScenePart(id='surface', geometry_index=0)
        part.pose.position.y, part.pose.orientation.w = .3, 1
        part.color.r, part.color.g, part.color.b, part.color.a = .25, .5, .75, 1
        ground = SceneGround(mode=SceneGround.MODE_MODEL, parts=[part])
        ground.pose.position.x, ground.pose.orientation.w = 2, 1
        body = SceneObstacle(id='actual-obstacle', parts=[part])
        message = SceneSnapshot(epoch='source', revision=7, ground=ground,
                                geometries=[SceneGeometry(type=6, parameters=payload)], obstacles=[body])
        decoded = roundtrip(message)
        self.assertEqual(decoded.ground.mode, SceneGround.MODE_MODEL)
        self.assertEqual(decoded.ground.pose.position.x, 2)
        self.assertEqual(decoded.ground.parts[0].pose.position.y, .3)
        self.assertEqual(decoded.ground.parts[0].color.b, .75)
        self.assertEqual(decoded.ground.parts[0].geometry_index, 0)
        self.assertEqual(decoded.obstacles[0].parts[0].geometry_index, 0)
        self.assertEqual([o.id for o in decoded.obstacles], ['actual-obstacle'])
        self.assertEqual(len(decoded.geometries), 1)
        self.assertEqual(bytes(decoded.geometries[0].parameters), payload)


if __name__ == '__main__':
    unittest.main()
