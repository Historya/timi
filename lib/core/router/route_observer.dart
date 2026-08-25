import 'package:flutter/material.dart';

/// 全局路由 Observer，用于监听页面 push/pop 生命周期
/// 供 ScaffoldWithNavBar 感知二级页面返回，从而重置底部导航显示状态
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();