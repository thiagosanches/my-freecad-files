# auto_commit_message.py
# FreeCAD macro to generate AI commit messages on save using Git diffs.
import os
import FreeCAD
import FreeCADGui as Gui
try:
    from PySide6.QtCore import QObject
    from PySide6.QtWidgets import QMessageBox
except ImportError:
    from PySide2.QtCore import QObject
    from PySide2.QtWidgets import QMessageBox
import subprocess


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
        FreeCAD.Console.PrintMessage(f"Committing: {file_path}\n")

        # Just to put the thumbnails right in the center, so they look better when viewing them.
        Gui.SendMsgToActiveView("ViewFit")
        doc.save()

        commit_script = os.path.join(os.path.dirname(__file__), "commit.sh")
        result = subprocess.run(
            [commit_script, file_path],
            capture_output=True,
            text=True
        )

        if result.stdout:
            FreeCAD.Console.PrintMessage(result.stdout + "\n")
        if result.stderr:
            FreeCAD.Console.PrintError(result.stderr + "\n")

        if result.returncode == 0:
            QMessageBox.information(
                None, "OK", "We are good!")
        else:
            error_detail = result.stderr or result.stdout or "Unknown error"
            QMessageBox.critical(
                None, "Error", f"Script failed:\n\n{error_detail}")

# Initialize the handler when macro is loaded
print("FreeCAD version:", FreeCAD.Version())
generator = GitCommitGenerator()
generator.main()
