import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ───────────────── الاتصال بـ Supabase ─────────────────

const supabaseUrl = 'https://qgexszdqqvgtxzqnxyek.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFnZXhzemRxcXZndHh6cW54eWVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1MDY3MzIsImV4cCI6MjExMDA4MjczMn0.GhoH9VutUFXCqaiOv0Wz-P5rsPzYOwg0yUoTj4c5UuA';

Future<void> initBackend() => Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

SupabaseClient get sb => Supabase.instance.client;
String? get myId => sb.auth.currentUser?.id;

// ───────────────── أدوات تنسيق ─────────────────

num _n(dynamic v) => v is num ? v : (num.tryParse('${v ?? ''}') ?? 0);
num? _nn(dynamic v) => v == null ? null : _n(v);
DateTime? _d(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
List<String> _sl(dynamic v) => v == null ? <String>[] : List<String>.from((v as List).map((e) => '$e'));

String fmtMoney(num v) => '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)} ر.س';
String fmtMoney2(num v) => '${v.toStringAsFixed(2)} ر.س';
String fmtDate(DateTime? d) => d == null ? '' : '${d.year}/${d.month}/${d.day}';
String fmtTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'ص' : 'م'}';
}

String fmtAgo(DateTime? d) {
  if (d == null) return '';
  final s = DateTime.now().difference(d);
  if (s.inMinutes < 1) return 'الآن';
  if (s.inMinutes < 60) return 'قبل ${s.inMinutes} د';
  if (s.inHours < 2) return 'قبل ساعة';
  if (s.inHours < 24) return 'قبل ${s.inHours} ساعات';
  if (s.inDays < 2) return 'أمس';
  return fmtDate(d);
}

String fmtLeft(DateTime? d) {
  if (d == null) return '';
  final s = d.difference(DateTime.now());
  if (s.isNegative) return 'انتهت المهلة';
  if (s.inHours >= 48) return 'باقي ${s.inDays} يوم';
  if (s.inHours >= 1) return 'باقي ${s.inHours} ساعة';
  return 'باقي ${s.inMinutes} دقيقة';
}

String errMsg(Object e) {
  if (e is PostgrestException) return e.message;
  if (e is AuthException) return e.message;
  if (e is FunctionException) {
    final d = e.details;
    if (d is Map && d['error'] != null) return '${d['error']}';
    return 'تعذّر الاتصال، حاول مرة ثانية';
  }
  if (e is StorageException) return e.message;
  return 'صار خطأ: $e';
}

// ───────────────── النماذج ─────────────────

class Profile {
  final String id;
  final String? phone, name, city, bio, avatarUrl, storeCr, storeVat, storeLocation;
  final String role, plan;
  final List<String> brands, categories;
  final bool receiveRequests, verified;
  final Map<String, dynamic> socials;
  Profile.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        phone = j['phone'],
        name = j['name'],
        city = j['city'],
        bio = j['bio'],
        avatarUrl = j['avatar_url'],
        storeCr = j['store_cr'],
        storeVat = j['store_vat'],
        storeLocation = j['store_location'],
        role = j['role'] ?? 'buyer',
        plan = j['plan'] ?? 'free',
        brands = _sl(j['brands']),
        categories = _sl(j['categories']),
        receiveRequests = j['receive_requests'] ?? true,
        verified = j['verified'] ?? false,
        socials = Map<String, dynamic>.from(j['socials'] ?? {});
  bool get isMerchant => role == 'merchant';
  String get displayName => (name == null || name!.isEmpty) ? 'مستخدم' : name!;
  String get initial => displayName.substring(0, 1);
}

