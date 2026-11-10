// النماذج والبيانات التجريبية — تُستبدل بـ Supabase في مرحلة الربط

class Product {
  final String id;
  final String title;
  final int? price;
  final bool auction;
  final int? startPrice;
  final int? highestBid;
  final int bidsCount;
  final String date;
  final String city;
  final String seller;
  final String condition;
  final String category;
  final String fits;
  final String notes;
  final bool pickupOnly;
  const Product({
    required this.id,
    required this.title,
    this.price,
    this.auction = false,
    this.startPrice,
    this.highestBid,
    this.bidsCount = 0,
    required this.date,
    required this.city,
    this.seller = 'كار ون',
    this.condition = 'جديد أصلي',
    this.category = 'بودي',
    this.fits = 'تويوتا كامري 2020',
    this.notes = '',
    this.pickupOnly = false,
  });
  String get priceLabel => auction ? 'على السوم' : '$price ر.س';
}

class Bid {
  final String name;
  final int amount;
  final String time;
  final bool top;
  const Bid(this.name, this.amount, this.time, {this.top = false});
}

class Offer {
  final String store;
  final String rating;
  final int price;
  final List<String> tags;
  final String note;
  final bool best;
  final String condition;
  const Offer(this.store, this.rating, this.price, this.tags, this.note, {this.best = false, this.condition = 'جديد أصلي'});
}

enum ReqStatus { active, expiredNoOffers, endedNoPurchase }

class PartRequest {
  final String id;
  final String title;
  final String? sub;
  final ReqStatus status;
  final int offers;
  final int? best;
  final bool image;
  final String left;
  const PartRequest(this.id, this.title, this.status, {this.sub, this.offers = 0, this.best, this.image = false, this.left = ''});
}

enum OrderStatus { shipping, awaitingPayment, preparing, delivered }

class Order {
  final String id;
  final String title;
  final String no;
  final OrderStatus status;
  final int progress;
  const Order(this.id, this.title, this.no, this.status, this.progress);
}

class AppNotification {
  final String kind; // offer, order, request, accepted, invoice
  final String title;
  final String body;
  final String date;
  final bool unread;
  const AppNotification(this.kind, this.title, this.body, this.date, {this.unread = false});
}

class ChatThread {
  final String id;
  final String name;
  final String last;
  final String time;
  final int unread;
  final bool store;
  const ChatThread(this.id, this.name, this.last, this.time, {this.unread = 0, this.store = true});
}

class CustomerRequest {
  final String id;
  final String title;
  final String sub;
  final String left;
  final String offers;
  final String city;
  final bool image;
  const CustomerRequest(this.id, this.title, this.sub, this.left, this.offers, this.city, {this.image = false});
}

class Invoice {
  final String no;
  final String desc;
  final String amount;
  final bool refunded;
  const Invoice(this.no, this.desc, this.amount, {this.refunded = false});
}

class Mock {
  static const products = [
    Product(id: 'p1', title: 'جهاز فحص كامري 2020', price: 100, date: '2026/9/24', city: 'الرياض', category: 'مكينة', notes: 'أعلى سومه', pickupOnly: true, condition: 'أصلي'),
    Product(id: 'p2', title: 'صدام أمامي كامري 2020', price: 450, date: '2026/9/20', city: 'الرياض'),
    Product(id: 'p3', title: 'فلتر زيت أصلي تويوتا', price: 50, date: '2026/9/18', city: 'جدة', category: 'مكينة'),
    Product(id: 'p4', title: 'صدام أمامي كامري 2020', auction: true, startPrice: 300, highestBid: 350, bidsCount: 5, date: '2026/9/22', city: 'الرياض', seller: 'الصقر لقطع الغيار', fits: 'تويوتا كامري 2018 – 2021'),
    Product(id: 'p5', title: 'شمعات لكزس LX 2020', price: 620, date: '2026/9/14', city: 'جدة', category: 'إنارة', fits: 'لكزس LX 2020'),
  ];

