import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Idea {
  final String title;
  final String description;
  final List<String> tags;
  final int id;
  int likes;

  Idea({required this.title, required this.description, required this.tags, required this.id, required this.likes});

  Future<void> like() async {
    await http.post(Uri.parse('https://what-to-code.com/api/ideas/$id/like'));
  }

  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(title: json['title'], description: json['description'], tags: (json['tags'] as List<dynamic>).map((e) => e.toString()).toList(), id: json['id'], likes: json['likes']);
  }

  static Future<Idea> getRandomIdea() async {
    final response = await http.get(Uri.parse('https://what-to-code.com/api/ideas/random'));
    if (response.statusCode == 200) {
      return Idea.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Non-200 status code');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        appBarTheme: const AppBarTheme(
          color: Color(0xFFFFFFFF)
        )
      ),
      home: const MyHomePage(title: 'What to Code?'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Idea> futureIdea;
  bool fetchingIdea = false;
  bool likedIdea = false;
  bool likingIdea = false;

  _likeIdea() {
    if (likingIdea) return;
    likingIdea = true;
    futureIdea.then((idea) {
      idea.like().then((_) {
        setState(() {
          idea.likes++;
          likedIdea = true;
        });
      });
    });
  }

  _randomIdea() {
    if(fetchingIdea) return;
    fetchingIdea = true;
    setState(() {
      futureIdea = Idea.getRandomIdea();
      futureIdea.then((value) {
        setState(() {
          fetchingIdea = false;
          likingIdea = false;
          likedIdea = false;
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _randomIdea();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(5.0),
          child: const Image(image: AssetImage('assets/idea.png'))
        ),
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<Idea>(
              future: futureIdea,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        border: Border.all(
                          width: 1,
                          color: Colors.grey.withOpacity(0.5),
                        )
                      ),
                      child: ClipPath(
                        clipper: ShapeBorderClipper(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(children: [
                                Text(
                                  snapshot.data!.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineLarge!.copyWith(color: theme.colorScheme.onPrimary),
                                ),
                                Text(
                                  snapshot.data!.description,
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: theme.colorScheme.onPrimary.withAlpha(215),
                                    fontSize: 22.0,
                                  ),
                                ),
                              ])
                            ),
                            Container(
                              color: theme.colorScheme.primary,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: _likeIdea,
                                    label: Text(
                                      '${snapshot.data!.likes}',
                                      style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onPrimary),
                                    ),
                                    icon: likedIdea
                                      ? const Icon( Icons.favorite, color: Colors.red )
                                      : const Icon( Icons.favorite_outline, color: Colors.black, ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _randomIdea,
        tooltip: 'Get new idea',
        child: const Icon(Icons.autorenew),
      ),
    );
  }
}