class Listing {
  final String id, sellerId, title, condition, saleType, status;
  final String? brand, model, category, city, description;
  final int? yearFrom, yearTo;
  final num? price, startPrice;
  final DateTime? auctionEndsAt, createdAt;
  final int quantity, views;
  final List<String> delivery, images;
  final Profile? seller;
  final num? topBid;
  final int bidsCount;
  Listing.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        sellerId = j['seller_id'],
        title = j['title'],
        condition = j['condition'] ?? '',
        saleType = j['sale_type'] ?? 'fixed',
        status = j['status'] ?? 'active',
        brand = j['brand'],
        model = j['model'],
        category = j['category'],
        city = j['city'],
        description = j['description'],
        yearFrom = j['year_from'],
        yearTo = j['year_to'],
        price = _nn(j['price']),
        startPrice = _nn(j['start_price']),
        auctionEndsAt = _d(j['auction_ends_at']),
        createdAt = _d(j['created_at']),
        quantity = j['quantity'] ?? 1,
        views = j['views'] ?? 0,
        delivery = _sl(j['delivery']),
        images = _sl(j['images']),
        seller = j['seller'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['seller'])) : null,
        topBid = _topBid(j['bids']),
        bidsCount = j['bids'] is List ? (j['bids'] as List).where((b) => b['status'] != 'rejected').length : 0;
  static num? _topBid(dynamic bids) {
    if (bids is! List || bids.isEmpty) return null;
    num? m;
    for (final b in bids) {
      if (b['status'] == 'rejected') continue;
      final a = _n(b['amount']);
      if (m == null || a > m) m = a;
    }
    return m;
  }

  bool get auction => saleType == 'auction';
  String get priceLabel => auction ? 'على السوم' : fmtMoney(price ?? 0);
  String get fits {
    final y = yearFrom == null ? '' : (yearTo != null && yearTo != yearFrom ? '$yearFrom – $yearTo' : '$yearFrom');
    return [brand, model, y].where((e) => e != null && e.isNotEmpty).join(' ');
  }

  String? get cover => images.isEmpty ? null : images.first;
  String get sellerName => seller?.displayName ?? '';
}

class Bid {
  final String id, listingId, bidderId, status;
  final num amount;
  final DateTime? createdAt;
  final Profile? bidder;
  Bid.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        listingId = j['listing_id'],
        bidderId = j['bidder_id'],
        status = j['status'] ?? 'pending',
        amount = _n(j['amount']),
        createdAt = _d(j['created_at']),
        bidder = j['bidder'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['bidder'])) : null;
  String get maskedName {
    final n = bidder?.displayName ?? 'مستخدم';
    return n.length <= 3 ? '$n ***' : '${n.substring(0, 3)}***';
  }
}

class PartRequest {
  final String id, buyerId, brand, condition, status;
  final String? model, vin, category, notes, city;
  final int? year;
  final List<String> parts, images;
  final DateTime? expiresAt, createdAt;
  final List<Offer> offers;
  final Profile? buyer;
  PartRequest.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        buyerId = j['buyer_id'],
        brand = j['brand'],
        condition = j['condition'] ?? '',
        status = j['status'] ?? 'open',
        model = j['model'],
        vin = j['vin'],
        category = j['category'],
        notes = j['notes'],
        city = j['city'],
        year = j['year'],
        parts = _sl(j['parts']),
        images = _sl(j['images']),
        expiresAt = _d(j['expires_at']),
        createdAt = _d(j['created_at']),
        offers = j['offers'] is List ? (j['offers'] as List).map((e) => Offer.fromJson(Map<String, dynamic>.from(e))).toList() : [],
        buyer = j['buyer'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['buyer'])) : null;
  String get partsLabel => parts.join('، ');
  String get car => [brand, model, year?.toString()].where((e) => e != null && e.isNotEmpty).join(' ');
  String get title => '$partsLabel · $car · $condition';
  bool get isOpen => status == 'open' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  List<Offer> get liveOffers => offers.where((o) => o.status != 'withdrawn').toList();
  num? get bestPrice => liveOffers.isEmpty ? null : liveOffers.map((o) => o.price).reduce((a, b) => a < b ? a : b);
}