  static const searchResults = [
    Product(id: 'p2', title: 'صدام أمامي كامري 2020', price: 450, date: '2026/9/20', city: 'الرياض'),
    Product(id: 's2', title: 'صدام أمامي كامري 2020', price: 380, date: '2026/9/19', city: 'جدة'),
    Product(id: 'p4', title: 'صدام خلفي كامري 2020', auction: true, startPrice: 300, highestBid: 350, bidsCount: 5, date: '2026/9/22', city: 'الرياض'),
    Product(id: 's4', title: 'شبك صدام كامري 2020', price: 150, date: '2026/9/17', city: 'الدمام'),
    Product(id: 's5', title: 'صدام أمامي كامري 2019', price: 300, date: '2026/9/15', city: 'حفر الباطن'),
    Product(id: 's6', title: 'حساسات صدام كامري', price: 90, date: '2026/9/12', city: 'الرياض'),
  ];

  static Product product(String id) =>
      [...products, ...searchResults].firstWhere((p) => p.id == id, orElse: () => products.first);

  static const bids = [
    Bid('أبو ف***', 350, 'قبل 12 د', top: true),
    Bid('سعد ***', 330, 'قبل ساعة'),
    Bid('محمد ***', 310, 'قبل 3 ساعات'),
    Bid('عبدالله ***', 300, 'أمس'),
  ];

  static const offers = [
    Offer('الصقر لقطع الغيار', '4.8 · 120 تقييم', 380, ['ضمان 6 أشهر', '2-3 أيام'], 'متوفر أصلي وكالة، نشحن اليوم', best: true),
    Offer('كار ون', 'جديد · لا تقييمات', 420, ['3-5 أيام'], 'القطعة متوفرة بالمستودع'),
    Offer('مؤسسة النخبة', '4.5 · 64 تقييم', 450, ['ضمان سنة', 'يوم واحد'], 'أصلي مع فاتورة الوكالة'),
  ];

  static const requests = [
    PartRequest('r1', 'صدام أمامي · تويوتا كامري 2020 · جديد أصلي', ReqStatus.active, offers: 3, best: 380, left: 'باقي 31 ساعة'),
    PartRequest('r2', 'صدام · لكزس LX 2020 · جديد أصلي', ReqStatus.expiredNoOffers, sub: 'تصنيف: بودي · أهم شي وكالة', image: true),
    PartRequest('r3', 'مطلوب مكينة كابرس · شيفروليه تاهو 2020 · جديد أصلي', ReqStatus.expiredNoOffers, image: true),
    PartRequest('r4', 'صدام أمامي · تويوتا يارس 2020 · جديد أصلي', ReqStatus.endedNoPurchase, offers: 1, best: 450),
  ];

  static const orders = [
    Order('o1', 'صدام أمامي كامري 2020', 'رقم الطلب ORD-58213 · 557.75 ر.س', OrderStatus.shipping, 4),
    Order('o2', 'جهاز فحص كامري 2020', 'رقم الطلب ORD-58190 · 115.00 ر.س', OrderStatus.awaitingPayment, 1),
    Order('o3', 'فلتر زيت أصلي تويوتا', 'رقم الطلب ORD-58102 · 92.00 ر.س', OrderStatus.preparing, 2),
  ];

  static const notifications = [
    AppNotification('offer', 'عرض جديد على طلبك', 'وصلك عرض بسعر 380 ر.س على صدام أمامي كامري 2020', 'الآن', unread: true),
    AppNotification('order', 'طلب جديد على قطعتك', 'تم شراء قطعتك «جهاز فحص كامري». الحالة: بانتظار الدفع', '2026/9/25', unread: true),
    AppNotification('request', 'طلب قطعة جديد يناسب تخصصك', 'عميل يبحث عن صدام أمامي تويوتا كامري 2019 — اضغط لعرض الطلب وتقديم عرض سعر', '2026/7/14', unread: true),
    AppNotification('request', 'طلب قطعة جديد يناسب تخصصك', 'عميل يبحث عن قطعة تويوتا كامري — اضغط لعرض الطلب وتقديم عرض سعر', '2026/7/14', unread: true),
    AppNotification('accepted', 'تم قبول عرضك', 'قبل العميل عرضك على شمعات لكزس LX 2020', '2026/7/13'),
    AppNotification('request', 'طلب قطعة جديد يناسب تخصصك', 'عميل يبحث عن حروف لكزس، كلمات لكزس — اضغط لعرض الطلب', '2026/7/13'),
    AppNotification('invoice', 'تم إصدار الفاتورة', 'فاتورة طلبك رقم INV-2026-001284 جاهزة للتحميل', '2026/7/12'),
  ];

