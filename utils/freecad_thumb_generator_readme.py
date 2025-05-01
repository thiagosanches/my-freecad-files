# | Thumbnail   | File        | Description |
# |-------------|-------------|-------------|
# | ./image.png | bla.freecad | wood joint  |
# | ./image.png | bla.freecad | wood joint  |

from zipfile import ZipFile
import os

temp_folder = "temp/"
thumbnails_folder = "thumbnails/"
markdown_table = [
    "| Thumbnail   | File        | Description |\n",
    "|-------------|-------------|-------------|\n"
]

for filename in os.listdir("."):
    if filename.endswith(".FCStd"):
        freecad_filename = filename
        freecad_thumbnail = thumbnails_folder + freecad_filename + "_thumb.png"

        with ZipFile(freecad_filename, 'r') as z:
            z.extractall(path=temp_folder)

        if os.path.exists(temp_folder + "thumbnails/Thumbnail.png"):
            os.rename(temp_folder + "thumbnails/Thumbnail.png",
                      freecad_thumbnail)

            markdown_table.append(
                f"| ![image](./{freecad_thumbnail}) | [{freecad_filename}](./{freecad_filename}) | N/A |\n")

markdown_begin_marker = "<!-- BEGIN TABLE -->\n"
markdown_end_marker = "<!-- END TABLE -->\n"

with open("README.md", "r") as markdown:
    lines = markdown.readlines()
    start = lines.index(markdown_begin_marker)
    end = lines.index(markdown_end_marker, start + 1)

new_content = (
    lines[:start + 1] +
    markdown_table +
    lines[end:]
)

with open("README.md", "w") as new_markdown:
    new_markdown.writelines(new_content)
