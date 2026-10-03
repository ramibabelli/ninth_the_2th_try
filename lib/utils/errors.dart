import 'package:supabase_flutter/supabase_flutter.dart';

String translateSupabaseError(Object error) {
  final message = error.toString().toLowerCase();

  if (error is PostgrestException) {
    if (error.code == '42501' ||
        message.contains('row-level security') ||
        message.contains('permission denied') ||
        message.contains('policy')) {
      return 'الصلاحية الحالية لا تسمح بهذه العملية، تحقق من قواعد الحماية (RLS) والإعدادات';
    }
    if (error.code == '23505') {
      return 'السجل موجود مسبقًا، تحقق من البيانات المدخلة';
    }
    if (error.code == '23503') {
      return 'السجل مرتبط ببيانات غير متوفرة (تحقق من الحساب المتصل)';
    }
  }

  if (error is StorageException) {
    if (message.contains('not found') || error.statusCode == '404') {
      return 'خزانة التخزين (Bucket) غير موجودة أو غير جاهزة بعد، تحقق من الإعدادات';
    }
    if (error.statusCode == '403' || message.contains('permission')) {
      return 'لا يوجد إذن لرفع الصورة، تحقق من قواعد التخزين (Storage)';
    }
  }

  if (message.contains('invalid login credentials') ||
      message.contains('invalid_credentials')) {
    return 'بيانات الدخول غير صحيحة، تحقق من البريد وكلمة المرور';
  }
  if (message.contains('user_already_exists') ||
      message.contains('already registered') ||
      message.contains('duplicate')) {
    return 'هذا البريد الإلكتروني مسجّل مسبقًا';
  }
  if (message.contains('password should be') ||
      message.contains('weak password')) {
    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
  }
  if (message.contains('contains capital letter') ||
      message.contains('contains @') ||
      message.contains('invalid email') ||
      message.contains('invalid format email')) {
    return 'صيغة البريد الإلكتروني غير صحيحة';
  }
  if (message.contains('rate limit') || message.contains('too many')) {
    return 'تم إرسال طلبات كثيرة، حاول بعد قليل';
  }
  if (message.contains('network') || message.contains('connection')) {
    return 'تعذّر الاتصال بالخادم، تحقق من الإنترنت';
  }
  if (message.contains('could not connect') ||
      message.contains('connection refused') ||
      message.contains('failed host lookup') ||
      message.contains('tls')) {
    return 'تعذّر الاتصال بالخادم، تحقق من إعدادات Supabase';
  }
  return 'حدث خطأ غير متوقع، حاول مرة أخرى';
}