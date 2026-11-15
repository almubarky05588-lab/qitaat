// طبقة توافق: نفس أسماء الأيقونات المستخدمة في كود التطبيق،
// مربوطة بمكتبة Phosphor (رسم أنعم ومتناسق) بدل Lucide.
// LucideIcons = النمط العادي · AppIconsFill = الممتلئ (التبويب المختار) · AppIconsDuo = بلونين (الأيقونات الكبيرة)
import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

export 'package:phosphor_flutter/phosphor_flutter.dart' show PhosphorIcon, PhosphorIconsRegular, PhosphorIconsFill, PhosphorIconsDuotone, PhosphorIconsBold;

class LucideIcons {
  LucideIcons._();

  static const IconData home = PhosphorIconsRegular.house;
  static const IconData shoppingBag = PhosphorIconsRegular.handbag;
  static const IconData archive = PhosphorIconsRegular.package;
  static const IconData user = PhosphorIconsRegular.user;
  static const IconData plus = PhosphorIconsRegular.plus;
  static const IconData minus = PhosphorIconsRegular.minus;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData messageSquare = PhosphorIconsRegular.chatCircleDots;
  static const IconData shoppingCart = PhosphorIconsRegular.shoppingCartSimple;
  static const IconData heart = PhosphorIconsRegular.heart;
  static const IconData mapPin = PhosphorIconsRegular.mapPin;
  static const IconData clock = PhosphorIconsRegular.clock;
  static const IconData chevronLeft = PhosphorIconsRegular.caretLeft;
  static const IconData chevronDown = PhosphorIconsRegular.caretDown;
  static const IconData arrowRight = PhosphorIconsRegular.arrowRight;
  static const IconData arrowLeft = PhosphorIconsRegular.arrowLeft;
  static const IconData arrowUp = PhosphorIconsRegular.arrowUp;
  static const IconData arrowDown = PhosphorIconsRegular.arrowDown;
  static const IconData tag = PhosphorIconsRegular.tag;
  static const IconData truck = PhosphorIconsRegular.truck;
  static const IconData send = PhosphorIconsRegular.paperPlaneTilt;
  static const IconData fileText = PhosphorIconsRegular.fileText;
  static const IconData store = PhosphorIconsRegular.storefront;
  static const IconData camera = PhosphorIconsRegular.camera;
  static const IconData phone = PhosphorIconsRegular.phone;
  static const IconData smartphone = PhosphorIconsRegular.deviceMobile;
  static const IconData lock = PhosphorIconsRegular.lock;
  static const IconData share2 = PhosphorIconsRegular.shareNetwork;
  static const IconData flag = PhosphorIconsRegular.flag;
  static const IconData slidersHorizontal = PhosphorIconsRegular.slidersHorizontal;
  static const IconData check = PhosphorIconsRegular.check;
  static const IconData checkCheck = PhosphorIconsRegular.checks;
  static const IconData checkCircle = PhosphorIconsRegular.checkCircle;
  static const IconData star = PhosphorIconsRegular.star;
  static const IconData car = PhosphorIconsRegular.car;
  static const IconData layoutGrid = PhosphorIconsRegular.squaresFour;
  static const IconData layoutDashboard = PhosphorIconsRegular.chartPieSlice;
  static const IconData inbox = PhosphorIconsRegular.tray;
  static const IconData award = PhosphorIconsRegular.medal;
  static const IconData settings = PhosphorIconsRegular.gear;
  static const IconData headphones = PhosphorIconsRegular.headset;
  static const IconData pencil = PhosphorIconsRegular.pencilSimple;
  static const IconData users = PhosphorIconsRegular.users;
  static const IconData gavel = PhosphorIconsRegular.gavel;
  static const IconData atSign = PhosphorIconsRegular.xLogo;
  static const IconData music = PhosphorIconsRegular.tiktokLogo;
  static const IconData creditCard = PhosphorIconsRegular.creditCard;
  static const IconData shieldCheck = PhosphorIconsRegular.shieldCheck;
  static const IconData download = PhosphorIconsRegular.downloadSimple;
  static const IconData rotateCw = PhosphorIconsRegular.arrowClockwise;
  static const IconData receipt = PhosphorIconsRegular.receipt;
  static const IconData badgeCheck = PhosphorIconsRegular.sealCheck;
  static const IconData shapes = PhosphorIconsRegular.shapes;
  static const IconData logOut = PhosphorIconsRegular.signOut;
  static const IconData x = PhosphorIconsRegular.x;
  static const IconData info = PhosphorIconsRegular.info;
  static const IconData copy = PhosphorIconsRegular.copy;
  static const IconData trash2 = PhosphorIconsRegular.trash;
  static const IconData ticket = PhosphorIconsRegular.ticket;
  static const IconData moreVertical = PhosphorIconsRegular.dotsThreeVertical;
  static const IconData globe = PhosphorIconsRegular.globe;
  static const IconData moon = PhosphorIconsRegular.moon;
  static const IconData helpCircle = PhosphorIconsRegular.question;
  static const IconData alertCircle = PhosphorIconsRegular.warningCircle;
  static const IconData eye = PhosphorIconsRegular.eye;
  static const IconData trendingUp = PhosphorIconsRegular.trendUp;
  static const IconData package = PhosphorIconsRegular.package;
  static const IconData percent = PhosphorIconsRegular.percent;
  static const IconData pause = PhosphorIconsRegular.pause;
  static const IconData printer = PhosphorIconsRegular.printer;
  static const IconData landmark = PhosphorIconsRegular.bank;
  static const IconData crown = PhosphorIconsRegular.crown;
}

/// أيقونات ممتلئة — للتبويب المختار في الشريط السفلي
class AppIconsFill {
  AppIconsFill._();

  static const IconData home = PhosphorIconsFill.house;
  static const IconData shoppingBag = PhosphorIconsFill.handbag;
  static const IconData archive = PhosphorIconsFill.package;
  static const IconData user = PhosphorIconsFill.user;
}

/// أيقونات بلونين (Duotone) — للبطاقات والأيقونات الكبيرة، تُعرض بـ PhosphorIcon
class AppIconsDuo {
  AppIconsDuo._();

  static const IconData shoppingBag = PhosphorIconsDuotone.handbag;
  static const IconData send = PhosphorIconsDuotone.paperPlaneTilt;
  static const IconData search = PhosphorIconsDuotone.magnifyingGlass;
  static const IconData tag = PhosphorIconsDuotone.tag;
  static const IconData crown = PhosphorIconsDuotone.crown;
  static const IconData sparkle = PhosphorIconsDuotone.sparkle;
  static const IconData receipt = PhosphorIconsDuotone.receipt;
  static const IconData truck = PhosphorIconsDuotone.truck;
}
