int _int(dynamic v, [int d = 0]) => v is num ? v.round() : int.tryParse('$v') ?? d;
double _dbl(dynamic v, [double d = 0]) => v is num ? v.toDouble() : double.tryParse('$v') ?? d;
double? _dblN(dynamic v) => v == null ? null : _dbl(v);
String _str(dynamic v, [String d = '']) => v == null ? d : '$v';
String? _strN(dynamic v) => v == null ? null : '$v';
bool _bool(dynamic v, [bool d = false]) => v is bool ? v : d;
DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> asList(dynamic v) => v is List ? v.map(asMap).toList() : <Map<String, dynamic>>[];

class AppUser {
  final String id, name, email;
  final String? phone, avatarUrl, address;
  final String role;
  final bool isTechnician;
  final double? lat, lng;
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.address,
    this.role = 'user',
    this.isTechnician = false,
    this.lat,
    this.lng,
  });
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: _str(j['id'] ?? j['userId']),
        name: _str(j['name'], 'Usuario'),
        email: _str(j['email']),
        phone: _strN(j['phone']),
        avatarUrl: _strN(j['avatarUrl']),
        address: _strN(j['address']),
        role: _str(j['role'], 'user'),
        isTechnician: _bool(j['isTechnician']),
        lat: _dblN(j['lat']),
        lng: _dblN(j['lng']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'address': address,
        'role': role,
        'isTechnician': isTechnician,
        'lat': lat,
        'lng': lng,
      };
  String get firstName => name.trim().split(' ').first;
}

class Levels {
  static const names = ['bronce', 'plata', 'oro', 'platino'];
  static const thresholds = [0, 200, 600, 1500];
  static String label(String l) => l.isEmpty ? 'Bronce' : l[0].toUpperCase() + l.substring(1);
  static int index(String l) {
    final i = names.indexOf(l);
    return i < 0 ? 0 : i;
  }

  static String forPoints(int p) {
    var r = 0;
    for (var i = 0; i < thresholds.length; i++) {
      if (p >= thresholds[i]) r = i;
    }
    return names[r];
  }

  /// Puntos del siguiente nivel (null si ya es platino).
  static int? nextThreshold(int points) {
    for (final t in thresholds) {
      if (points < t) return t;
    }
    return null;
  }

  static double progress(int points) {
    final next = nextThreshold(points);
    if (next == null) return 1;
    var prev = 0;
    for (final t in thresholds) {
      if (t <= points) prev = t;
    }
    return ((points - prev) / (next - prev)).clamp(0.0, 1.0);
  }
}

class TechProfile {
  final String userId, bio, level;
  final List<String> categoryIds;
  final double radiusKm, ratingAvg;
  final bool available, verified, paymentsConnected;
  final int ratingCount, jobsDone, points;
  const TechProfile({
    required this.userId,
    this.bio = '',
    this.categoryIds = const [],
    this.radiusKm = 10,
    this.available = true,
    this.verified = false,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.jobsDone = 0,
    this.points = 0,
    this.level = 'bronce',
    this.paymentsConnected = false,
  });
  factory TechProfile.fromJson(Map<String, dynamic> j) => TechProfile(
        userId: _str(j['userId'] ?? j['id']),
        bio: _str(j['bio']),
        categoryIds: (j['categoryIds'] as List? ?? []).map((e) => '$e').toList(),
        radiusKm: _dbl(j['radiusKm'], 10),
        available: _bool(j['available'], true),
        verified: _bool(j['verified']),
        ratingAvg: _dbl(j['ratingAvg']),
        ratingCount: _int(j['ratingCount']),
        jobsDone: _int(j['jobsDone']),
        points: _int(j['points']),
        level: _str(j['level'], 'bronce'),
        paymentsConnected: _bool(j['paymentsConnected']),
      );
  TechProfile copyWith({bool? available}) => TechProfile(
        userId: userId,
        bio: bio,
        categoryIds: categoryIds,
        radiusKm: radiusKm,
        available: available ?? this.available,
        verified: verified,
        ratingAvg: ratingAvg,
        ratingCount: ratingCount,
        jobsDone: jobsDone,
        points: points,
        level: level,
        paymentsConnected: paymentsConnected,
      );
}

