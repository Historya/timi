import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// 将分类图标字符串转为 Phosphor 图标
IconData resolveCategoryIcon(String iconName) {
  switch (iconName) {
    case 'food': return PhosphorIconsLight.forkKnife;
    case 'car': return PhosphorIconsLight.car;
    case 'shopping': return PhosphorIconsLight.shoppingBag;
    case 'film': return PhosphorIconsLight.filmStrip;
    case 'house': return PhosphorIconsLight.house;
    case 'heartbeat': return PhosphorIconsLight.heartbeat;
    case 'book': return PhosphorIconsLight.bookOpen;
    case 'game': return PhosphorIconsLight.gameController;
    case 'bus': return PhosphorIconsLight.bus;
    case 'money': return PhosphorIconsLight.money;
    case 'gift': return PhosphorIconsLight.gift;
    case 'coffee': return PhosphorIconsLight.coffee;
    case 'bag': return PhosphorIconsLight.bag;
    case 'phone': return PhosphorIconsLight.phone;
    case 'airplane': return PhosphorIconsLight.airplane;
    case 'firstAid': return PhosphorIconsLight.firstAid;
    case 'pawPrint': return PhosphorIconsLight.pawPrint;
    case 'wrench': return PhosphorIconsLight.wrench;
    case 'dotsThree': return PhosphorIconsLight.dotsThree;
    default: return PhosphorIconsLight.placeholder;
  }
}

/// 将 hex 颜色字符串转为 Color
Color parseHexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  final full = h.length == 6 ? 'FF$h' : h;
  return Color(int.parse(full, radix: 16));
}

/// 图标名称列表（用于分类选择器）
const List<String> categoryIconNames = [
  'food', 'car', 'shopping', 'film', 'house', 'heartbeat', 'book', 'game',
  'bus', 'money', 'gift', 'coffee', 'bag', 'phone', 'airplane', 'firstAid',
  'pawPrint', 'wrench', 'dotsThree',
];

/// 颜色十六进制列表（用于分类选择器）
const List<String> categoryColorHexes = [
  '#FF6B6B', '#FFA94D', '#FFD43B', '#69DB7C', '#38D9A9', '#4DABF7',
  '#748FFC', '#9775FA', '#F783AC', '#FF8787', '#FFC078', '#FFE066',
  '#8CE99A', '#66D9E8', '#74C0FC', '#91A7FF', '#B197FC', '#DDA0DD',
];
