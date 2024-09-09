import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance;
  final _notesCollection = _firestore.collection('notes');
  final _textController = TextEditingController();

  Future<void> _addNote() async {
    await _notesCollection.add({
      'note': _textController.text,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _updateNote(String docId) async {
    await _notesCollection.doc(docId).update({
      'note': _textController.text,
    });
  }

  Future<void> _deleteNote(String docId) async {
    await _notesCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas'),
      ),
      body: StreamBuilder(
        stream: _notesCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final notes = snapshot.data.docs;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note['note']),
                trailing: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _textController.text = note['note'];
                        _updateNote(note.id);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _deleteNote(note.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Agregar nota'),
                content: TextField(
                  controller: _textController,
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      _addNote();
                      Navigator.pop(context);
                    },
                    child: Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}