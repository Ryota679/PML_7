import 'package:kantin_app/data/models/log.dart';
import 'package:kantin_app/data/models/status.dart';
import 'package:kantin_app/data/repository/base_appwrite_repository.dart';
import 'package:kantin_app/ui/components/checkered_background.dart';
import 'package:kantin_app/ui/components/collapsible_bottomsheet.dart';
import 'package:kantin_app/ui/components/connection_status_view.dart';
import 'package:kantin_app/ui/components/getting_started_cards.dart';
import 'package:kantin_app/ui/components/top_platform_view.dart';
import 'package:kantin_app/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

class AppwriteStarterKit extends StatefulWidget {
  const AppwriteStarterKit({super.key});

  @override
  State<AppwriteStarterKit> createState() => _AppwriteStarterKit();
}

class _AppwriteStarterKit extends State<AppwriteStarterKit> {
  final List<Log> _logs = [];
  Status _status = Status.idle;
  final BaseAppwriteRepository _repository = BaseAppwriteRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CheckeredBackground(
        child: SafeArea(
          minimum: EdgeInsets.only(
              top: context.isExtraWideScreen
                  ? 156
                  : context.isLargeScreen
                      ? 24
                      : 32),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  spacing: 16,
                  children: [
                    TopPlatformView(status: _status),
                    ConnectionStatusView(
                      status: _status,
                      onButtonClick: () async {
                        setState(() => _status = Status.loading);
                        final log = await _repository.ping();
                        _logs.add(log);

                        await Future.delayed(
                          const Duration(milliseconds: 1250),
                        );

                        setState(
                          () => _status =
                              (200 <= log.status && log.status <= 399)
                                  ? Status.success
                                  : Status.error,
                        );
                      },
                    ),
                    GettingStartedCards()
                  ],
                ),
              ),

              // bottomsheet
              Align(
                alignment: Alignment.bottomCenter,
                child: CollapsibleBottomSheet(
                  logs: _logs,
                  projectInfo: _repository.getProjectInfo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