class Offer {
  final String id, requestId, supplierId, condition, status;
  final num price;
  final bool includesShipping;
  final String? deliveryTime, warranty, note;
  final List<String> images;
  final DateTime? createdAt;
  final Profile? supplier;
  Offer.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? '',
        requestId = j['request_id'] ?? '',
        supplierId = j['supplier_id'] ?? '',
        condition = j['condition'] ?? '',
        status = j['status'] ?? 'pending',
        price = _n(j['price']),
        includesShipping = j['includes_shipping'] ?? true,
        deliveryTime = j['delivery_time'],
        warranty = j['warranty'],
        note = j['note'],
        images = _sl(j['images']),
        createdAt = _d(j['created_at']),
        supplier = j['supplier'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['supplier'])) : null;
}

class OrderPhoto {
  final String side, url;
  OrderPhoto.fromJson(Map<String, dynamic> j)
      : side = j['side'],
        url = j['url'];
}

class Order {
  final String id, orderNo, buyerId, sellerId, title, status;
  final String? listingId, offerId, bidId, condition, paymentMethod, carrier, trackingNo, shippingAddress, invoiceNo;
  final int quantity;
  final num subtotal, shipping, vat, total;
  final DateTime? paidAt, payDeadline, shippedAt, deliveredAt, createdAt;
  final Profile? seller, buyer;
  final List<OrderPhoto> photos;
  final String? image;
  Order.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        orderNo = j['order_no'] ?? '',
        buyerId = j['buyer_id'],
        sellerId = j['seller_id'],
        title = j['title'] ?? '',
        status = j['status'] ?? 'awaiting_payment',
        listingId = j['listing_id'],
        offerId = j['offer_id'],
        bidId = j['bid_id'],
        condition = j['condition'],
        paymentMethod = j['payment_method'],
        carrier = j['carrier'],
        trackingNo = j['tracking_no'],
        shippingAddress = j['shipping_address'],
        invoiceNo = j['invoice_no'],
        quantity = j['quantity'] ?? 1,
        subtotal = _n(j['subtotal']),
        shipping = _n(j['shipping']),
        vat = _n(j['vat']),
        total = _n(j['total']),
        paidAt = _d(j['paid_at']),
        payDeadline = _d(j['pay_deadline']),
        shippedAt = _d(j['shipped_at']),
        deliveredAt = _d(j['delivered_at']),
        createdAt = _d(j['created_at']),
        seller = j['seller'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['seller'])) : null,
        buyer = j['buyer'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['buyer'])) : null,
        photos = j['order_photos'] is List ? (j['order_photos'] as List).map((e) => OrderPhoto.fromJson(Map<String, dynamic>.from(e))).toList() : [],
        image = (j['listing'] is Map && (j['listing']['images'] as List?)?.isNotEmpty == true) ? '${j['listing']['images'][0]}' : null;

  /// تقدّم الطلب من 5 (طلب، دفع، تجهيز، شحن، تسليم)
  int get progress => switch (status) {
        'awaiting_payment' => 1,
        'paid' => 2,
        'preparing' => 3,
        'shipped' => 4,
        'delivered' => 5,
        _ => 0,
      };
  String? photo(String side) {
    for (final p in photos) {
      if (p.side == side) return p.url;
    }
    return null;
  }
}

class Conversation {
  final String id, buyerId, sellerId;
  final String? listingId, lastMessage;
  final DateTime? lastAt;
  final Profile? buyer, seller;
  final Map<String, dynamic>? listing;
  Conversation.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        buyerId = j['buyer_id'],
        sellerId = j['seller_id'],
        listingId = j['listing_id'],
        lastMessage = j['last_message'],
        lastAt = _d(j['last_at']),
        buyer = j['buyer'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['buyer'])) : null,
        seller = j['seller'] is Map ? Profile.fromJson(Map<String, dynamic>.from(j['seller'])) : null,
        listing = j['listing'] is Map ? Map<String, dynamic>.from(j['listing']) : null;
  Profile? get other => buyerId == myId ? seller : buyer;
}

class Message {
  final String id, conversationId, senderId;
  final String? body;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? readAt;
  Message.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        conversationId = j['conversation_id'],
        senderId = j['sender_id'],
        body = j['body'],
        images = _sl(j['images']),
        createdAt = _d(j['created_at']) ?? DateTime.now(),
        readAt = _d(j['read_at']);
  bool get mine => senderId == myId;
}

