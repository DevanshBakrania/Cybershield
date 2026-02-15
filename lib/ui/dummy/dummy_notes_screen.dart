import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../core/routes.dart';
import '../../storage/dummy_notes_storage.dart';

class DummyNotesScreen extends StatefulWidget {
  const DummyNotesScreen({super.key});

  @override
  State<DummyNotesScreen> createState() => _DummyNotesScreenState();
}

class _DummyNotesScreenState extends State<DummyNotesScreen> {
  late String username;
  late DummyNotesStorage storage;
  List<NoteModel> notes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    username = ModalRoute.of(context)!.settings.arguments as String;
    storage = DummyNotesStorage(username);
    _reloadNotes();
  }

  // ─────────────────────────
  // LOAD FROM STORAGE (SOURCE OF TRUTH)
  // ─────────────────────────
  void _reloadNotes() {
    notes = List.from(storage.notes);

    // Optional: keep pinned on top
    notes.sort((a, b) {
      if (a.isPinned == b.isPinned) return 0;
      return a.isPinned ? -1 : 1;
    });

    setState(() {});
  }

  // ─────────────────────────
  // ADD / EDIT NOTE
  // ─────────────────────────
  void _showNoteSheet({NoteModel? note}) {
    final isEditing = note != null;
    final titleCtrl = TextEditingController(text: isEditing ? note!.title : "");
    final contentCtrl =
        TextEditingController(text: isEditing ? note!.content : "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? "Edit Note" : "New Note",
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F0F2),
              ),
              textCapitalization: TextCapitalization.sentences,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: contentCtrl,
              decoration: InputDecoration(
                hintText: "Type something...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F0F2),
              ),
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;

                  if (isEditing) {
                    note!.title = titleCtrl.text;
                    note.content = contentCtrl.text;
                  } else {
                    notes.add(
                      NoteModel(
                        title: titleCtrl.text,
                        content: contentCtrl.text,
                        createdAt: DateTime.now(),
                        isPinned: false,
                      ),
                    );
                  }

                  await storage.save(notes);
                  _reloadNotes();
                  Navigator.pop(ctx);
                },
                child: Text(
                  isEditing ? "Update Note" : "Save Note",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────
  // PIN / DELETE
  // ─────────────────────────
  void _togglePin(NoteModel note) async {
    note.isPinned = !note.isPinned;
    await storage.save(notes);
    _reloadNotes();
  }

  void _deleteNote(NoteModel note) async {
    notes.remove(note);
    await storage.save(notes);
    _reloadNotes();
  }

  // ─────────────────────────
  // UI
  // ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(backgroundColor: Colors.black),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("Notes"),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.grey),
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.login,
              ),
            )
          ],
        ),

        body: notes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_document,
                        size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      "No Notes",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (ctx, i) {
                  final note = notes[i];
                  return GestureDetector(
                    onTap: () => _showNoteSheet(note: note),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                        border: note.isPinned
                            ? Border.all(
                                color: Colors.orange.withOpacity(0.5),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _togglePin(note),
                                  child: Icon(
                                    note.isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    size: 20,
                                    color: note.isPinned
                                        ? Colors.orange
                                        : Colors.grey.shade300,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.4,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}",
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 12),
                                ),
                                GestureDetector(
                                  onTap: () => _deleteNote(note),
                                  child: Icon(Icons.delete_outline,
                                      size: 18,
                                      color: Colors.grey.shade300),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNoteSheet(),
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "New",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
