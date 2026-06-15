import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.api = const GhibliApi()});

  final FilmApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ghibli Films',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: FilmsPage(api: api),
    );
  }
}

class GhibliFilm {
  const GhibliFilm({
    required this.id,
    required this.title,
    required this.year,
    required this.director,
    required this.producer,
    required this.duration,
    required this.score,
    required this.description,
  });

  final String id;
  final String title;
  final String year;
  final String director;
  final String producer;
  final String duration;
  final String score;
  final String description;

  factory GhibliFilm.fromJson(Map<String, dynamic> json) {
    return GhibliFilm(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Brak tytulu').toString(),
      year: (json['release_date'] ?? '').toString(),
      director: (json['director'] ?? '').toString(),
      producer: (json['producer'] ?? '').toString(),
      duration: '${json['running_time'] ?? ''} min',
      score: (json['rt_score'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

abstract class FilmApi {
  Future<List<GhibliFilm>> getFilms();

  Future<GhibliFilm> getFilm(String id);
}

class GhibliApi implements FilmApi {
  const GhibliApi();

  static const baseUrl = 'https://ghibliapi.vercel.app';

  @override
  Future<List<GhibliFilm>> getFilms() async {
    final response = await http.get(Uri.parse('$baseUrl/films'));

    if (response.statusCode != 200) {
      throw Exception('Nie udalo sie pobrac filmow');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => GhibliFilm.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GhibliFilm> getFilm(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/films/$id'));

    if (response.statusCode != 200) {
      throw Exception('Nie udalo sie pobrac szczegolow filmu');
    }

    return GhibliFilm.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class FilmsPage extends StatefulWidget {
  const FilmsPage({super.key, required this.api});

  final FilmApi api;

  @override
  State<FilmsPage> createState() => _FilmsPageState();
}

class _FilmsPageState extends State<FilmsPage> {
  late Future<List<GhibliFilm>> filmsFuture;

  @override
  void initState() {
    super.initState();
    filmsFuture = widget.api.getFilms();
  }

  void loadFilms() {
    setState(() {
      filmsFuture = widget.api.getFilms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filmy Studio Ghibli'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<GhibliFilm>>(
        future: filmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'Nie udalo sie pobrac listy filmow.',
              onRetry: loadFilms,
            );
          }

          final films = snapshot.data ?? [];

          return ListView.builder(
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
                        Text(
                          film.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FilmDetailsPage(api: widget.api, filmId: film.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FilmDetailsPage extends StatefulWidget {
  const FilmDetailsPage({super.key, required this.api, required this.filmId});

  final FilmApi api;
  final String filmId;

  @override
  State<FilmDetailsPage> createState() => _FilmDetailsPageState();
}

class _FilmDetailsPageState extends State<FilmDetailsPage> {
  late Future<GhibliFilm> filmFuture;

  @override
  void initState() {
    super.initState();
    filmFuture = widget.api.getFilm(widget.filmId);
  }

  void loadFilm() {
    setState(() {
      filmFuture = widget.api.getFilm(widget.filmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegoly filmu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<GhibliFilm>(
        future: filmFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'Nie udalo sie pobrac szczegolow filmu.',
              onRetry: loadFilm,
            );
          }

          final film = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                film.title,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Rok: ${film.year}'),
              Text('Rezyser: ${film.director}'),
              Text('Producent: ${film.producer}'),
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
          );
        },
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Sprobuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
