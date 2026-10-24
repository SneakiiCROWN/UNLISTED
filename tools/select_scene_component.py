"""Keep an approved GLB component in its original parent/texture transforms.

No engine/import is run. Original archives and model are never modified.
The output remains restricted/local whenever the source asset is restricted.
"""
from pathlib import Path
import argparse, hashlib, json, struct

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('parent')
    parser.add_argument('component')
    args = parser.parse_args()
    raw = args.source.read_bytes()
    magic, version, length = struct.unpack_from('<4sII', raw)
    assert magic == b'glTF' and version == 2 and length == len(raw)
    size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4E4F534A
    document = json.loads(raw[20:20 + size])
    parent = next(n for n in document['nodes'] if n.get('name') == args.parent)
    component = next(i for i in parent['children'] if document['nodes'][i].get('name') == args.component)
    parent['children'] = [component]
    encoded = json.dumps(document, separators=(',', ':')).encode('utf8')
    encoded += b' ' * (-len(encoded) % 4)
    tail = raw[20 + size:]
    output = struct.pack('<4sII', magic, version, 20 + len(encoded) + len(tail))
    output += struct.pack('<II', len(encoded), kind) + encoded + tail
    with args.destination.open('xb') as stream:
        stream.write(output)
    receipt = {'source': args.source.name, 'source_sha256': hashlib.sha256(raw).hexdigest(),
               'selected_node': args.component, 'retained_parent': args.parent,
               'output': args.destination.name, 'sha256': hashlib.sha256(output).hexdigest(),
               'method': 'Scene selection only; original geometry, images and transforms retained',
               'redistribution': 'Same licence restrictions as original Dusk asset; local only'}
    args.destination.with_suffix('.provenance.json').write_text(json.dumps(receipt, indent=2), encoding='utf8')