class Category {
  final String id, slug, name, icon, group;
  const Category({required this.id, required this.slug, required this.name, required this.icon, required this.group});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: _str(j['id']),
        slug: _str(j['slug']),
        name: _str(j['name']),
        icon: _str(j['icon']),
        group: _str(j['group'], 'Otros'),
      );
}

class TechCard {
  final String userId, name, level;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount, jobsDone, points;
  final bool verified;
  final double? distanceKm;
  const TechCard({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.jobsDone = 0,
    this.points = 0,
    this.level = 'bronce',
    this.verified = false,
    this.distanceKm,
  });
  factory TechCard.fromJson(Map<String, dynamic> j) => TechCard(
        userId: _str(j['userId'] ?? j['id']),
        name: _str(j['name'], 'Técnico'),
        avatarUrl: _strN(j['avatarUrl']),
        ratingAvg: _dbl(j['ratingAvg']),
        ratingCount: _int(j['ratingCount']),
        jobsDone: _int(j['jobsDone']),
        points: _int(j['points']),
        level: _str(j['level'], 'bronce'),
        verified: _bool(j['verified']),
        distanceKm: _dblN(j['distanceKm']),
      );
}

List<String> _badges(Map<String, dynamic> j) {
  final b = j['badges'];
  if (b is List) return b.map((e) => '$e').toList();
  final one = j['badge'];
  if (one is String && one.isNotEmpty) return [one];
  return [];
}

class NeedRequest {
  final String id, clientId, categoryId, title, description, urgency, status;
  final List<String> photos;
  final double lat, lng;
  final String address;
  final int? budgetMax;
  final DateTime? scheduledAt, createdAt;
  final int offersCount;
  final double? distanceKm;
  final String? categoryName;
  final String? clientName;
  const NeedRequest({
    required this.id,
    this.clientId = '',
    this.categoryId = '',
    this.title = '',
    this.description = '',
    this.photos = const [],
    this.lat = 0,
    this.lng = 0,
    this.address = '',
    this.budgetMax,
    this.urgency = 'today',
    this.scheduledAt,
    this.status = 'open',
    this.offersCount = 0,
    this.createdAt,
    this.distanceKm,
    this.categoryName,
    this.clientName,
  });
  factory NeedRequest.fromJson(Map<String, dynamic> j) => NeedRequest(
        id: _str(j['id']),
        clientId: _str(j['clientId']),
        categoryId: _str(j['categoryId']),
        title: _str(j['title']),
        description: _str(j['description']),
        photos: (j['photos'] as List? ?? []).map((e) => '$e').toList(),
        lat: _dbl(j['lat']),
        lng: _dbl(j['lng']),
        address: _str(j['address']),
        budgetMax: j['budgetMax'] == null ? null : _int(j['budgetMax']),
        urgency: _str(j['urgency'], 'today'),
        scheduledAt: _date(j['scheduledAt']),
        status: _str(j['status'], 'open'),
        offersCount: _int(j['offersCount']),
        createdAt: _date(j['createdAt']),
        distanceKm: _dblN(j['distanceKm']),
        categoryName: _strN(asMap(j['category'])['name'] ?? j['categoryName']),
        clientName: _strN(asMap(j['client'])['name'] ?? j['clientName']),
      );
  bool get isOpen => status == 'open';
}