class Notif {
  final String id, kind, title;
  final String? body, link;
  final bool read;
  final DateTime? createdAt;
  Notif.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        kind = j['kind'],
        title = j['title'],
        body = j['body'],
        link = j['link'],
        read = j['read'] ?? false,
        createdAt = _d(j['created_at']);
}

class Car {
  final String id, brand;
  final String? model, vin;
  final int? year;
  final bool isDefault;
  Car.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        brand = j['brand'],
        model = j['model'],
        vin = j['vin'],
        year = j['year'],
        isDefault = j['is_default'] ?? false;
  String get title => [brand, model, year?.toString()].where((e) => e != null && e.isNotEmpty).join(' ');
}

// ───────────────── الاستعلامات ─────────────────

const _listingSel = '*, seller:profiles!listings_seller_id_fkey(*), bids(amount,status)';
const _orderSel = '*, seller:profiles!orders_seller_id_fkey(*), buyer:profiles!orders_buyer_id_fkey(*), order_photos(side,url), listing:listings(images)';

class Api {
  // تسجيل الدخول برقم الجوال (الرمز مؤقتاً 1234 إلى أن يُربط مزوّد الرسائل)
  static Future<void> phoneLogin({required String phone, required String code, String? role, String? name, String? city}) async {
    final res = await sb.functions.invoke('phone-login', body: {'phone': phone, 'code': code, 'role': role, 'name': name, 'city': city});
    final data = res.data is Map ? Map<String, dynamic>.from(res.data) : <String, dynamic>{};
    if (data['error'] != null) throw Exception(data['error']);
    await sb.auth.setSession(data['refresh_token']);
  }

  static Future<void> signOut() => sb.auth.signOut();

  static Future<Profile?> profile(String id) async {
    final r = await sb.from('profiles').select().eq('id', id).maybeSingle();
    return r == null ? null : Profile.fromJson(r);
  }

