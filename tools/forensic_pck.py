"""Read-only unencrypted embedded PCK directory/content validation, Godot 4 V2-V4."""
from pathlib import Path
import hashlib,json,struct,sys
E=Path(sys.argv[1]);O=Path(sys.argv[2]);data=E.read_bytes()
assert data[-4:]==b'GDPC','Missing pack footer'
size=struct.unpack_from('<Q',data,len(data)-12)[0];start=len(data)-12-size
assert data[start:start+4]==b'GDPC','Missing pack header'
pos=start+4
def u32():
    global pos
    value=struct.unpack_from('<I',data,pos)[0];pos+=4;return value
def u64():
    global pos
    value=struct.unpack_from('<Q',data,pos)[0];pos+=8;return value
version=u32();engine=[u32(),u32(),u32()];flags=u32();base=u64()
assert version in [2,3,4] and not flags&1,'Unsupported/encrypted pack'
if version in [3,4] or flags&2:base+=start
if version in [3,4]:pos=start+u64()
else:pos+=64
count=u32();rows=[];errors=[]
for i in range(count):
    length=u32();path=data[pos:pos+length].rstrip(b'\0').decode();pos+=length
    offset=u64()+base;length=u64();expected=data[pos:pos+16].hex();pos+=16;entry_flags=u32()
    assert not entry_flags,'Nonordinary entry flags require explicit support'
    valid=offset>=start and offset+length<=len(data)-12
    actual=hashlib.md5(data[offset:offset+length]).hexdigest() if valid else None
    row={'path':path,'offset':offset,'size':length,'md5':expected,'bounds_valid':valid,'md5_matches':expected==actual}
    rows.append(row)
    if not valid or expected!=actual:errors.append(row)
report={'executable':str(E),'sha256':hashlib.sha256(data).hexdigest(),'pack_offset':start,'format_version':version,'engine_version':engine,'pack_flags':flags,'files':len(rows),'errors':errors,'entries':rows}
O.write_text(json.dumps(report,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in report.items() if k!='entries'},indent=2))
assert not errors
