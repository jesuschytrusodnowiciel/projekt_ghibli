import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('filmsBox');

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5A27), // Forest Green
          secondary: const Color(0xFFD4A373), // Sandy Brown
          surface: const Color(0xFFFEFDF5), // Creamy white
        ),
        scaffoldBackgroundColor: const Color(0xFFFEFDF5),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF2E5A27),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFF2E5A27).withOpacity(0.1)),
          ),
          color: Colors.white,
        ),
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
      title: (json['title'] ?? 'Brak tytułu').toString(),
      year: (json['release_date'] ?? '').toString(),
      director: (json['director'] ?? '').toString(),
      producer: (json['producer'] ?? '').toString(),
      duration: '${json['running_time'] ?? ''} min',
      score: (json['rt_score'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  factory GhibliFilm.fromMap(Map<dynamic, dynamic> map) {
    return GhibliFilm(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? 'Brak tytułu').toString(),
      year: (map['year'] ?? '').toString(),
      director: (map['director'] ?? '').toString(),
      producer: (map['producer'] ?? '').toString(),
      duration: (map['duration'] ?? '').toString(),
      score: (map['score'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
    );
  }

  Map<String, String> toMap() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'director': director,
      'producer': producer,
      'duration': duration,
      'score': score,
      'description': description,
    };
  }
}

class GhibliPerson {
  const GhibliPerson({
    required this.name,
    required this.gender,
    required this.age,
    required this.filmUrls,
  });

  final String name;
  final String gender;
  final String age;
  final List<String> filmUrls;

  factory GhibliPerson.fromJson(Map<String, dynamic> json) {
    final films = (json['films'] as List<dynamic>? ?? [])
        .map((filmUrl) => filmUrl.toString())
        .toList();

    return GhibliPerson(
      name: (json['name'] ?? 'Brak imienia').toString(),
      gender: (json['gender'] ?? '').toString(),
      age: (json['age'] ?? '').toString(),
      filmUrls: films,
    );
  }

  factory GhibliPerson.fromMap(Map<dynamic, dynamic> map) {
    final films = (map['filmUrls'] as List<dynamic>? ?? [])
        .map((filmUrl) => filmUrl.toString())
        .toList();

    return GhibliPerson(
      name: (map['name'] ?? 'Brak imienia').toString(),
      gender: (map['gender'] ?? '').toString(),
      age: (map['age'] ?? '').toString(),
      filmUrls: films,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'filmUrls': filmUrls,
    };
  }
}

enum SortOption {
  rating,
  duration,
  year,
}

abstract class FilmApi {
  Future<List<GhibliFilm>> getFilms();

  Future<GhibliFilm> getFilm(String id);

  Future<List<GhibliPerson>> getPeopleForFilm(String filmId);
}

class GhibliApi implements FilmApi {
  const GhibliApi();

  static const baseUrl = 'https://ghibliapi.vercel.app';
  static const cacheKey = 'films';

  Box get cacheBox => Hive.box('filmsBox');

  @override
  Future<List<GhibliFilm>> getFilms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/films'));

