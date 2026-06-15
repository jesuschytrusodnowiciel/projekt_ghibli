import 'package:flutter_test/flutter_test.dart';
import 'package:projekt_gh/main.dart';

class FakeFilmApi implements FilmApi {
  final film = const GhibliFilm(
    id: '1',
    title: 'Castle in the Sky',
    year: '1986',
    director: 'Hayao Miyazaki',
    producer: 'Isao Takahata',
    duration: '124 min',
    score: '95',
    description: 'Opis testowy',
  );

  @override
  Future<List<GhibliFilm>> getFilms() async {
    return [film];
  }

  @override
  Future<GhibliFilm> getFilm(String id) async {
    return film;
  }
}

void main() {
  testWidgets('shows films from api', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: FakeFilmApi()));
    await tester.pumpAndSettle();

    expect(find.text('Filmy Studio Ghibli'), findsOneWidget);
    expect(find.text('Castle in the Sky'), findsOneWidget);
    expect(find.text('1986 - Hayao Miyazaki'), findsOneWidget);
  });

  testWidgets('opens film details after tap', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: FakeFilmApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Castle in the Sky'));
    await tester.pumpAndSettle();

    expect(find.text('Rezyser: Hayao Miyazaki'), findsOneWidget);
    expect(find.text('Producent: Isao Takahata'), findsOneWidget);
    expect(find.text('Czas trwania: 124 min'), findsOneWidget);
  });
}
