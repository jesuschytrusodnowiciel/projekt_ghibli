import 'package:flutter_test/flutter_test.dart';
import 'package:projekt_gh/main.dart';

class FakeFilmApi implements FilmApi {
  final firstFilm = const GhibliFilm(
    id: '1',
    title: 'Castle in the Sky',
    year: '1986',
    director: 'Hayao Miyazaki',
    producer: 'Isao Takahata',
    duration: '124 min',
    score: '95',
    description: 'Opis testowy',
  );

  final secondFilm = const GhibliFilm(
    id: '2',
    title: 'Spirited Away',
    year: '2001',
    director: 'Hayao Miyazaki',
    producer: 'Toshio Suzuki',
    duration: '125 min',
    score: '97',
    description: 'Opis testowy 2',
  );

  @override
  Future<List<GhibliFilm>> getFilms() async {
    return [firstFilm, secondFilm];
  }

  @override
  Future<GhibliFilm> getFilm(String id) async {
    if (id == '2') {
      return secondFilm;
    }

    return firstFilm;
  }

  @override
  Future<List<GhibliPerson>> getPeopleForFilm(String filmId) async {
    return const [
      GhibliPerson(
        name: 'Pazu',
        gender: 'Male',
        age: '13',
        filmUrls: ['https://ghibliapi.vercel.app/films/1'],
      ),
    ];
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
    expect(find.text('Postacie w filmie'), findsOneWidget);
    expect(find.text('Pazu'), findsOneWidget);
  });

  testWidgets('sorts films by year', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(api: FakeFilmApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sortowanie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rok wydania'));
    await tester.pumpAndSettle();

    final spiritedAwayTop = tester.getTopLeft(find.text('Spirited Away')).dy;
    final castleTop = tester.getTopLeft(find.text('Castle in the Sky')).dy;

    expect(spiritedAwayTop, lessThan(castleTop));
  });
}
