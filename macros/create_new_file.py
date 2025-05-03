import FreeCAD
import random
import hashlib
from datetime import datetime

def generate_hash_name():
    seed = f"{random.getrandbits(128)}{datetime.now().timestamp()}"
    hashed = hashlib.sha256(seed.encode()).hexdigest().upper()
    safe_chars = {'0','1','2','3','5','7','8','9','A','Y','X','W'}
    filtered = [c for c in hashed if c in safe_chars]
    hash_part = ''.join(filtered[:8])
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return f"{hash_part}_{timestamp}"

filename = generate_hash_name()

# Create a new document
doc = FreeCAD.newDocument()

# Save the document (optional)
doc.saveAs(f"{filename}.FCStd")
print("New FreeCAD document created successfully!")
