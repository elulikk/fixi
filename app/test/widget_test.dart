import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixi/core/models/models.dart';
import 'package:fixi/core/util/format.dart';
import 'package:fixi/core/widgets/common.dart';

void main() {
  group('dinero y comisión', () {
    test('formatea pesos argentinos', () {
      expect(money(45000), '\$ 45.000');
      expect(money(1250000), '\$ 1.250.000');
      expect(money(0), '\$ 0');
    });
    test('comisión 5% y neto del técnico', () {
      expect(commissionOf(10000), 500);
      expect(techNetOf(10000), 9500);
      expect(commissionOf(45000), 2250);
      expect(commissionOf(999), 50); // redondeo de 49.95
      expect(techNetOf(999), 949);
      expect(commissionOf(10000) + techNetOf(10000), 10000);
    });
    test('distancias y tiempos', () {
      expect(fmtDistance(0.85), '850 m');
      expect(fmtDistance(null), '—');
      expect(fmtMinutes(45), '45 min');
      expect(fmtMinutes(90), '1 h 30 min');
      expect(fmtMinutes(120), '2 h');
    });
  });

  group('modelos', () {
    test('Offer.fromJson con técnico, score e insignias', () {
      final o = Offer.fromJson({
        'id': 'o1',
        'requestId': 'r1',
        'techId': 't1',
        'price': 32000,
        'etaMinutes': 25,
        'durationMinutes': 90,
        'message': 'Voy ya',
        'status': 'pending',
        'distanceKm': 2.4,
        'score': 87.5,
        'badges': ['best', 'cheapest'],
        'tech': {'userId': 't1', 'name': 'Marcos', 'ratingAvg': 4.8, 'ratingCount': 31, 'jobsDone': 40, 'points': 640, 'level': 'oro', 'verified': true},
      });
      expect(o.price, 32000);
      expect(o.tech?.name, 'Marcos');
      expect(o.tech?.level, 'oro');
      expect(o.badges, ['best', 'cheapest']);
      expect(o.score, 87.5);
    });

    test('badge simple (string) se convierte en lista', () {
      final o = Offer.fromJson({'id': 'o', 'price': 1, 'badge': 'fastest'});
      expect(o.badges, ['fastest']);
    });

    test('Job.fromJson acepta job anidado con extras', () {
      final j = Job.fromJson({
        'job': {'id': 'j1', 'clientId': 'c1', 'techId': 't1', 'title': 'Heladera', 'price': 20000, 'commission': 1000, 'techNet': 19000, 'status': 'paid', 'paymentStatus': 'held', 'lat': -34.6, 'lng': -58.4},
        'tech': {'userId': 't1', 'name': 'Ana'},
        'client': {'id': 'c1', 'name': 'Luis'},
        'payment': {'id': 'p1', 'jobId': 'j1', 'amount': 20000, 'status': 'approved'},
      });
      expect(j.id, 'j1');
      expect(j.status, 'paid');
      expect(j.tech?.name, 'Ana');
      expect(j.client?.name, 'Luis');
      expect(j.payment?.amount, 20000);
      expect(j.isActive, isTrue);
    });

    test('RequestDetail con ofertas embebidas', () {
      final d = RequestDetail.fromJson({
        'request': {'id': 'r1', 'title': 'Aire', 'status': 'open', 'urgency': 'now', 'budgetMax': 50000},
        'offers': [
          {'id': 'a', 'price': 10, 'etaMinutes': 5},
          {'id': 'b', 'price': 20, 'etaMinutes': 3},
        ],
      });
      expect(d.request.budgetMax, 50000);
      expect(d.offers.length, 2);
    });

    test('niveles y progreso', () {
      expect(Levels.forPoints(0), 'bronce');
      expect(Levels.forPoints(200), 'plata');
      expect(Levels.forPoints(600), 'oro');
      expect(Levels.forPoints(1500), 'platino');
      expect(Levels.nextThreshold(150), 200);
      expect(Levels.nextThreshold(2000), isNull);
      expect(Levels.progress(100), closeTo(.5, .001));
    });

    test('ensureBadges calcula insignias si el server no las manda', () {
      final offers = ensureBadges([
        const Offer(id: 'a', price: 100, etaMinutes: 30, distanceKm: 3, score: 60, tech: TechCard(userId: 'x', name: 'X', ratingAvg: 4.0)),
        const Offer(id: 'b', price: 200, etaMinutes: 10, distanceKm: 1, score: 80, tech: TechCard(userId: 'y', name: 'Y', ratingAvg: 4.9)),
      ]);
      expect(offers[0].badges, contains('cheapest'));
      expect(offers[1].badges, containsAll(['best', 'fastest', 'closest', 'top_rated']));
    });
  });

  group('widgets', () {
    testWidgets('EmptyState muestra título y acción', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: EmptyState(icon: Icons.inbox, title: 'Nada por acá', message: 'Todavía no hay nada.', actionLabel: 'Crear', onAction: () => tapped = true)),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Nada por acá'), findsOneWidget);
      await tester.tap(find.text('Crear'));
      expect(tapped, isTrue);
    });

    testWidgets('BadgeChip usa etiquetas en español', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [BadgeChip('best'), BadgeChip('cheapest'), BadgeChip('top_rated')]))));
      expect(find.text('Mejor opción'), findsOneWidget);
      expect(find.text('Más barato'), findsOneWidget);
      expect(find.text('Mejor puntuado'), findsOneWidget);
    });
  });
}
