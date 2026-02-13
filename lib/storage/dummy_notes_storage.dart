import 'package:hive_flutter/hive_flutter.dart';
import '../models/note_model.dart';
import 'hive_boxes.dart';

class DummyNotesStorage {
  // Get reference to the specific box
  Box<NoteModel> get _box => HiveBoxes.dummy;

  Future<void> addNote(String title, String content) async {
    final note = NoteModel(
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );
    await _box.add(note);
  }

  List<NoteModel> getAllNotes() {
    // Return newest first
    final notes = _box.values.toList().cast<NoteModel>();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<void> deleteNote(dynamic key) async {
    await _box.delete(key);
  }
}