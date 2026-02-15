import 'package:hive/hive.dart';

class NoteModel extends HiveObject {
  String title;
  String content;
  DateTime createdAt;
  bool isPinned; // <--- NEW FIELD

  NoteModel({
    required this.title,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
  });
}

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 5; // Keep ID 5

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      title: fields[0] as String? ?? "Untitled",
      content: fields[1] as String? ?? "",
      createdAt: fields[2] as DateTime? ?? DateTime.now(),
      isPinned: fields[3] as bool? ?? false, // <--- Read new field
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(4) // <--- Changed from 3 to 4 fields
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.isPinned); // <--- Write new field
  }
}
extension NoteCopy on NoteModel {
  NoteModel copyWith({
    String? title,
    String? content,
    DateTime? createdAt,
    bool? isPinned,
  }) {
    return NoteModel(
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
