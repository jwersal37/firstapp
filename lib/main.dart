import 'package:flutter/material.dart';
import 'dart:html' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Choice Picker',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Random Choice Picker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String? _randomChoice;
  final List<String> _results = [];
  final Map<String, int> _resultCounts = {};
  static const String _storageKey = 'user_choices';
  static const String _resultsKey = 'user_results';

  @override
  void initState() {
    super.initState();
    // Load saved choices from local storage
    final saved = html.window.localStorage[_storageKey];
    if (saved != null) {
      _controller.text = saved;
    }
    // Load saved results from local storage
    final savedResults = html.window.localStorage[_resultsKey];
    if (savedResults != null) {
      _results.addAll(savedResults.split('\n').where((line) => line.trim().isNotEmpty));
      for (final result in _results) {
        _resultCounts[result] = (_resultCounts[result] ?? 0) + 1;
      }
    }
  }

  void _saveChoices() {
    html.window.localStorage[_storageKey] = _controller.text;
    // Remove results that are no longer in the input
    final currentLines = _controller.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    setState(() {
      _results.removeWhere((result) => !currentLines.contains(result));
      _resultCounts.removeWhere((key, value) => !currentLines.contains(key));
      _saveResults();
    });
  }

  void _saveResults() {
    html.window.localStorage[_resultsKey] = _results.join('\n');
  }

  void _pickRandomChoice() {
    final lines = _controller.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      lines.shuffle();
      setState(() {
        _randomChoice = lines.first;
        _results.add(_randomChoice!);
        _resultCounts[_randomChoice!] = (_resultCounts[_randomChoice!] ?? 0) + 1;
        _saveResults();
      });
    }
  }

  void _shuffleEntries() {
    final lines = _controller.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.length > 1) {
      lines.shuffle();
      setState(() {
        _controller.text = lines.join('\n');
        _saveChoices();
      });
    }
  }

  void _clearResults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Results'),
        content: const Text('Are you sure you want to clear all results?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _results.clear();
        _resultCounts.clear();
        _randomChoice = null;
        _saveResults();
      });
    }
  }

  void _removeResult(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Entry'),
        content: Text('Are you sure you want to remove "$key" from the results?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _results.removeWhere((r) => r == key);
        _resultCounts.remove(key);
        if (_randomChoice == key) _randomChoice = null;
        _saveResults();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 400,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Enter one choice per line in the box below.\nClick "Pick Random Choice" to randomly select one of your entries. Each picked result will appear in the list below.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            if (_randomChoice != null) ...[
              Text(
                _randomChoice!,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Enter your choices:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _controller,
                maxLines: null, // Allow multiple lines
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Type here',
                ),
                textInputAction: TextInputAction.newline,
                onChanged: (_) => _saveChoices(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickRandomChoice,
                  child: const Text('Pick Random Choice'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _shuffleEntries,
                  child: const Text('Shuffle Entries'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearResults,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear Results'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Horizontal rule
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 400,
              height: 1,
              color: Colors.grey,
            ),
            // Winning Choice H1
            if (_resultCounts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    const Text(
                      'Winning Choice',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final maxCount = _resultCounts.values.isEmpty ? 0 : _resultCounts.values.reduce((a, b) => a > b ? a : b);
                        final winners = _resultCounts.entries
                            .where((e) => e.value == maxCount)
                            .map((e) => e.key)
                            .toList();
                        if (maxCount == 0) return const SizedBox.shrink();
                        return Text(
                          winners.join(', '),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: _results.isEmpty
                  ? const Text('No results yet.')
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView(
                        shrinkWrap: true,
                        children: _resultCounts.entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (entry.value > 1)
                                        Row(
                                          children: [
                                            ...List.generate(
                                              entry.value,
                                              (i) => const Icon(Icons.star, color: Colors.amber, size: 18),
                                            ),
                                            const SizedBox(width: 4),
                                            Text('(${entry.value})'),
                                          ],
                                        )
                                      else
                                        Text('(${entry.value})'),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Remove',
                                        onPressed: () => _removeResult(entry.key),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
