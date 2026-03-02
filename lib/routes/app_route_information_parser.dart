import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Navigator 2.0 路由信息解析器，将 URL/RouteInformation 解析为应用路由状态
class AppRouteInformationParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    // 解析 path 可在后续用于深链接；当前主流程由 NavigationProvider 驱动
    return SynchronousFuture<Object>(Object());
  }

  @override
  RouteInformation? restoreRouteInformation(Object configuration) {
    // 可选：根据当前状态恢复 RouteInformation，便于 Web 或系统后退
    return null;
  }
}
