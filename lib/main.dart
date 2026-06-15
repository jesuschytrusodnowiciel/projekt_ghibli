import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghibli Films',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const FilmsPage(),
    );
  }
}

class GhibliFilm {
  const GhibliFilm({
    required this.title,
    required this.year,
    required this.director,
    required this.duration,
    required this.score,
    required this.description,
  });

  final String title;
  final String year;
  final String director;
  final String duration;
  final String score;
  final String description;
}

const films = [
  GhibliFilm(
    title: 'Castle in the Sky',
    year: '1986',
    director: 'Hayao Miyazaki',
    duration: '124 min',
    score: '95',
    description:
        'awdaw',
  ),
  GhibliFilm(
    title: 'My Neighbor Totoro',
    year: '1988',
    director: 'Hayao Miyazaki',
    duration: '86 min',
    score: '93',
    description:
        'awd',
  )
];

class FilmsPage extends StatelessWidget {
  const FilmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filmy Studio Ghibli'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: films.length,
        itemBuilder: (context, index) {
          final film = films[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                film.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${film.year} - ${film.director}'),
                    Text('${film.duration} - Ocena: ${film.score}/100'),
                    const SizedBox(height: 8),
                    Text(film.description),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilmDetailsPage(film: film),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class FilmDetailsPage extends StatelessWidget {
  const FilmDetailsPage({super.key, required this.film});

  final GhibliFilm film;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(film.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            film.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Rok: ${film.year}'),
          Text('Rezyser: ${film.director}'),
          Text('Czas trwania: ${film.duration}'),
          Text('Ocena: ${film.score}/100'),
          const SizedBox(height: 20),
          const Text(
            'Opis',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(film.description),
        ],
      ),
    );
  }
}
