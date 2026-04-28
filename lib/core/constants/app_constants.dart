// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'GKJW Karangpilang';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.gkjw.gkjw_karangpilang';

  // Supabase
  static const String supabaseUrl = 'https://roocpiqogsnqqnfdokiv.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvb2NwaXFvZ3NucXFuZmRva2l2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxODQwMjQsImV4cCI6MjA5Mjc2MDAyNH0.sq2UJu6Buatqu72mXNt2SUcj6BxVkXlmh54aPq3FkO0';

  // Persembahan
  static const String qrisImageUrl =
      'https://roocpiqogsnqqnfdokiv.supabase.co/storage/v1/object/public/assets/qris_gkjw.png';
  static const String rekeningBRI = '1234-01-012345-67-8';
  static const String namaPemilikRekening = 'GKJW Karangpilang';

  // Firebase Storage paths
  static const String wartaPath = 'warta_jemaat/';
  static const String tataIbadahPath = 'tata_ibadah/';
  static const String renunganPath = 'renungan/';
  static const String siranPath = 'siaran/';
  static const String galeriPath = 'galeri/';
  static const String eperpusPath = 'eperpus/';

  // Firestore collections
  static const String colWarta = 'warta_jemaat';
  static const String colTataIbadah = 'tata_ibadah';
  static const String colRenungan = 'renungan';
  static const String colSiaran = 'siaran';
  static const String colUsers = 'users';
}