class Offer {
  final String id, requestId, techId, message, status;
  final int price, etaMinutes, durationMinutes;
  final DateTime? createdAt;
  final TechCard? tech;
  final double? distanceKm, score;
  final List<String> badges;
  final String? requestTitle;
  const Offer({
    required this.id,
    this.requestId = '',
    this.techId = '',
    this.price = 0,
    this.etaMinutes = 0,
    this.durationMinutes = 0,
    this.message = '',
    this.status = 'pending',
    this.createdAt,
    this.tech,
    this.distanceKm,
    this.score,
    this.badges = const [],
    this.requestTitle,
  });
  factory Offer.fromJson(Map<String, dynamic> j) => Offer(
        id: _str(j['id']),
        requestId: _str(j['requestId']),
        techId: _str(j['techId']),
        price: _int(j['price']),
        etaMinutes: _int(j['etaMinutes']),
        durationMinutes: _int(j['durationMinutes']),
        message: _str(j['message']),
        status: _str(j['status'], 'pending'),
        createdAt: _date(j['createdAt']),
        tech: j['tech'] is Map ? TechCard.fromJson(asMap(j['tech'])) : null,
        distanceKm: _dblN(j['distanceKm']),
        score: _dblN(j['score']),
        badges: _badges(j),
        requestTitle: _strN(asMap(j['request'])['title'] ?? j['requestTitle']),
      );
  Offer withBadges(List<String> b) => Offer(
        id: id,
        requestId: requestId,
        techId: techId,
        price: price,
        etaMinutes: etaMinutes,
        durationMinutes: durationMinutes,
        message: message,
        status: status,
        createdAt: createdAt,
        tech: tech,
        distanceKm: distanceKm,
        score: score,
        badges: b,
        requestTitle: requestTitle,
      );
}

class Listing {
  final String id, techId, categoryId, title, description, priceType;
  final int price, durationMinutes;
  final bool active;
  final TechCard? tech;
  final double? distanceKm, score;
  final int? etaMinutes;
  final List<String> badges;
  final double? lat, lng;
  const Listing({
    required this.id,
    this.techId = '',
    this.categoryId = '',
    this.title = '',
    this.description = '',
    this.price = 0,
    this.priceType = 'fixed',
    this.durationMinutes = 60,
    this.active = true,
    this.tech,
    this.distanceKm,
    this.etaMinutes,
    this.score,
    this.badges = const [],
    this.lat,
    this.lng,
  });
  factory Listing.fromJson(Map<String, dynamic> j, {TechCard? tech}) => Listing(
        id: _str(j['id']),
        techId: _str(j['techId']),
        categoryId: _str(j['categoryId']),
        title: _str(j['title']),
        description: _str(j['description']),
        price: _int(j['price']),
        priceType: _str(j['priceType'], 'fixed'),
        durationMinutes: _int(j['durationMinutes'], 60),
        active: _bool(j['active'], true),
        tech: j['tech'] is Map ? TechCard.fromJson(asMap(j['tech'])) : tech,
        distanceKm: _dblN(j['distanceKm']),
        etaMinutes: j['etaMinutes'] == null ? null : _int(j['etaMinutes']),
        score: _dblN(j['score']),
        badges: _badges(j),
        lat: _dblN(j['lat'] ?? asMap(j['tech'])['lat']),
        lng: _dblN(j['lng'] ?? asMap(j['tech'])['lng']),
      );
  String get priceSuffix => priceType == 'hourly' ? ' / hora' : '';
  String get pricePrefix => priceType == 'from' ? 'Desde ' : '';
}

class PartyInfo {
  final String id, name;
  final String? avatarUrl, phone;
  const PartyInfo({required this.id, required this.name, this.avatarUrl, this.phone});
  factory PartyInfo.fromJson(Map<String, dynamic> j) => PartyInfo(
        id: _str(j['id'] ?? j['userId']),
        name: _str(j['name'], 'Cliente'),
        avatarUrl: _strN(j['avatarUrl']),
        phone: _strN(j['phone']),
      );
}

