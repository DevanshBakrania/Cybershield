// dummy_notes_storage.dart
import '../models/note_model.dart';
import '../storage/hive_boxes.dart';

class DummyNotesStorage {
  final String username;
  DummyNotesStorage(this.username);

  /// Get all dummy notes for this user
  List<NoteModel> get notes {
    return HiveBoxes.dummy.values
        .where((n) => n is NoteModel)
        .where((n) => n.title.startsWith('$username::'))
        .map((n) => _stripUserPrefix(n))
        .toList();
  }

  /// Save all notes for this user (replace existing)
  Future<void> save(List<NoteModel> notes) async {
    // 1️⃣ Remove old notes for this user
    final keysToDelete = HiveBoxes.dummy.keys.where((k) {
      return k.toString().startsWith('$username::');
    }).toList();

    for (final k in keysToDelete) {
      await HiveBoxes.dummy.delete(k);
    }

    // 2️⃣ Save new notes
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final key = '$username::$i';

      await HiveBoxes.dummy.put(
        key,
        note.copyWith(
          title: '$username::${note.title}',
        ),
      );
    }
  }

  /// Remove username prefix before returning to UI
  NoteModel _stripUserPrefix(NoteModel n) {
    return NoteModel(
      title: n.title.replaceFirst('$username::', ''),
      content: n.content,
      createdAt: n.createdAt,
      isPinned: n.isPinned,
    );
  }
}