  // الإعلانات
  static Future<List<Listing>> listings({String? q, String? brand, String? sellerId, String? status = 'active', int limit = 50, bool auctionOnly = false}) async {
    var f = sb.from('listings').select(_listingSel);
    if (status != null) f = f.eq('status', status);
    if (sellerId != null) f = f.eq('seller_id', sellerId);
    if (brand != null && brand.isNotEmpty) f = f.eq('brand', brand);
    if (auctionOnly) f = f.eq('sale_type', 'auction');
    if (q != null && q.trim().isNotEmpty) {
      final words = q.trim().split(RegExp(r'\s+'));
      for (final w in words) {
        f = f.or('title.ilike.%$w%,brand.ilike.%$w%,model.ilike.%$w%');
      }
    }
    final r = await f.order('created_at', ascending: false).limit(limit);
    return r.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  static Future<Listing?> listing(String id) async {
    final r = await sb.from('listings').select(_listingSel).eq('id', id).maybeSingle();
    if (r == null) return null;
    sb.rpc('increment_views', params: {'p_listing': id}).catchError((_) => null);
    return Listing.fromJson(r);
  }

  static Future<List<Bid>> bids(String listingId) async {
    final r = await sb.from('bids').select('*, bidder:profiles!bids_bidder_id_fkey(*)').eq('listing_id', listingId).neq('status', 'rejected').order('amount', ascending: false);
    return r.map<Bid>((e) => Bid.fromJson(e)).toList();
  }

  static Future<void> placeBid(String listingId, num amount) =>
      sb.from('bids').insert({'listing_id': listingId, 'bidder_id': myId, 'amount': amount});

  static Future<String> createListing(Map<String, dynamic> data) async {
    final r = await sb.from('listings').insert({...data, 'seller_id': myId}).select('id').single();
    return r['id'];
  }

  static Future<void> updateListing(String id, Map<String, dynamic> data) => sb.from('listings').update(data).eq('id', id);
  static Future<void> deleteListing(String id) => sb.from('listings').delete().eq('id', id);

  // المفضلة والسلة
  static Future<Set<String>> favoriteIds() async {
    if (myId == null) return {};
    final r = await sb.from('favorites').select('listing_id').eq('user_id', myId!);
    return r.map<String>((e) => e['listing_id'] as String).toSet();
  }

  static Future<void> toggleFavorite(String listingId, bool on) async {
    if (on) {
      await sb.from('favorites').upsert({'user_id': myId, 'listing_id': listingId});
    } else {
      await sb.from('favorites').delete().eq('user_id', myId!).eq('listing_id', listingId);
    }
  }

  static Future<List<Listing>> favorites() async {
    final r = await sb.from('favorites').select('listing:listings($_listingSel)').eq('user_id', myId!).order('created_at', ascending: false);
    return r.where((e) => e['listing'] != null).map<Listing>((e) => Listing.fromJson(Map<String, dynamic>.from(e['listing']))).toList();
  }

  static Future<List<(Listing, int)>> cart() async {
    final r = await sb.from('cart_items').select('qty, listing:listings($_listingSel)').eq('user_id', myId!);
    return r.where((e) => e['listing'] != null).map<(Listing, int)>((e) => (Listing.fromJson(Map<String, dynamic>.from(e['listing'])), e['qty'] as int)).toList();
  }

  static Future<void> setCartQty(String listingId, int qty) async {
    if (qty <= 0) {
      await sb.from('cart_items').delete().eq('user_id', myId!).eq('listing_id', listingId);
    } else {
      await sb.from('cart_items').upsert({'user_id': myId, 'listing_id': listingId, 'qty': qty});
    }
  }

  static Future<void> clearCart() => sb.from('cart_items').delete().eq('user_id', myId!);

  static Future<List<String>> checkoutCart(String? address) async {
    final r = await sb.rpc('checkout_cart', params: {'p_address': address});
    return List<String>.from(r as List);
  }

  // الطلبات
  static Future<List<Order>> myOrders({bool asSeller = false}) async {
    final r = await sb.from('orders').select(_orderSel).eq(asSeller ? 'seller_id' : 'buyer_id', myId!).order('created_at', ascending: false);
    return r.map<Order>((e) => Order.fromJson(e)).toList();
  }

  static Future<Order?> order(String id) async {
    final r = await sb.from('orders').select(_orderSel).eq('id', id).maybeSingle();
    return r == null ? null : Order.fromJson(r);
  }

  static Future<List<Order>> ordersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final r = await sb.from('orders').select(_orderSel).inFilter('id', ids);
    return r.map<Order>((e) => Order.fromJson(e)).toList();
  }

  static Future<void> payOrders(List<String> ids, String method) => sb.rpc('pay_orders', params: {'p_orders': ids, 'p_method': method});
  static Future<void> setOrderAddress(List<String> ids, String address) => sb.from('orders').update({'shipping_address': address}).inFilter('id', ids);
  static Future<void> confirmReceived(String id) => sb.rpc('confirm_received', params: {'p_order': id});
  static Future<void> sellerSetStatus(String id, String status) => sb.rpc('seller_set_status', params: {'p_order': id, 'p_status': status});
  static Future<void> markShipped(String id, String carrier, String tracking) =>
      sb.rpc('mark_shipped', params: {'p_order': id, 'p_carrier': carrier, 'p_tracking': tracking});

  static Future<void> setOrderPhoto(String orderId, String side, String url) =>
      sb.from('order_photos').upsert({'order_id': orderId, 'side': side, 'url': url}, onConflict: 'order_id,side');

  // طلبات القطع والعروض
  static Future<String> createRequest(Map<String, dynamic> data) async {
    final r = await sb.from('part_requests').insert({...data, 'buyer_id': myId}).select('id').single();
    return r['id'];
  }

  static Future<int> matchingSuppliers(String brand) async {
    final r = await sb.from('profiles').select('id').eq('role', 'merchant').contains('brands', [brand]);
    return r.length;
  }