class Payment {
  final String id, jobId, provider, status;
  final int amount, commission;
  final String? checkoutUrl;
  const Payment({
    required this.id,
    this.jobId = '',
    this.provider = 'mock',
    this.amount = 0,
    this.commission = 0,
    this.status = 'pending',
    this.checkoutUrl,
  });
  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: _str(j['id']),
        jobId: _str(j['jobId']),
        provider: _str(j['provider'], 'mock'),
        amount: _int(j['amount']),
        commission: _int(j['commission']),
        status: _str(j['status'], 'pending'),
        checkoutUrl: _strN(j['checkoutUrl']),
      );
}

class Review {
  final String id, jobId, fromUserId, toUserId, comment;
  final int rating;
  final DateTime? createdAt;
  final String? fromName;
  const Review({
    required this.id,
    this.jobId = '',
    this.fromUserId = '',
    this.toUserId = '',
    this.rating = 5,
    this.comment = '',
    this.createdAt,
    this.fromName,
  });
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: _str(j['id']),
        jobId: _str(j['jobId']),
        fromUserId: _str(j['fromUserId']),
        toUserId: _str(j['toUserId']),
        rating: _int(j['rating'], 5),
        comment: _str(j['comment']),
        createdAt: _date(j['createdAt']),
        fromName: _strN(j['fromName'] ?? asMap(j['from'])['name'] ?? asMap(j['author'])['name']),
      );
}

class Job {
  final String id, clientId, techId, categoryId, title, address, status, paymentStatus;
  final String? requestId, offerId, listingId;
  final double lat, lng;
  final int price, commission, techNet, etaMinutes;
  final DateTime? createdAt, paidAt, startedAt, completedAt;
  final PartyInfo? client;
  final TechCard? tech;
  final Payment? payment;
  final Review? myReview;
  const Job({
    required this.id,
    this.requestId,
    this.offerId,
    this.listingId,
    this.clientId = '',
    this.techId = '',
    this.categoryId = '',
    this.title = '',
    this.address = '',
    this.lat = 0,
    this.lng = 0,
    this.price = 0,
    this.commission = 0,
    this.techNet = 0,
    this.etaMinutes = 0,
    this.status = 'pending_payment',
    this.paymentStatus = 'pending',
    this.createdAt,
    this.paidAt,
    this.startedAt,
    this.completedAt,
    this.client,
    this.tech,
    this.payment,
    this.myReview,
  });

  /// [root] puede ser el job solo o `{ job, client, tech, payment, myReview }`.
  factory Job.fromJson(Map<String, dynamic> root) {
    final j = root['job'] is Map ? asMap(root['job']) : root;
    dynamic pick(String k) => root[k] ?? j[k];
    return Job(
      id: _str(j['id']),
      requestId: _strN(j['requestId']),
      offerId: _strN(j['offerId']),
      listingId: _strN(j['listingId']),
      clientId: _str(j['clientId']),
      techId: _str(j['techId']),
      categoryId: _str(j['categoryId']),
      title: _str(j['title']),
      address: _str(j['address']),
      lat: _dbl(j['lat']),
      lng: _dbl(j['lng']),
      price: _int(j['price']),
      commission: _int(j['commission']),
      techNet: _int(j['techNet']),
      etaMinutes: _int(j['etaMinutes']),
      status: _str(j['status'], 'pending_payment'),
      paymentStatus: _str(j['paymentStatus'], 'pending'),
      createdAt: _date(j['createdAt']),
      paidAt: _date(j['paidAt']),
      startedAt: _date(j['startedAt']),
      completedAt: _date(j['completedAt']),
      client: pick('client') is Map ? PartyInfo.fromJson(asMap(pick('client'))) : null,
      tech: pick('tech') is Map ? TechCard.fromJson(asMap(pick('tech'))) : null,
      payment: pick('payment') is Map ? Payment.fromJson(asMap(pick('payment'))) : null,
      myReview: pick('myReview') is Map ? Review.fromJson(asMap(pick('myReview'))) : null,
    );
  }

  bool get isActive =>
      const ['pending_payment', 'paid', 'on_the_way', 'in_progress', 'done', 'disputed'].contains(status);
  bool get isPaid => status != 'pending_payment' && status != 'cancelled';
}

