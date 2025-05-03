import FreeCAD
import FreeCADGui

# Create a new document
doc = FreeCAD.newDocument()

# Save the document (optional)
doc.saveAs("new_file.FCStd")

print("New FreeCAD document created successfully!")