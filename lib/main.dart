import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}class FallThroughError implements Exception {
  final String message;

  FallThroughError(this.message);

  @override
  String toString() => message;
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD Firebase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CRUDPage(),
    );
  }
}

class CRUDPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD Firebase'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showForm(context), // Pasa el contexto correctamente
          ),
        ],
      ),
      body: buildTaskList(context), // Pasa el contexto aquí
    );
  }

  Widget buildTaskList(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: readTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        List<Task> tasks = snapshot.data!;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(task.title),
              subtitle: Text(task.description),
              onTap: () => _showForm(context, task: task), // Lógica para editar
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => deleteTask(task.id),
              ),
            );
          },
        );
      },
    );
  }

  void _showForm(BuildContext context, {Task? task}) {
    final _formKey = GlobalKey<FormState>();
    String _title = '';
    String _description = '';

    if (task != null) {
      _title = task.title;
      _description = task.description;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'Agregar Tarea' : 'Editar Tarea'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Título'),
                onSaved: (value) => _title = value!,
                validator: (value) => value!.isEmpty ? 'Ingrese un título' : null,
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: 'Descripción'),
                onSaved: (value) => _description = value!,
                validator: (value) => value!.isEmpty ? 'Ingrese una descripción' : null,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                if (task == null) {
                  createTask(_title, _description);
                } else {
                  updateTask(task.id, _title, _description);
                }
                Navigator.of(context).pop();
              }
            },
            child: Text(task == null ? 'Agregar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }
}

class Task {
  String id;
  String title;
  String description;

  Task({required this.id, required this.title, required this.description});

  // Para convertir un documento Firestore a un objeto Task
  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
    );
  }

  // Para convertir un objeto Task a un mapa (JSON) para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
    };
  }
}

Future<void> createTask(String title, String description) async {
  CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');
  await tasks.add({
    'title': title,
    'description': description,
  });
}

Stream<List<Task>> readTasks() {
  return FirebaseFirestore.instance
      .collection('tasks')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Task.fromFirestore(doc.data(), doc.id)).toList());
}

Future<void> updateTask(String id, String newTitle, String newDescription) async {
  DocumentReference task = FirebaseFirestore.instance.collection('tasks').doc(id);
  await task.update({
    'title': newTitle,
    'description': newDescription,
  });
}

Future<void> deleteTask(String id) async {
  DocumentReference task = FirebaseFirestore.instance.collection('tasks').doc(id);
  await task.delete();
}