      if (response.statusCode != 200) {
        throw Exception('Nie udało się pobrać filmów');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final films = data
          .map((item) => GhibliFilm.fromJson(item as Map<String, dynamic>))
          .toList();

      await cacheBox.put(cacheKey, films.map((film) => film.toMap()).toList());

      return films;
    } catch (_) {
      final cachedFilms = getCachedFilms();

      if (cachedFilms.isNotEmpty) {
        return cachedFilms;
      }

      rethrow;
    }
  }

  @override
  Future<GhibliFilm> getFilm(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/films/$id'));

      if (response.statusCode != 200) {
        throw Exception('Nie udało się pobrać szczegółów filmu');
      }

      final film = GhibliFilm.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      await saveFilmInCache(film);

      return film;
    } catch (_) {
      final cachedFilm = getCachedFilm(id);

      if (cachedFilm != null) {
        return cachedFilm;
      }

      rethrow;
    }
  }

  List<GhibliFilm> getCachedFilms() {
    final data = cacheBox.get(cacheKey, defaultValue: []) as List;

    return data
        .map((item) => GhibliFilm.fromMap(item as Map<dynamic, dynamic>))
        .toList();
  }

  GhibliFilm? getCachedFilm(String id) {
    for (final film in getCachedFilms()) {
      if (film.id == id) {
        return film;
      }
    }

    return null;
  }

  Future<void> saveFilmInCache(GhibliFilm film) async {
    final films = getCachedFilms();
    final index = films.indexWhere((cachedFilm) => cachedFilm.id == film.id);

    if (index == -1) {
      films.add(film);
    } else {
      films[index] = film;
    }

    await cacheBox.put(cacheKey, films.map((film) => film.toMap()).toList());
  }

  @override
  Future<List<GhibliPerson>> getPeopleForFilm(String filmId) async {
    final peopleCacheKey = 'people_$filmId';

    try {
      final response = await http.get(Uri.parse('$baseUrl/people'));

      if (response.statusCode != 200) {
        throw Exception('Nie udało się pobrać postaci');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final people = data
          .map((item) => GhibliPerson.fromJson(item as Map<String, dynamic>))
          .where((person) => person.filmUrls.any((url) => url.contains(filmId)))
          .toList();

      await cacheBox.put(
        peopleCacheKey,
        people.map((person) => person.toMap()).toList(),
      );

      return people;
    } catch (_) {
      final cachedPeople = getCachedPeople(peopleCacheKey);

      if (cachedPeople.isNotEmpty) {
        return cachedPeople;
      }

      rethrow;
    }
  }

  List<GhibliPerson> getCachedPeople(String peopleCacheKey) {
    final data = cacheBox.get(peopleCacheKey, defaultValue: []) as List;

    return data
        .map((item) => GhibliPerson.fromMap(item as Map<dynamic, dynamic>))
        .toList();
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
  SortOption sortOption = SortOption.rating;

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
        title: const Text('Studio Ghibli'),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Sortowanie',
            onSelected: (option) {
              setState(() {
                sortOption = option;
              });
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: SortOption.rating,
                  child: Row(
                    children: [
                      Icon(Icons.star_outline_rounded, color: Colors.black ,size: 20),
                      SizedBox(width: 8),
                      Text('Ocena'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortOption.duration,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.black ,size: 20),
                      SizedBox(width: 8),
                      Text('Długość'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortOption.year,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.black ,size: 20),
                      SizedBox(width: 8),
                      Text('Rok wydania'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: FutureBuilder<List<GhibliFilm>>(
        future: filmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'Nie udało się pobrać listy filmów.',
              onRetry: loadFilms,
            );
          }

          final films = sortFilms(snapshot.data ?? []);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FilmDetailsPage(api: widget.api, filmId: film.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E5A27).withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF2E5A27).withOpacity(0.05),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                film.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2E5A27),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMiniTag(Icons.calendar_month_outlined, film.year, const Color(
                                0xFF575454)),
                            const SizedBox(width: 8),
                            _buildMiniTag(Icons.star_rounded, '${film.score}/100', Colors.orange[800]!),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.movie_creation_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                film.director,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              film.duration,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<GhibliFilm> sortFilms(List<GhibliFilm> films) {
    final sortedFilms = [...films];

    if (sortOption == SortOption.rating) {
      sortedFilms.sort(
        (a, b) => numberFromText(b.score).compareTo(numberFromText(a.score)),
      );
    } else if (sortOption == SortOption.duration) {
      sortedFilms.sort(
        (a, b) =>
            numberFromText(b.duration).compareTo(numberFromText(a.duration)),
      );
    } else {
      sortedFilms.sort(
        (a, b) => numberFromText(b.year).compareTo(numberFromText(a.year)),
      );
    }

    return sortedFilms;
  }

  int numberFromText(String text) {
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
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
  late Future<List<GhibliPerson>> peopleFuture;

  @override
  void initState() {
    super.initState();
    filmFuture = widget.api.getFilm(widget.filmId);
    peopleFuture = widget.api.getPeopleForFilm(widget.filmId);
  }

  void loadFilm() {
    setState(() {
      filmFuture = widget.api.getFilm(widget.filmId);
      peopleFuture = widget.api.getPeopleForFilm(widget.filmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły'),
      ),
      body: FutureBuilder<GhibliFilm>(
        future: filmFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              message: 'Nie udało się pobrać szczegółów filmu.',
              onRetry: loadFilm,
            );
          }

          final film = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  film.title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E5A27),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildFeatureChip(Icons.calendar_today_rounded, film.year),
                    const SizedBox(width: 16),
                    _buildFeatureChip(Icons.timer_outlined, film.duration),
                    const Spacer(),
                    _buildScoreBadge(film.score),
                  ],
                ),
                const SizedBox(height: 40),
                _buildModernInfoCard('Reżyser', film.director, Icons.movie_creation_outlined),
                _buildModernInfoCard('Producent', film.producer, Icons.business_center_outlined),
                const SizedBox(height: 32),
                const Text(
                  'Opis fabuły',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E5A27),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  film.description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),
                const Row(
                  children: [
                    Icon(Icons.people_outline_rounded, color: Color(0xFF2E5A27)),
                    SizedBox(width: 10),
                    Text(
                      'Postacie w filmie',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilmPeopleSection(peopleFuture: peopleFuture),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernInfoCard(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E5A27).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4A373).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFD4A373), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(String score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2E5A27),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E5A27).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(
            score,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class FilmPeopleSection extends StatelessWidget {
  const FilmPeopleSection({super.key, required this.peopleFuture});

  final Future<List<GhibliPerson>> peopleFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GhibliPerson>>(
      future: peopleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Text('Nie udało się pobrać postaci.');
        }

        final people = snapshot.data ?? [];

        if (people.isEmpty) {
          return const Text('Brak danych o postaciach.');
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: people
              .map(
                (person) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A373).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4A373).withOpacity(0.2)),
                  ),
                  child: Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
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
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFD4A373)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Spróbuj ponownie'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E5A27),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