  static Future<List<PartRequest>> myRequests() async {
    await sb.rpc('expire_requests').catchError((_) => null);
    final r = await sb.from('part_requests').select('*, offers(*)').eq('buyer_id', myId!).neq('status', 'expired').order('created_at', ascending: false);
    final r2 = await sb.from('part_requests').select('*, offers(*)').eq('buyer_id', myId!).eq('status', 'expired').order('created_at', ascending: false).limit(20);
    return [...r, ...r2].map<PartRequest>((e) => PartRequest.fromJson(e)).toList();
  }

  static Future<PartRequest?> request(String id) async {
    final r = await sb.from('part_requests').select('*, buyer:profiles!part_requests_buyer_id_fkey(*), offers(*, supplier:profiles!offers_supplier_id_fkey(*))').eq('id', id).maybeSingle();
    return r == null ? null : PartRequest.fromJson(r);
  }

  /// طلبات العملاء المطابقة لتخصص التاجر (الحماية في القاعدة تضمن الماركة)
  static Future<List<PartRequest>> customerRequests() async {
    await sb.rpc('expire_requests').catchError((_) => null);
    final r = await sb.from('part_requests').select('*, offers(*)').neq('buyer_id', myId!).order('created_at', ascending: false).limit(100);
    return r.map<PartRequest>((e) => PartRequest.fromJson(e)).toList();
  }

  static Future<void> republish(String id) => sb.rpc('republish_request', params: {'p_request': id});

  static Future<void> submitOffer(Map<String, dynamic> data) => sb.from('offers').insert({...data, 'supplier_id': myId});
  static Future<String> acceptOffer(String offerId) async => (await sb.rpc('accept_offer', params: {'p_offer': offerId})) as String;

  // السومات (للبائع)
  static Future<List<Listing>> myAuctions() => listings(sellerId: myId, status: null, auctionOnly: true);
  static Future<String> acceptBid(String id) async => (await sb.rpc('accept_bid', params: {'p_bid': id})) as String;
  static Future<void> rejectBid(String id) => sb.rpc('reject_bid', params: {'p_bid': id});

  // المحادثات
  static Future<String> startChat(String otherId, {String? listingId}) async =>
      (await sb.rpc('start_conversation', params: {'p_other': otherId, 'p_listing': listingId})) as String;

  static Future<List<Conversation>> conversations() async {
    final r = await sb
        .from('conversations')
        .select('*, buyer:profiles!conversations_buyer_id_fkey(*), seller:profiles!conversations_seller_id_fkey(*), listing:listings(id,title,price,sale_type,images)')
        .or('buyer_id.eq.$myId,seller_id.eq.$myId')
        .order('last_at', ascending: false);
    return r.map<Conversation>((e) => Conversation.fromJson(e)).toList();
  }

  static Future<Conversation?> conversation(String id) async {
    final r = await sb
        .from('conversations')
        .select('*, buyer:profiles!conversations_buyer_id_fkey(*), seller:profiles!conversations_seller_id_fkey(*), listing:listings(id,title,price,sale_type,images)')
        .eq('id', id)
        .maybeSingle();
    return r == null ? null : Conversation.fromJson(r);
  }

  static Stream<List<Message>> messages(String conversationId) => sb
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at')
      .map((rows) => rows.map((e) => Message.fromJson(e)).toList());

  static Future<void> sendMessage(String conversationId, {String? body, List<String> images = const []}) =>
      sb.from('messages').insert({'conversation_id': conversationId, 'sender_id': myId, 'body': body, 'images': images});

  static Future<void> markChatRead(String conversationId) =>
      sb.from('messages').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('conversation_id', conversationId).neq('sender_id', myId!).isFilter('read_at', null);

  static Future<Map<String, int>> unreadByConversation() async {
    final r = await sb.from('messages').select('conversation_id').neq('sender_id', myId!).isFilter('read_at', null);
    final m = <String, int>{};
    for (final e in r) {
      m[e['conversation_id']] = (m[e['conversation_id']] ?? 0) + 1;
    }
    return m;
  }

