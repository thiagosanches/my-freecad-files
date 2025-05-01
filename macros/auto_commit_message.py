# AutoCommitMessage.py
# FreeCAD macro to generate AI commit messages on save using Git diffs

import FreeCAD
from PySide2.QtCore import QObject
from PySide2.QtWidgets import QMessageBox
import zipfile
import tempfile
import subprocess
import os
import sys

# Configure your OpenAI API key here
# openai.api_key = "YOUR_API_KEY_HERE"


class GitCommitGenerator(QObject):
    def __init__(self):
        super().__init__()

    def main(self):
        FreeCAD.Console.PrintMessage("AutoCommit Message macro initialized\n")

        doc = FreeCAD.ActiveDocument
        if not doc or not doc.FileName.endswith('.FCStd'):
            QMessageBox.warning(
                None, "Error", "Open a valid FreeCAD document first!")
            return

        file_path = doc.FileName
        print(file_path)

        subprocess.Popen([
            "bash", "-c",
            f"/home/thiago/r/github/my-freecad-files/macros/commit.sh '{file_path}'"
        ])


# Initialize the handler when macro is loaded
print("FreeCAD version:", FreeCAD.Version())
generator = GitCommitGenerator()
generator.main()