  static const chats = [
    ChatThread('c1', 'كار ون', 'تمام، أرسلت لك صور القطعة من كل الجهات', 'الآن', unread: 2),
    ChatThread('c2', 'الصقر لقطع الغيار', 'العرض ساري لين بكرة الساعة 12', '9:41 ص', unread: 1),
    ChatThread('c3', 'مؤسسة النخبة', 'أصلي مع فاتورة الوكالة إن شاء الله', 'أمس'),
    ChatThread('c4', 'عبدالله', 'كم آخر سعر للصدام؟', 'أمس', store: false),
    ChatThread('c5', 'قطع الشرقية', 'تم شحن الطلب، رقم التتبع بالرسالة', '2026/11/02'),
  ];

  static const customerRequests = [
    CustomerRequest('cr1', 'صدام أمامي · تويوتا كامري 2020', 'جديد أصلي · بودي · «أبيه أصلي وكالة»', 'باقي 31 ساعة', '2 عروض', 'الرياض', image: true),
    CustomerRequest('cr2', 'شمعات أمامية · لكزس LX 2020', 'جديد درجة أولى · إنارة', 'باقي 20 ساعة', 'لا عروض بعد', 'جدة'),
    CustomerRequest('cr3', 'كمبروسر مكيف · نيسان باترول 2022', 'مستعمل أو جديد · تبريد', 'باقي 6 ساعات', '4 عروض', 'الدمام'),
  ];

  static const invoices = [
    Invoice('INV-2026-001284', 'صدام أمامي كامري 2020 · 2026/11/08', '557.75'),
    Invoice('INV-2026-001190', 'جهاز فحص كامري · 2026/10/21', '115.00'),
    Invoice('INV-2026-001102', 'فلتر زيت أصلي · 2026/10/02', '92.00', refunded: true),
    Invoice('INV-2026-000987', 'شمعات لكزس LX · 2026/09/14', '475.75'),
  ];

  static const brands = ['تويوتا', 'لكزس', 'نيسان', 'إنفينيتي', 'هوندا', 'أكيورا', 'هيونداي'];
  static const allBrands = [
    'تويوتا', 'لكزس', 'نيسان', 'إنفينيتي', 'هوندا', 'أكيورا', 'ميتسوبيشي', 'مازدا', 'سوزوكي', 'سوبارو',
    'جي إم سي', 'شيفروليه', 'كاديلاك', 'فورد', 'لينكولن', 'دودج', 'رام', 'كرايسلر', 'جيب', 'تسلا',
    'مرسيدس', 'بي إم دبليو', 'ميني', 'أودي', 'فولكس واجن', 'بورش', 'هيونداي', 'كيا', 'جينيسيس', 'لاند روفر',
    'جاكوار', 'فولفو', 'بيجو', 'رينو', 'فيات', 'مازيراتي', 'فيراري', 'بنتلي', 'رولز رويس', 'شانجان', 'جيلي', 'هافال', 'إم جي', 'بي واي دي',
  ];
  static const categories = ['بودي', 'إنارة', 'مكينة', 'قير', 'كهرباء', 'تبريد', 'عفشة', 'فرامل', 'إطارات'];
  static const conditions = ['جديد أصلي', 'جديد درجة أولى', 'مستعمل', 'كليهما'];
  static const cities = ['الرياض', 'جدة', 'الدمام', 'مكة', 'المدينة', 'حفر الباطن', 'أبها', 'تبوك'];
}