  // الإشعارات
  static Stream<List<Notif>> notifications() => sb
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', myId!)
      .order('created_at', ascending: false)
      .limit(100)
      .map((rows) => rows.map((e) => Notif.fromJson(e)).toList());

  static Future<void> markNotifRead(String id) => sb.from('notifications').update({'read': true}).eq('id', id);
  static Future<void> markAllNotifsRead() => sb.from('notifications').update({'read': true}).eq('user_id', myId!).eq('read', false);

  // الحساب
  static Future<void> updateProfile(Map<String, dynamic> data) => sb.from('profiles').update(data).eq('id', myId!);

  static Future<String?> iban() async {
    final r = await sb.from('payout_accounts').select('iban').eq('user_id', myId!).maybeSingle();
    return r?['iban'];
  }

  static Future<void> setIban(String iban) => sb.from('payout_accounts').upsert({'user_id': myId, 'iban': iban, 'updated_at': DateTime.now().toUtc().toIso8601String()});

  static Future<List<Car>> cars() async {
    final r = await sb.from('cars').select().eq('user_id', myId!).order('created_at');
    return r.map<Car>((e) => Car.fromJson(e)).toList();
  }

  static Future<void> addCar(Map<String, dynamic> data) async {
    final count = (await sb.from('cars').select('id').eq('user_id', myId!)).length;
    await sb.from('cars').insert({...data, 'user_id': myId, 'is_default': count == 0});
  }

  static Future<void> deleteCar(String id) => sb.from('cars').delete().eq('id', id);
  static Future<void> setDefaultCar(String id) async {
    await sb.from('cars').update({'is_default': false}).eq('user_id', myId!);
    await sb.from('cars').update({'is_default': true}).eq('id', id);
  }

  static Future<Map<String, dynamic>> merchantStats(int days) async => Map<String, dynamic>.from(await sb.rpc('merchant_stats', params: {'p_days': days}));

  static Future<int> followersCount(String storeId) async => (await sb.from('follows').select('follower_id').eq('store_id', storeId)).length;
  static Future<int> followingCount() async => (await sb.from('follows').select('store_id').eq('follower_id', myId!)).length;
  static Future<bool> isFollowing(String storeId) async =>
      (await sb.from('follows').select('store_id').eq('follower_id', myId!).eq('store_id', storeId)).isNotEmpty;
  static Future<void> setFollow(String storeId, bool on) => on
      ? sb.from('follows').upsert({'follower_id': myId, 'store_id': storeId})
      : sb.from('follows').delete().eq('follower_id', myId!).eq('store_id', storeId);

  static Future<List<Map<String, dynamic>>> comments(String listingId) async =>
      List<Map<String, dynamic>>.from(await sb.from('comments').select('*, user:profiles(name)').eq('listing_id', listingId).order('created_at'));
  static Future<void> addComment(String listingId, String body) => sb.from('comments').insert({'listing_id': listingId, 'user_id': myId, 'body': body});

  // الصور
  static Future<XFile?> pickImage({bool camera = false}) =>
      ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, imageQuality: 75, maxWidth: 1600);

  static Future<String> uploadImage(XFile f) async {
    final bytes = await f.readAsBytes();
    var ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : 'jpg';
    if (!['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(ext)) ext = 'jpg';
    final path = '$myId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await sb.storage.from('media').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: ext == 'png' ? 'image/png' : 'image/jpeg', upsert: true));
    return sb.storage.from('media').getPublicUrl(path);
  }
}

// ───────────────── مزوّدات الحالة ─────────────────

final authProvider = StreamProvider<AuthState>((ref) => sb.auth.onAuthStateChange);

final myProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authProvider);
  final id = myId;
  if (id == null) return null;
  return Api.profile(id);
});

final favoriteIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.watch(authProvider);
  return Api.favoriteIds();
});

final cartProvider = FutureProvider<List<(Listing, int)>>((ref) => Api.cart());

final notificationsProvider = StreamProvider<List<Notif>>((ref) {
  ref.watch(authProvider);
  if (myId == null) return Stream.value(const []);
  return Api.notifications();
});
