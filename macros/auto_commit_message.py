# auto_commit_message.py
# FreeCAD macro to generate AI commit messages on save using Git diffs.
import os
import FreeCAD
import FreeCADGui as Gui
try:
    from PySide6.QtCore import QObject, QThread, Signal
    from PySide6.QtWidgets import QMessageBox
except ImportError:
    from PySide2.QtCore import QObject, QThread, Signal
    from PySide2.QtWidgets import QMessageBox
import subprocess


class CommitWorker(QThread):
    finished = Signal(int, str, str)  # return_code, stdout, stderr

    def __init__(self, script, file_path):
        super().__init__()
        self.script = script
        self.file_path = file_path

    def run(self):
        result = subprocess.run(
            [self.script, self.file_path],
            capture_output=True,
            text=True
        )
        self.finished.emit(result.returncode, result.stdout, result.stderr)


class GitCommitGenerator(QObject):
    def __init__(self):
        super().__init__()
        self.worker = None  # keep reference to prevent garbage collection

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
        self.worker = CommitWorker(commit_script, file_path)
        self.worker.finished.connect(self._on_finished)
        self.worker.start()

    def _on_finished(self, return_code, stdout, stderr):
        if stdout:
            FreeCAD.Console.PrintMessage(stdout + "\n")
        if stderr:
            FreeCAD.Console.PrintError(stderr + "\n")

        if return_code == 0:
            QMessageBox.information(None, "OK", "We are good!")
        else:
            error_detail = stderr or stdout or "Unknown error"
            QMessageBox.critical(
                None, "Error", f"Script failed:\n\n{error_detail}")

# Initialize the handler when macro is loaded
print("FreeCAD version:", FreeCAD.Version())
generator = GitCommitGenerator()
generator.main()
