import 'package:flutter/material.dart';
import '../widgets/custom_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _notes = [];
  List<Map<String, String>> _filteredNotes = [];
  int? _selectedNoteIndex;

  @override
  void initState() {
    super.initState();
    _loadNotesFromSharedPreferences();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterNotes);
    _searchController.dispose();
    super.dispose();
  }

  // Load notes from SharedPreferences on startup
  Future<void> _loadNotesFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? titles = prefs.getStringList('note_titles');
    List<String>? descriptions = prefs.getStringList('note_descriptions');

    if (titles != null && descriptions != null) {
      setState(() {
        _notes = List.generate(titles.length, (index) {
          return {
            'title': titles[index],
            'description': descriptions[index],
          };
        });
        _filteredNotes = List.from(_notes); // Initialize filtered list
      });
    }
  }

  // Filter notes based on search query
  void _filterNotes() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        return note['title']!.toLowerCase().contains(query) ||
            note['description']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  // Method to show dialog with text fields for adding or updating a note
  void _showNoteDialog({bool isUpdating = false}) {
    if (isUpdating && _selectedNoteIndex != null) {
      _titleController.text = _filteredNotes[_selectedNoteIndex!]['title']!;
      _descriptionController.text = _filteredNotes[_selectedNoteIndex!]['description']!;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isUpdating ? 'Update Note' : 'Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'Enter Title'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(hintText: 'Enter Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: isUpdating
                  ? _updateNoteInSharedPreferences
                  : _saveNoteToSharedPreferences,
              child: Text(
                isUpdating ? 'Update' : 'Save',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Save new note to SharedPreferences
  Future<void> _saveNoteToSharedPreferences() async {
    final String title = _titleController.text;
    final String description = _descriptionController.text;

    if (title.isEmpty || description.isEmpty) {
      return; // Don't save if either field is empty
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? titles = prefs.getStringList('note_titles') ?? [];
    List<String>? descriptions = prefs.getStringList('note_descriptions') ?? [];

    titles.add(title);
    descriptions.add(description);

    await prefs.setStringList('note_titles', titles);
    await prefs.setStringList('note_descriptions', descriptions);

    setState(() {
      _notes.add({
        'title': title,
        'description': description,
      });
      _filterNotes(); // Update filtered notes
    });

    // Clear text fields and close the dialog
    _titleController.clear();
    _descriptionController.clear();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note Saved!')),
    );
  }

  // Update existing note in SharedPreferences
  Future<void> _updateNoteInSharedPreferences() async {
    final String title = _titleController.text;
    final String description = _descriptionController.text;

    if (title.isEmpty || description.isEmpty || _selectedNoteIndex == null) {
      return; // Don't update if either field is empty
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? titles = prefs.getStringList('note_titles') ?? [];
    List<String>? descriptions = prefs.getStringList('note_descriptions') ?? [];

    titles[_selectedNoteIndex!] = title;
    descriptions[_selectedNoteIndex!] = description;

    await prefs.setStringList('note_titles', titles);
    await prefs.setStringList('note_descriptions', descriptions);

    setState(() {
      _notes[_selectedNoteIndex!] = {
        'title': title,
        'description': description,
      };
      _filterNotes(); // Update filtered notes
    });

    // Clear text fields and close the dialog
    _titleController.clear();
    _descriptionController.clear();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note Updated!')),
    );
  }

  // Delete note from SharedPreferences
  Future<void> _deleteNoteFromSharedPreferences(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? titles = prefs.getStringList('note_titles') ?? [];
    List<String>? descriptions = prefs.getStringList('note_descriptions') ?? [];

    titles.removeAt(index);
    descriptions.removeAt(index);

    await prefs.setStringList('note_titles', titles);
    await prefs.setStringList('note_descriptions', descriptions);

    setState(() {
      _notes.removeAt(index);
      _filterNotes(); // Update filtered notes
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note Deleted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Color(0xFFF9F9F9),
        title: Text(
          'Notes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Icon(Icons.more_vert, color: Colors.black),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _filterNotes(); // Trigger search when icon is pressed
                  },
                ),
              ),
            ),
            SizedBox(height: 30),
            _filteredNotes.isEmpty
                ? Center(child: Text('No Notes Available'))
                : Expanded(
              child: ListView.builder(
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: Text(
                        _filteredNotes[index]['title']!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _filteredNotes[index]['description']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        color: Colors.white,
                        onSelected: (String result) {
                          if (result == 'Update') {
                            setState(() {
                              _selectedNoteIndex = index;
                            });
                            _showNoteDialog(isUpdating: true);
                          } else if (result == 'Delete') {
                            _deleteNoteFromSharedPreferences(index);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: 'Update',
                            child: Text('Update'),
                          ),
                          PopupMenuItem(
                            value: 'Delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          _selectedNoteIndex = null; // Reset index for a new note
          _showNoteDialog();
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
