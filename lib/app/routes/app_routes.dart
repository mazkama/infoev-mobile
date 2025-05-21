
part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH = Path.SPLASH;
  static const LOGIN = Path.LOGIN;
  static const REGISTER = Path.REGISTER;
  static const ONBOARDING = Path.ONBOARDING;
  static const NAVBAR = Path.NAVBAR;

  static const HOME = Path.HOME;
  static const JELAJAH = Path.JELAJAH;
  static const BRAND = Path.BRAND;
  static const VEHICLE = Path.VEHICLE;
  static const NEWS = Path.NEWS; 
  static const CHARGER_STATION = Path.CHARGER_STATION;
  static const EV_COMPARISON = Path.EV_COMPARISON;
  static const CALCULATOR = Path.CALCULATOR;
}

abstract class Path {
  static const SPLASH = '/splash';
  static const ONBOARDING = '/onboarding';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const NAVBAR = '/navbar';

  static const HOME = '/beranda';
  static const JELAJAH = '/jelajah'; 
  static const BRAND = '/brand/:brandId';
  static const VEHICLE = '/kendaraan/:slug';
  static const NEWS = '/news'; 
  static const CHARGER_STATION = '/charger_station';
  static const EV_COMPARISON = '/ev_comparison';
  static const PROFIL = '/profil';
  static const CALCULATOR = '/calculator';
}
