"""Independent CPU reference for the pinned CesiumMan glTF fixture.

Read raw GLB accessors, interpolate LINEAR TRS channels, compose the source node
hierarchy, and skin with global_joint * inverse_bind. Never read Godot poses.
This deliberately supports only the subset used by the pinned fixture.
"""
import hashlib
import json
import struct
from pathlib import Path

import numpy as np

ASSET_SHA256 = "b7001eaeea8254bd44773bcd247e78696d94169388fbb2a1800fc69434e777d9"
HEAD = "Skeleton_neck_joint_2"


def rotation(q):
    x, y, z, w = np.asarray(q) / np.linalg.norm(q)
    return np.array([[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                     [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                     [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]])


def slerp(a, b, weight):
    a, b = a / np.linalg.norm(a), b / np.linalg.norm(b)
    dot = np.dot(a, b)
    if dot < 0:
        b, dot = -b, -dot
    if dot > .9995:
        value = a + (b - a) * weight
        return value / np.linalg.norm(value)
    angle = np.arccos(np.clip(dot, -1, 1))
    return (np.sin((1-weight)*angle)*a + np.sin(weight*angle)*b) / np.sin(angle)


class Character:
    def __init__(self, path):
        data = Path(path).read_bytes()
        assert hashlib.sha256(data).hexdigest() == ASSET_SHA256, "Unexpected character asset"
        assert struct.unpack_from("<4sII", data) == (b"glTF", 2, len(data))
        length, kind = struct.unpack_from("<II", data, 12)
        assert kind == 0x4e4f534a
        self.doc = json.loads(data[20:20+length])
        binary_length, kind = struct.unpack_from("<II", data, 20+length)
        assert kind == 0x004e4942
        self.binary = data[28+length:28+length+binary_length]
        self.nodes = self.doc["nodes"]
        self.head = next(i for i, node in enumerate(self.nodes) if node.get("name") == HEAD)
        self.skin = self.doc["skins"][0]
        self.inverse_bind = self.accessor(self.skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
        primitive = self.doc["meshes"][0]["primitives"][0]
        assert primitive["mode"] == 4
        attributes = primitive["attributes"]
        self.vertices = self.accessor(attributes["POSITION"])
        self.joints = self.accessor(attributes["JOINTS_0"]).astype(int)
        self.weights = self.accessor(attributes["WEIGHTS_0"])
        assert np.max(abs(self.weights.sum(axis=1) - 1)) < 1e-6
        self.indices = self.accessor(primitive["indices"]).ravel().astype(np.int32)
        self.channels = []
        animation = self.doc["animations"][0]
        for channel in animation["channels"]:
            sampler = animation["samplers"][channel["sampler"]]
            assert sampler.get("interpolation", "LINEAR") == "LINEAR"
            self.channels.append((channel["target"], self.accessor(sampler["input"]).ravel(),
                                  self.accessor(sampler["output"])))
        # Authored local boom starts at a useful world view, then follows the head.
        initial_camera = np.eye(4)
        initial_camera[:3, 3] = [0, 1, 2.5]
        self.boom = np.linalg.inv(self.pose(0)[self.head]) @ initial_camera

    def accessor(self, index):
        accessor = self.doc["accessors"][index]
        assert "sparse" not in accessor and not accessor.get("normalized", False)
        view = self.doc["bufferViews"][accessor["bufferView"]]
        assert view.get("buffer", 0) == 0
        dtype = np.dtype({5123: "<u2", 5125: "<u4", 5126: "<f4"}[accessor["componentType"]])
        columns = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[accessor["type"]]
        offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        return np.ndarray((accessor["count"], columns), dtype=dtype, buffer=self.binary,
                          offset=offset, strides=(view.get("byteStride", columns*dtype.itemsize), dtype.itemsize)).astype(np.float64)

    def pose(self, seconds):
        values = [{key: node.get(key, default) for key, default in
                   [("translation", [0, 0, 0]), ("rotation", [0, 0, 0, 1]), ("scale", [1, 1, 1])]} for node in self.nodes]
        for target, times, keys in self.channels:
            next_index = int(np.searchsorted(times, seconds, side="right"))
            if next_index == 0:
                value = keys[0]
            elif next_index == len(times):
                value = keys[-1]
            else:
                previous = next_index - 1
                weight = (seconds-times[previous]) / (times[next_index]-times[previous])
                value = slerp(keys[previous], keys[next_index], weight) if target["path"] == "rotation" else (
                    keys[previous]*(1-weight) + keys[next_index]*weight)
            values[target["node"]][target["path"]] = value
        poses = {}

        def visit(index, parent):
            node, trs = self.nodes[index], values[index]
            if "matrix" in node:
                local = np.array(node["matrix"]).reshape(4, 4).T
            else:
                local = np.eye(4)
                local[:3, :3] = rotation(trs["rotation"]) @ np.diag(trs["scale"])
                local[:3, 3] = trs["translation"]
            poses[index] = parent @ local
            for child in node.get("children", []):
                visit(child, poses[index])

        for root in self.doc["scenes"][self.doc.get("scene", 0)]["nodes"]:
            visit(root, np.eye(4))
        return poses

    def deform(self, poses):
        matrices = np.array([poses[i] for i in self.skin["joints"]]) @ self.inverse_bind
        weighted = (matrices[self.joints] * self.weights[:, :, None, None]).sum(axis=1)
        positions = np.column_stack((self.vertices, np.ones(len(self.vertices))))
        return np.einsum("nij,nj->ni", weighted, positions)[:, :3]

    def write_reference(self, output, frames, fps, head_look=False, nested=False):
        output.mkdir(parents=True)
        self.indices.astype("<i4").tofile(output / "indices.bin")
        rows = []
        calibration = self.pose(0)[self.head][:3, :3]
        target_base = self.pose(0)[self.head][:3, 3] + [0, 0, -3]
        nested_rest = np.eye(4)
        nested_rest[:3, 3] = [.18, .12, 0]
        for frame in range(frames):
            poses = self.pose(frame / fps)
            base_bones = {self.nodes[i]["name"]: pose.T.ravel().tolist()
                          for i, pose in poses.items() if i in self.skin["joints"]}
            target = target_base + [0.85*np.sin(frame*.17), .35*np.sin(frame*.23), 0]
            if head_look:
                original = poses[self.head].copy()
                z = original[:3, 3] - target
                z /= np.linalg.norm(z)
                x = np.cross([0, 1, 0], z)
                x /= np.linalg.norm(x)
                poses[self.head] = original.copy()
                poses[self.head][:3, :3] = np.column_stack((x, np.cross(z, x), z)) @ calibration
                change = poses[self.head] @ np.linalg.inv(original)

                def update_children(index):
                    for child in self.nodes[index].get("children", []):
                        poses[child] = change @ poses[child]
                        update_children(child)

                update_children(self.head)
            self.deform(poses).astype("<f4").tofile(output / f"vertices-{frame:03d}.bin")
            cut = np.eye(4)
            angle = .55 if frame >= frames//2 else 0
            cut[:3, :3] = rotation([0, np.sin(angle/2), 0, np.cos(angle/2)])
            mount = poses[self.head]
            nested_pose = np.eye(4)
            if nested:
                angle = .2*np.sin(frame*.31)
                nested_pose[:3, :3] = rotation([0, np.sin(angle/2), 0, np.cos(angle/2)])
                mount = mount @ nested_rest @ nested_pose
            camera = mount @ self.boom @ cut
            rows.append({"camera": camera.T.ravel().tolist(),
                         "target": target.tolist(), "base_bones": base_bones,
                         "nested": (poses[self.head] @ nested_rest @ nested_pose).T.ravel().tolist(),
                         "bones": {self.nodes[i]["name"]: pose.T.ravel().tolist()
                                   for i, pose in poses.items() if i in self.skin["joints"]}})
        result = {"asset_sha256": ASSET_SHA256, "vertices": len(self.vertices), "triangles": len(self.indices)//3,
                  "joints": len(self.skin["joints"]), "channels": len(self.channels),
                  "head": HEAD, "boom": self.boom.T.ravel().tolist(), "frames": rows,
                  "calibration": calibration.T.ravel().tolist(), "target_base": target_base.tolist()}
        (output / "reference.json").write_text(json.dumps(result) + "\n", encoding="utf-8")
        return result
