import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api.dart';

enum UserRole { buyer, merchant }

/// نوع الحساب يُقرأ من الملف الشخصي في القاعدة (الرقم المسجّل بدور لا يدخل بالدور الآخر)
final roleProvider = Provider<UserRole>((ref) {
  final p = ref.watch(myProfileProvider).valueOrNull;
  return p?.isMerchant == true ? UserRole.merchant : UserRole.buyer;
});

/// بيانات التسجيل المؤقتة بين شاشة التسجيل ورمز التحقق
class SignupDraft {
  final String phone;
  final String? name, city, role;
  final bool login;
  const SignupDraft({required this.phone, this.name, this.city, this.role, this.login = false});
}

final signupDraftProvider = StateProvider<SignupDraft?>((ref) => null);

/// الطلبات الجاهزة للدفع (من السلة أو قبول عرض/سومة)
final checkoutOrdersProvider = StateProvider<List<String>>((ref) => const []);

const shippingFee = 35.0;
const vatRate = 0.15;
