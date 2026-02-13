import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../storage/hive_boxes.dart';
import '../../models/note_model.dart';
import '../../core/routes.dart';

class DummyNotesScreen extends StatefulWidget {
  const DummyNotesScreen({super.key});

  @override
  State<DummyNotesScreen> createState() => _DummyNotesScreenState();
}

class _DummyNotesScreenState extends State<DummyNotesScreen> {

  // Combined Add/Edit Function
  void _showNoteSheet({NoteModel? note}) {
    final isEditing = note != null;
    final titleCtrl = TextEditingController(text: isEditing ? note.title : "");
    final contentCtrl = TextEditingController(text: isEditing ? note.content : "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? "Edit Note" : "New Note", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: const Color(0xFFF0F0F2),
              ),
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              decoration: InputDecoration(
                hintText: "Type something...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    try {
                      final box = Hive.box<NoteModel>('dummy_notes');

                      if (isEditing) {
                        // EDIT EXISTING
                        note.title = titleCtrl.text;
                        note.content = contentCtrl.text;
                        note.save();
                      } else {
                        // CREATE NEW
                        final newNote = NoteModel(
                          title: titleCtrl.text,
                          content: contentCtrl.text,
                          createdAt: DateTime.now(),
                          isPinned: false,
                        );
                        box.add(newNote);
                      }
                      Navigator.pop(ctx);
                    } catch (e) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: Text(isEditing ? "Update Note" : "Save Note", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _togglePin(NoteModel note) {
    note.isPinned = !note.isPinned;
    note.save();
  }

  void _deleteNote(NoteModel note) {
    note.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
          primaryColor: Colors.black,
          scaffoldBackgroundColor: const Color(0xFFF2F2F7), // Standard iOS Background
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.black)
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
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.pin),
            )
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<NoteModel>('dummy_notes').listenable(),
          builder: (context, Box<NoteModel> box, _) {
            if (box.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_document, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text("No Notes", style: TextStyle(color: Colors.grey.shade400, fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }

            final notes = box.values.toList().cast<NoteModel>();

            // SORT: Pinned first, then Newest
            notes.sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return b.createdAt.compareTo(a.createdAt);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (ctx, i) {
                final note = notes[i];
                return GestureDetector(
                  onTap: () => _showNoteSheet(note: note), // Edit on Tap
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      border: note.isPinned ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5) : null, // Subtle border for pinned
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Pin Icon
                              GestureDetector(
                                onTap: () => _togglePin(note),
                                child: Icon(
                                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  size: 20,
                                  color: note.isPinned ? Colors.orange : Colors.grey.shade300,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, height: 1.4, fontSize: 15)
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}",
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: () => _deleteNote(note),
                                child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade300),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNoteSheet(), // Create New
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("New", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}