class ChatMessage {
  final String id, jobId, fromUserId, text;
  final DateTime? createdAt;
  const ChatMessage({required this.id, this.jobId = '', this.fromUserId = '', this.text = '', this.createdAt});
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: _str(j['id']),
        jobId: _str(j['jobId']),
        fromUserId: _str(j['fromUserId']),
        text: _str(j['text']),
        createdAt: _date(j['createdAt']),
      );
}

class AppNotification {
  final String id, type, title, body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime? createdAt;
  const AppNotification({
    required this.id,
    this.type = '',
    this.title = '',
    this.body = '',
    this.data = const {},
    this.read = false,
    this.createdAt,
  });
  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: _str(j['id']),
        type: _str(j['type']),
        title: _str(j['title']),
        body: _str(j['body']),
        data: asMap(j['data']),
        read: j['read'] == true || j['read'] == 1,
        createdAt: _date(j['createdAt']),
      );
}

class Earnings {
  final int totalNet, pendingNet, commissionPaid;
  final List<Job> jobs;
  const Earnings({this.totalNet = 0, this.pendingNet = 0, this.commissionPaid = 0, this.jobs = const []});
  factory Earnings.fromJson(Map<String, dynamic> j) => Earnings(
        totalNet: _int(j['totalNet']),
        pendingNet: _int(j['pendingNet']),
        commissionPaid: _int(j['commissionPaid']),
        jobs: asList(j['jobs']).map(Job.fromJson).toList(),
      );
}

class RequestDetail {
  final NeedRequest request;
  final List<Offer> offers;
  const RequestDetail(this.request, this.offers);
  factory RequestDetail.fromJson(Map<String, dynamic> j) {
    final r = j['request'] is Map ? asMap(j['request']) : j;
    final offers = asList(j['offers'] ?? r['offers']).map(Offer.fromJson).toList();
    return RequestDetail(NeedRequest.fromJson(r), offers);
  }
}

class TechPublic {
  final TechCard tech;
  final TechProfile? profile;
  final List<Listing> listings;
  final List<Review> reviews;
  const TechPublic(this.tech, this.profile, this.listings, this.reviews);
  factory TechPublic.fromJson(Map<String, dynamic> j) {
    final tech = TechCard.fromJson(asMap(j['tech']));
    return TechPublic(
      tech,
      j['profile'] is Map ? TechProfile.fromJson(asMap(j['profile'])) : null,
      asList(j['listings']).map((e) => Listing.fromJson(e, tech: tech)).toList(),
      asList(j['reviews']).map(Review.fromJson).toList(),
    );
  }
}

/// Si el servidor no mandó insignias, las calculamos en el cliente
/// (más barato, más cerca, más rápido, mejor puntuado, mejor opción).
List<Offer> ensureBadges(List<Offer> offers) {
  if (offers.length < 2 || offers.any((o) => o.badges.isNotEmpty)) return offers;
  final cheapest = offers.reduce((a, b) => a.price <= b.price ? a : b).id;
  final closest = offers.reduce((a, b) => (a.distanceKm ?? 999) <= (b.distanceKm ?? 999) ? a : b).id;
  final fastest = offers.reduce((a, b) => a.etaMinutes <= b.etaMinutes ? a : b).id;
  final top = offers.reduce((a, b) => (a.tech?.ratingAvg ?? 0) >= (b.tech?.ratingAvg ?? 0) ? a : b).id;
  final best = offers.reduce((a, b) => (a.score ?? 0) >= (b.score ?? 0) ? a : b).id;
  return offers.map((o) {
    final b = <String>[
      if (o.id == best) 'best',
      if (o.id == cheapest) 'cheapest',
      if (o.id == closest) 'closest',
      if (o.id == fastest) 'fastest',
      if (o.id == top) 'top_rated',
    ];
    return o.withBadges(b);
  }).toList();
}
